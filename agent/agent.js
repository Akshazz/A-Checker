#!/usr/bin/env node
/**
 * Storage Health Monitor - Advanced Windows/Linux/macOS agent.
 * Collects SMART data plus OS disk/partition inventory and posts it to PHP.
 * Safe by default: partition operations are READ-ONLY; no formatting,
 * deletion, resizing or destructive surface tests are triggered remotely.
 */
const { execFile } = require('child_process');
const os = require('os');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

const CONFIG_PATH = path.join(__dirname, 'config.json');

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) throw new Error('Missing config.json');
  return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
}
function run(cmd, args, options={}) {
  return new Promise(resolve => {
    execFile(cmd, args, {maxBuffer: 20*1024*1024, windowsHide:true, ...options},
      (err, stdout, stderr) => resolve({stdout: stdout || '', stderr: stderr || '', code: err?.code ?? 0}));
  });
}
async function runPowerShell(script) {
  const r = await run('powershell.exe', ['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-Command',script]);
  try { return JSON.parse(r.stdout); } catch { return []; }
}
async function collectPartitions() {
  if (process.platform === 'win32') {
    const ps = `$ErrorActionPreference='SilentlyContinue'; Get-Partition | ForEach-Object {
      $p=$_; $v=Get-Volume -Partition $p -ErrorAction SilentlyContinue;
      [pscustomobject]@{
        disk_number=[int]$p.DiskNumber; partition_number=[int]$p.PartitionNumber;
        drive_letter=if($p.DriveLetter){[string]$p.DriveLetter}else{$null};
        size_bytes=[int64]$p.Size; offset_bytes=[int64]$p.Offset;
        type=[string]$p.Type; gpt_type=[string]$p.GptType;
        filesystem=if($v){[string]$v.FileSystem}else{$null};
        label=if($v){[string]$v.FileSystemLabel}else{$null};
        total_bytes=if($v){[int64]$v.Size}else{$null};
        free_bytes=if($v){[int64]$v.SizeRemaining}else{$null};
        health=if($v){[string]$v.HealthStatus}else{$null};
      }
    } | ConvertTo-Json -Compress -Depth 5`;
    const data=await runPowerShell(ps);
    return Array.isArray(data)?data:(data&&typeof data==='object'?[data]:[]);
  }
  if (process.platform === 'linux') {
    const r=await run('lsblk',['-J','-b','-o','NAME,PATH,SIZE,FSTYPE,LABEL,MOUNTPOINT,FSAVAIL,FSUSE%']);
    try {
      const flat=[];
      const walk=(xs)=>{for(const x of xs||[]){if(x.type==='part'||x.mountpoint||x.fstype) flat.push({
        device_path:x.path||('/dev/'+x.name), size_bytes:Number(x.size)||null, filesystem:x.fstype||null,
        label:x.label||null, mount_point:x.mountpoint||null, free_bytes:x.fsavail?Number(x.fsavail):null,
        usage_percent:x['fsuse%']?parseFloat(x['fsuse%']):null}); walk(x.children);}};
      walk(JSON.parse(r.stdout).blockdevices); return flat;
    } catch { return []; }
  }
  if (process.platform === 'darwin') {
    const r=await run('diskutil',['list','-plist','physical']);
    return [{device_path:'macOS diskutil inventory', raw:r.stdout}];
  }
  return [];
}
async function discoverDevices(smartctlPath) {
  // Windows smartctl can require an open probe to enumerate USB/SATA/NVMe
  // devices. Try scan-open first, then regular scan as a fallback.
  const candidates = [
    ['--scan-open', '--json'],
    ['--scan', '--json']
  ];
  for (const args of candidates) {
    const r = await run(smartctlPath, args);
    const text = r.stdout || '';
    try {
      const parsed = JSON.parse(text);
      const devices = Array.isArray(parsed.devices) ? parsed.devices : [];
      if (devices.length) {
        return devices.map(d => ({name:d.name, type:d.type}));
      }
    } catch {}
  }
  return [];
}
function getAttr(table,id){const row=(table||[]).find(a=>a.id===id); return row?row.raw?.value:null;}
function healthScore({health,reallocated,pending,uncorrectable,temp,wear}) {
  if(health==='FAILED') return 0;
  let s=100;
  if((reallocated??0)>0) s-=Math.min(35,10+(reallocated??0));
  if((pending??0)>0) s-=Math.min(35,15+(pending??0));
  if((uncorrectable??0)>0) s-=40;
  if(typeof temp==='number' && temp>=60) s-=Math.min(25,5+Math.floor(temp-60));
  if(typeof wear==='number') s=Math.min(s, Math.max(0,wear));
  return Math.max(0,Math.min(100,Math.round(s)));
}
async function scanDevice(smartctlPath, devicePath, devType) {
  const args=['-a','--json=c',devicePath]; if(devType) args.push('-d',devType);
  const out=(await run(smartctlPath,args)).stdout; let data;
  try { data=JSON.parse(out); } catch { console.error(`Could not parse ${devicePath}`); return null; }
  const isNvme=!!data.nvme_smart_health_information_log;
  let health='UNKNOWN', reallocated=null,pending=null,uncorrectable=null,wear=null;
  if(data.smart_status && typeof data.smart_status.passed==='boolean') health=data.smart_status.passed?'PASSED':'FAILED';
  if(isNvme){
    const n=data.nvme_smart_health_information_log;
    wear=n.percentage_used!==undefined?Math.max(0,100-n.percentage_used):null;
    if(n.critical_warning) health='WARNING';
  } else if(data.ata_smart_attributes){
    const t=data.ata_smart_attributes.table;
    reallocated=getAttr(t,5); pending=getAttr(t,197); uncorrectable=getAttr(t,198);
    const w=getAttr(t,177) ?? getAttr(t,173); if(w!==null) wear=Math.max(0,Math.min(100,100-Number(w)));
    if(health==='PASSED' && ((reallocated??0)>0||(pending??0)>0||(uncorrectable??0)>0)) health='WARNING';
  }
  const temp=data.temperature?.current ?? data.nvme_smart_health_information_log?.temperature ?? null;
  const score=healthScore({health,reallocated,pending,uncorrectable,temp,wear});
  const selfTest=data.ata_smart_data?.self_test?.status?.string || data.nvme_self_test_log?.current_selftest_operation?.string || null;
  return {
    hostname:os.hostname(), device_path:devicePath, model:data.model_name||data.model_family||null,
    serial_number:data.serial_number||null, interface_type:data.device?.protocol||null,
    drive_type:isNvme?'SSD':(data.rotation_rate===0?'SSD':(data.rotation_rate?'HDD':null)),
    health_status: score<50?'FAILED':(score<80?'WARNING':health),
    health_score:score, temperature_c:temp,
    power_on_hours:data.power_on_time?.hours||null,
    reallocated_sector_count:reallocated,pending_sector_count:pending,
    uncorrectable_sector_count:uncorrectable,wear_level_percent:wear,
    self_test_status:selfTest, smart_enabled:data.smart_support?.enabled ?? null, raw:data
  };
}
async function report(config,payload){
  const res=await fetch(config.serverUrl,{method:'POST',
    headers:{'Content-Type':'application/json','X-API-Key':config.apiKey},
    body:JSON.stringify(payload)});
  const raw=await res.text();
  let body={};
  try { body=JSON.parse(raw); } catch { body={raw:raw.slice(0,500)}; }
  if(!res.ok) {
    throw new Error(`Server ${res.status} at ${config.serverUrl}: ${JSON.stringify(body)}`);
  }
  console.log(`Reported ${payload.device_path} -> scan ${body.scan_id ?? 'ok'}`);
}
async function scanOnce(config, smartctlPath){
  const partitions=await collectPartitions();
  let targets=config.devices&&config.devices[0]!=='auto'
    ? config.devices.map(d=>({name:d,type:null})) : await discoverDevices(smartctlPath);
  if(!targets.length) console.warn('No SMART devices discovered; reporting live partition inventory.');
  const sentHosts=new Set();
  for(const t of targets){
    const p=await scanDevice(smartctlPath,t.name,t.type); if(!p) continue;
    p.partitions=partitions; sentHosts.add(p.hostname);
    try { await report(config,p); } catch(e) { console.error(e.message); }
  }
  if(!sentHosts.size && config.reportInventoryOnly){
    try { await report(config,{hostname:os.hostname(),device_path:'__INVENTORY__',model:'OS partition inventory',drive_type:'SYSTEM',health_status:'UNKNOWN',partitions}); }
    catch(e){ console.error(e.message); }
  }
  console.log(`[realtime] ${new Date().toISOString()} · SMART devices: ${targets.length} · partitions: ${partitions.length}`);
}
async function main(){
  const config=loadConfig(), smartctlPath=config.smartctlPath||'smartctl';
  const interval=Math.max(1000,Number(config.scanIntervalMs||5000));
  do {
    try { await scanOnce(config,smartctlPath); } catch(e) { console.error('Realtime scan failed:',e.message); }
    if(config.once) break;
    await new Promise(r=>setTimeout(r,interval));
  } while(true);
}
main().catch(e=>{console.error('Agent failed:',e);process.exit(1);});
