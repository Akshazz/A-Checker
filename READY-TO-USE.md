# A-TestChecker — Ready-to-Use Guide

## Quick start on Windows

1. Install/start XAMPP with **Apache** and **MySQL**.
2. Install Node.js.
3. Run `setup.ps1` from PowerShell.
4. Start the agent with:

```powershell
cd C:\xampp\htdocs\storage-health-monitor\agent
node agent.js
```

5. Open:

```text
http://localhost/storage-health-monitor/
```

The setup script now deploys both the PHP application and the Node.js agent into the same project directory. This is required for the dashboard's **Scan connected devices** button to start a local one-time scan.

## One-time scan

```powershell
cd C:\xampp\htdocs\storage-health-monitor\agent
node agent.js --once
```

Run PowerShell as Administrator when Windows hardware/SMART access requires elevation.

## Optional tools

- `smartctl` / smartmontools — SMART data
- `adb` — Android detection
- `idevice_id` — iOS/iPadOS detection

## Read-only file viewer

The **View Files** feature only lists folders/files and previews small readable text files. It cannot edit, delete, rename, upload, move or execute files.

Use `ATESTCHECKER_FILE_ROOTS` to restrict the browser to selected roots.

## If the dashboard says Agent Offline

Run:

```powershell
node --version
node agent.js --once
```

Then check `agent/config.json` for the generated API key and `serverUrl`.
