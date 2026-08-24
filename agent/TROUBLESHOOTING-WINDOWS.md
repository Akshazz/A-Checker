# Windows scan troubleshooting

## 1. Test the PHP endpoint

Open:

`http://localhost/A-Checker/`

The agent posts to:

`http://localhost/A-Checker/php/api/report.php`

A browser GET to the report endpoint is expected to return `POST only`; that confirms the route exists.

## 2. Test the API key

The value in `agent/config.json` must exist in MySQL table `api_keys`.

For the development database shipped with this project:

`__API_KEY__`

For a real installation, generate a fresh key with the setup script and do not expose it publicly.

## 3. Test smartctl

From Git Bash:

```bash
smartctl --version
smartctl --scan-open
```

If `smartctl` is not found, install smartmontools and add its `bin` directory to PATH.

## 4. Run as Administrator

SMART access on Windows can require elevated privileges:

```bash
npm run scan
```

Start Git Bash as Administrator before running the scan.

## 5. What the agent does when SMART is unavailable

The agent still reports the Windows partition inventory when `reportInventoryOnly` is true. Therefore, even systems where an SSD/USB bridge does not expose SMART can still appear in the Partition & Volume Manager.
