# A-TestChecker — Advanced Device & Storage Monitor

A-TestChecker is a self-hosted, read-only hardware monitoring dashboard for a computer running PHP/XAMPP plus a small local Node.js agent.

It is designed to answer three questions:

1. **What devices are connected?**
2. **What is the health/capacity/status of my storage and other hardware?**
3. **Can I safely browse readable files on an approved local storage volume without modifying them?**

> **Safety:** The web interface is intentionally read-only. It does not format, delete, resize, rename, upload, move, or execute files and it does not expose destructive partition operations.

---

## 1. Main Features

### Device Center

The left sidebar organizes detected hardware into categories:

- **Storage** — physical HDD/SSD/NVMe devices, SMART health, temperature, capacity and partitions.
- **Printers** — installed/connected printers, driver/port information and status when the operating system exposes it.
- **RAM** — total, used and available system memory.
- **Smartphones** — Android devices through `adb` and iPhone/iPad devices through `idevice_id` when those tools are installed.
- **USB & Peripherals** — USB, Bluetooth, HID, keyboard/mouse/game-controller and similar devices where the OS exposes them.
- **Network Devices** — network adapters and PCI network hardware.
- **Audio / Display** — audio, display, camera and related media hardware.
- **Other Devices** — additional devices reported by the operating system.

The device inventory is collected by the local agent and refreshed by the dashboard. A device that disappears from the machine will no longer be reported as an active connected device on the next inventory refresh.

### Storage Monitor

Storage is organized by **physical device**, then by its partitions/volumes.

Example:

```text
Samsung SSD / PhysicalDrive0
  ├─ C:  Windows
  ├─ D:  Data
  └─ Recovery

WD HDD / PhysicalDrive1
  └─ E:  Backup
```

The UI avoids displaying the same physical drive or drive letter repeatedly. Drive letters are shown once under the physical device that owns the corresponding partition.

Storage information can include:

- Model
- Physical device path
- Interface / drive type
- Capacity
- Health score/status
- Temperature when available
- SMART information when available
- Partition count
- Drive letter / mount point
- Filesystem
- Volume label
- Used/free space
- Usage percentage
- Partition health

### Read-only File Browser

Use **View Files** from a storage volume or the **Files** area in the sidebar to browse approved local storage roots.

Supported actions:

- Open folders
- Go up to a parent folder within an approved root
- Switch between available storage roots
- View file name, size and modification time
- Preview readable text files up to 1 MB

Not supported by design:

- Edit
- Delete
- Rename
- Upload
- Move/copy
- Execute
- Format
- Resize
- Partition changes

Binary files are metadata-only and are not rendered as text.

### Device Search

The device search field can filter storage by model/path and can also be used with the device inventory view to find hardware by its available identifying fields.

### Read-only Device Scan

**Scan connected devices** does not use a CAPTCHA. It starts a local read-only inventory scan.

The scan can collect:

- Storage
- Printers
- RAM
- Android/iOS devices
- USB/Bluetooth/HID devices
- Network hardware
- Audio/display/media devices
- Other OS-reported hardware

No storage data is changed by the scan.

---

## 2. How the System Works

A-TestChecker has three main layers:

```text
┌──────────────────────────────┐
│ Browser / A-TestChecker UI   │
│ PHP dashboard + JavaScript   │
└──────────────┬───────────────┘
               │ HTTP / JSON
┌──────────────▼───────────────┐
│ PHP backend                  │
│ devices.php / hardware.php  │
│ files.php / scan.php         │
│ report.php                   │
└──────────────┬───────────────┘
               │ MySQL + local agent
┌──────────────▼───────────────┐
│ Node.js local agent          │
│ smartctl / PowerShell / OS   │
│ lsblk / adb / idevice_id     │
└──────────────┬───────────────┘
               │
               ▼
        Local computer hardware
```

### Why an agent is required

A normal browser cannot directly query raw disk SMART information or enumerate all operating-system hardware. The Node.js agent performs those OS-level reads and sends normalized results to the PHP backend.

### Realtime behavior

The dashboard polls the PHP JSON endpoints for fresh telemetry/inventory. The agent can run continuously or be started for a one-time scan.

The normal agent loop is intended to refresh hardware inventory approximately every 5 seconds.

---

## 3. Requirements

### Required

- Windows, Linux or macOS
- PHP 8.x recommended
- MySQL/MariaDB
- Apache or another PHP-capable web server
- Node.js 18+ recommended
- npm
- A browser

### Storage SMART support

Install **smartmontools** on the machine being scanned if you want SMART data.

- **Windows:** install smartmontools and make `smartctl.exe` available to the agent.
- **macOS:** `brew install smartmontools`
- **Debian/Ubuntu:** `sudo apt install smartmontools`
- **Fedora/RHEL:** use the appropriate `dnf` package.

SMART availability depends on the controller, USB enclosure and operating-system permissions. Some USB flash drives and card readers do not expose SMART information.

### Optional device bridges

For smartphones:

- Android: install Android Platform Tools so `adb` is available.
- iOS/iPadOS: install `libimobiledevice` so `idevice_id` is available.

These are optional. The rest of the Device Center can operate without them.

---

## 4. Recommended Windows/XAMPP Setup

### Step 1 — Install XAMPP

Install XAMPP with at least:

- Apache
- MySQL
- PHP

Start **Apache** and **MySQL** from the XAMPP Control Panel.

### Step 2 — Install Node.js

Install Node.js and confirm:

```powershell
node --version
npm --version
```

### Step 3 — Install smartmontools

Confirm:

```powershell
smartctl --version
```

If Windows cannot find it, add the smartmontools installation directory to `PATH`, or set `smartctlPath` in `agent/config.json` to the full executable path.

### Step 4 — Run the setup script

Open PowerShell in the project folder:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

The installer will:

1. Find or ask for the XAMPP `htdocs` folder.
2. Deploy the PHP application.
3. Deploy the local Node.js agent.
4. Generate a random API key.
5. Import the MySQL schema.
6. Write database credentials.
7. Generate `agent/config.json` with the correct API endpoint/key.
8. Run `npm install` for the agent.
9. Check whether `smartctl` is available.

Then open:

```text
http://localhost/storage-health-monitor/
```

### Step 5 — Start the agent

From the deployed project:

```powershell
cd C:\xampp\htdocs\storage-health-monitor\agent
npm install
node agent.js
```

For a one-time scan:

```powershell
node agent.js --once
```

Run the agent from an **Administrator PowerShell** when Windows storage/SMART access requires elevated permissions.

### Optional launcher

`START-A-TestChecker.bat` can start the local agent and XAMPP when the package is being used from the project directory. The dashboard URL in that launcher should match the folder name where the application is deployed.

---

## 5. Linux / macOS Setup

### Step 1 — Install PHP/MySQL/Apache or use an existing PHP server

Create a database named `storage_health`, then import:

```text
database/schema.sql
```

Update the deployed `php/config.php` if you are not using the setup script.

### Step 2 — Run setup

```bash
chmod +x setup.sh
./setup.sh
```

The installer can target common XAMPP/LAMPP `htdocs` locations and will ask for the correct path when it cannot find one.

### Step 3 — Install the agent dependencies

```bash
cd agent
npm install
```

### Step 4 — Start the agent

```bash
sudo node agent.js
```

One-time scan:

```bash
sudo node agent.js --once
```

If your PHP server is on another machine, edit `agent/config.json` and set `serverUrl` to the reachable address of that PHP installation.

---

## 6. Database

The main database tables are:

- `devices` — physical storage device records.
- `scans` — SMART/health scan history.
- `partitions` — partition and volume inventory/history.
- `api_keys` — authentication keys used by the agent.
- `hardware_devices` — printers, RAM, phones and generic hardware inventory.

The agent sends data to the PHP API, and the dashboard reads it through JSON endpoints.

### Fresh database import

Use:

```text
database/schema.sql
```

If you are upgrading an older installation, review:

```text
database/migration.sql
```

Do not repeatedly import the schema into an installation that already contains production data unless you understand the SQL being executed.

---

## 7. Agent Configuration

The installer generates:

```text
agent/config.json
```

Typical structure:

```json
{
  "serverUrl": "http://localhost/storage-health-monitor/api/report.php",
  "apiKey": "YOUR_GENERATED_API_KEY",
  "smartctlPath": "smartctl",
  "devices": ["auto"]
}
```

### `serverUrl`

The PHP endpoint that receives agent telemetry.

If the dashboard is on another machine, use its LAN address, for example:

```text
http://192.168.1.50/storage-health-monitor/api/report.php
```

### `apiKey`

Must match the key stored in the MySQL `api_keys` table.

Do not publish the real API key in screenshots, Git repositories or public downloads.

### `smartctlPath`

Usually:

```text
smartctl
```

or a full path to the executable.

---

## 8. Storage Mapping and Drive Letters

The agent collects partitions from the operating system rather than guessing which volume belongs to which disk.

### Windows

The agent uses PowerShell `Get-Partition` and `Get-Volume`. Each partition includes its `DiskNumber`, and the dashboard associates it with:

```text
\\.\PhysicalDrive0
\\.\PhysicalDrive1
...
```

Drive letters such as `C:`, `D:` and `E:` therefore remain attached to the physical storage device that owns the partition.

### Linux

The agent uses `lsblk` and its parent/child block-device relationship.

### macOS

The current agent exposes a physical disk inventory through `diskutil`; detailed partition mapping can depend on the macOS output available on the machine.

---

## 9. File Browser Configuration

The file browser is deliberately restricted to local readable roots.

### Default Windows roots

The API discovers mounted drive roots such as:

```text
C:\
D:\
E:\
```

### Default Linux/macOS roots

It checks common locations such as:

```text
/home
/media
/mnt
/run/media
/Volumes
```

### Restrict access further

Set the environment variable:

```text
ATESTCHECKER_FILE_ROOTS
```

Windows example:

```text
C:\Users;D:\Shared
```

Linux example:

```text
/home/user;/mnt/shared
```

This is recommended if the dashboard should only expose selected folders.

### File preview limit

Text preview is limited to **1 MB**. Binary files cannot be displayed as text.

---

## 10. Using the Dashboard

### Storage

1. Open **Storage** in the sidebar.
2. Choose a physical drive.
3. Review health, capacity and partitions.
4. Select a drive letter/volume when available.
5. Press **View Files** to browse the volume read-only.

### Printers / RAM / Smartphones / Other Devices

1. Select the category in the sidebar.
2. Review the current inventory.
3. If the inventory is stale, use **Scan connected devices**.

### Search

Use the device search box to filter devices by the information exposed by the agent.

### Scan connected devices

1. Click **Scan connected devices**.
2. Review the read-only confirmation.
3. Click **Start Scan**.
4. Wait for the local agent to report the refreshed inventory.

There is **no CAPTCHA** for scanning.

---

## 11. Read-only Safety Model

The web application does not expose operations that modify user storage.

### Allowed

- Detect hardware
- Read SMART data
- Read partition metadata
- Read volume capacity/free-space information
- List folders
- Read file metadata
- Preview small readable text files

### Not allowed

- Format
- Delete files
- Delete partitions
- Resize partitions
- Create partitions
- Merge/split partitions
- Change drive letters
- Rename files
- Upload files
- Move/copy files through the web UI
- Execute files through the web UI

If you need to modify storage, use a dedicated local administration tool after taking appropriate backups.

---

## 12. Troubleshooting

### Dashboard loads but says Agent Offline

Check:

```powershell
node --version
```

Then start:

```powershell
cd agent
node agent.js
```

Also check that `agent/config.json` contains the correct `serverUrl` and API key.

### Scan button says Node.js is unavailable

The PHP web server process cannot find Node.js. Start the agent manually instead:

```powershell
cd agent
node agent.js --once
```

Or make Node.js available to the Apache/PHP service account's PATH.

### SMART data is empty

Run:

```powershell
smartctl --scan-open
```

Then test an exposed device with the appropriate `smartctl` command. Some controllers/enclosures do not pass SMART data through.

### Storage is detected but health is UNKNOWN

This normally means the OS can see the physical disk but SMART health data is unavailable or incomplete. Capacity/partition information can still be useful.

### Android is not detected

Confirm:

```powershell
adb devices
```

Enable USB debugging on the Android device and authorize the computer when prompted.

### iPhone/iPad is not detected

Confirm:

```bash
idevice_id -l
```

Install/configure libimobiledevice and trust the computer on the Apple device when required.

### View Files does not open a drive

Confirm that the drive is mounted and readable by the PHP/Apache account. If using a restricted allowlist, make sure the drive root is included in `ATESTCHECKER_FILE_ROOTS`.

### Browser shows an old design or old behavior

Use a hard refresh:

```text
Ctrl + F5
```

The dashboard uses JavaScript and CSS assets that can otherwise remain cached.

---

## 13. Project Structure

```text
A-TestChecker/
├── README.md
├── READY-TO-USE.md
├── setup.sh
├── setup.ps1
├── START-A-TestChecker.bat
├── database/
│   ├── schema.sql
│   └── migration.sql
├── php/
│   ├── index.php
│   ├── device.php
│   ├── config.php
│   ├── db.php
│   ├── assets/
│   │   └── style.css
│   └── api/
│       ├── devices.php
│       ├── hardware.php
│       ├── report.php
│       ├── scan.php
│       └── files.php
└── agent/
    ├── agent.js
    ├── package.json
    ├── package-lock.json
    ├── config.json
    └── config.example.json
```

### Important files

**`agent/agent.js`**

Collects local hardware and storage information.

**`php/api/report.php`**

Receives authenticated agent telemetry.

**`php/api/devices.php`**

Provides storage/device information to the dashboard.

**`php/api/hardware.php`**

Provides the connected-device inventory.

**`php/api/files.php`**

Provides the read-only folder/file browser.

**`php/api/scan.php`**

Starts a local one-time agent scan.

**`database/schema.sql`**

Creates the database structure.

---

## 14. Security Notes

For local/LAN use, keep the application behind a trusted network boundary.

Recommended:

- Use a strong generated API key.
- Restrict `ATESTCHECKER_FILE_ROOTS` instead of exposing every mounted drive when possible.
- Do not expose the PHP dashboard directly to the public Internet without authentication and HTTPS.
- Run the agent with only the privileges required to read the hardware information you need.
- Keep Node.js, PHP, MySQL and smartmontools updated.
- Do not place secrets such as `agent/config.json` or production database credentials in a public repository.

---

## 15. Quick Start

### Windows / XAMPP

```powershell
# 1. Start XAMPP Apache + MySQL
# 2. Open PowerShell in this project
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1

# 3. Start the agent
cd agent
npm install
node agent.js

# 4. Open the dashboard
# http://localhost/storage-health-monitor/
```

### Linux/macOS

```bash
chmod +x setup.sh
./setup.sh
cd agent
npm install
sudo node agent.js
```

Then open the dashboard URL printed by the setup script.

---

## 16. Current Functional Scope

This edition is a **read-only monitoring and inspection system**, not a disk-management utility.

Its main strengths are:

- Unified hardware inventory
- Physical-drive/partition relationship
- Drive-letter-aware storage display
- SMART/health monitoring
- Realtime inventory refresh
- Read-only file browsing
- Search and category filtering
- Android/iOS bridge detection when optional tools are installed
- Cross-platform collection paths for Windows/Linux/macOS

It intentionally does not modify devices or files.
