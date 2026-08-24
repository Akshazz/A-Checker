# View Files Fix

Fixed the read-only storage file browser.

## What was fixed
- Storage volume **View Files** buttons now pass the actual mount point or drive letter to the file browser.
- Windows drive letters such as `C`, `C:`, `C:\`, and `C:/` are normalized correctly.
- Added a dedicated read-only `api/files.php?action=drive&drive=C` resolver for Windows volumes.
- The file browser now reports a useful error when a drive is not mounted/readable instead of silently failing.
- The file browser remains read-only: no edit, rename, delete, upload, move, execute, format, or partition modification operations.
- Existing text preview remains limited to readable text files up to 1 MB.

## Usage
1. Start Apache/PHP and the A-TestChecker agent.
2. Open Storage.
3. Select a physical device.
4. Click **View Files** on a volume such as `C:` or `D:`.
5. Browse folders and use **VIEW** for readable text files.
