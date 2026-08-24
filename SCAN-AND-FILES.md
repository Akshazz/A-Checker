# Scan & Read-Only Files Update

## Device scanning
- The Scan Devices button now launches a **one-shot** read-only scan with `agent.js --once`.
- The web endpoint dynamically updates the agent's report URL to the current A-TestChecker installation, avoiding stale hard-coded localhost paths after the project is moved.
- If SMART tools cannot enumerate a drive, the agent falls back to the operating system's physical storage inventory and still reports the drive as an `UNKNOWN` health device instead of showing an empty dashboard.
- The normal background agent remains continuous; the scan button does not change `config.json` to one-shot mode.

## Read-only file viewing
- Every detected storage device and mounted volume has a **View Files** button when a readable mount point or drive letter is available.
- File Browser remains read-only: listing, metadata and text preview only.
- No create, edit, rename, delete, upload, move, execute, format, resize or partition-modification operation is exposed.
