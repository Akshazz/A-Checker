#!/usr/bin/env node
/**
 * Storage Health Agent
 * Runs smartctl against local drives and POSTs SMART health data to the
 * Storage Health Monitor PHP backend.
 *
 * Requires smartmontools to be installed separately (this script only
 * shells out to it, it does not read hardware directly):
 *   - Windows: https://www.smartmontools.org/wiki/Download  (add to PATH)
 *   - macOS:   brew install smartmontools
 *   - Linux:   sudo apt install smartmontools  (or yum/dnf equivalent)
 *
 * Usage:
 *   npm install
 *   cp config.example.json config.json   (then edit serverUrl / apiKey)
 *   npm run scan
 *
 * Note: reading SMART data usually requires admin/root privileges
 * (run as Administrator on Windows, or with sudo on macOS/Linux).
 */

const { execFile } = require('child_process');
const os = require('os');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

const CONFIG_PATH = path.join(__dirname, 'config.json');

function loadConfig() {
    if (!fs.existsSync(CONFIG_PATH)) {
        console.error('Missing config.json. Copy config.example.json to config.json and edit it first.');
        process.exit(1);
    }
    return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
}

function run(cmd, args) {
    return new Promise((resolve) => {
        execFile(cmd, args, { maxBuffer: 10 * 1024 * 1024 }, (err, stdout) => {
            // smartctl returns non-zero exit codes even on a successful read
            // (bit flags for warnings), so we don't treat err as fatal here.
            resolve(stdout || '');
        });
    });
}

async function discoverDevices(smartctlPath) {
    const out = await run(smartctlPath, ['--scan', '--json']);
    try {
        const parsed = JSON.parse(out);
        return (parsed.devices || []).map((d) => ({ name: d.name, type: d.type }));
    } catch {
        return [];
    }
}

function getAttr(table, id) {
    if (!table) return null;
    const row = table.find((a) => a.id === id);
    return row ? row.raw.value : null;
}

async function scanDevice(smartctlPath, devicePath, devType) {
    const args = ['-a', '--json=c', devicePath];
    if (devType) args.push('-d', devType);
    const out = await run(smartctlPath, args);

    let data;
    try {
        data = JSON.parse(out);
    } catch {
        console.error(`  Could not parse smartctl output for ${devicePath}`);
        return null;
    }

    const isNvme = !!data.nvme_smart_health_information_log;
    let health = 'UNKNOWN';
    if (data.smart_status && typeof data.smart_status.passed === 'boolean') {
        health = data.smart_status.passed ? 'PASSED' : 'FAILED';
    }

    let reallocated = null, pending = null, uncorrectable = null, wear = null;

    if (isNvme) {
        const nvme = data.nvme_smart_health_information_log;
        wear = nvme.percentage_used !== undefined ? 100 - nvme.percentage_used : null;
        if (nvme.critical_warning && nvme.critical_warning !== 0) health = 'WARNING';
    } else if (data.ata_smart_attributes) {
        const table = data.ata_smart_attributes.table;
        reallocated = getAttr(table, 5);
        pending = getAttr(table, 197);
        uncorrectable = getAttr(table, 198);
        const wearAttr = getAttr(table, 177) ?? getAttr(table, 173); // SSD wear leveling (vendor-dependent)
        if (wearAttr !== null) wear = 100 - wearAttr > 0 ? wearAttr : null;
        if (health === 'PASSED' && ((reallocated ?? 0) > 0 || (pending ?? 0) > 0)) {
            health = 'WARNING';
        }
    }

    return {
        hostname: os.hostname(),
        device_path: devicePath,
        model: data.model_name || data.model_family || null,
        serial_number: data.serial_number || null,
        interface_type: (data.device && data.device.protocol) || null,
        drive_type: isNvme ? 'SSD' : (data.rotation_rate === 0 ? 'SSD' : (data.rotation_rate ? 'HDD' : null)),
        health_status: health,
        temperature_c: (data.temperature && data.temperature.current) || null,
        power_on_hours: (data.power_on_time && data.power_on_time.hours) || null,
        reallocated_sector_count: reallocated,
        pending_sector_count: pending,
        uncorrectable_sector_count: uncorrectable,
        wear_level_percent: wear,
        raw: data,
    };
}

async function report(config, payload) {
    const res = await fetch(config.serverUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-API-Key': config.apiKey },
        body: JSON.stringify(payload),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) {
        console.error(`  Server rejected report: ${res.status} ${JSON.stringify(body)}`);
    } else {
        console.log(`  Reported OK (device_id=${body.device_id}, scan_id=${body.scan_id})`);
    }
}

async function main() {
    const config = loadConfig();
    const smartctlPath = config.smartctlPath || 'smartctl';

    let targets = [];
    if (!config.devices || config.devices[0] === 'auto') {
        console.log('Discovering devices via smartctl --scan ...');
        targets = await discoverDevices(smartctlPath);
        if (!targets.length) {
            console.error('No devices found. Is smartmontools installed and are you running as admin/root?');
            process.exit(1);
        }
    } else {
        targets = config.devices.map((d) => ({ name: d, type: null }));
    }

    console.log(`Found ${targets.length} device(s): ${targets.map((t) => t.name).join(', ')}`);

    for (const t of targets) {
        console.log(`Scanning ${t.name} ...`);
        const payload = await scanDevice(smartctlPath, t.name, t.type);
        if (payload) {
            console.log(`  Health: ${payload.health_status}`);
            await report(config, payload);
        }
    }
}

main().catch((err) => {
    console.error('Agent failed:', err);
    process.exit(1);
});
