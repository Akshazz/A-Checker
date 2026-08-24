# Storage display + read-only file browser fix

## Storage grouping
- Each physical storage device receives only its own partitions.
- Windows partitions are associated with `PhysicalDriveN` using `disk_number`.
- Linux partitions are associated with their parent block device.
- Drive-letter volumes are deduplicated in the UI so C:, D:, E:, etc. display once.
- Legacy database records are filtered at the API/UI layer so old cross-device partition snapshots do not reappear.

## Read-only file browser
- Added the missing File Browser panel that the JavaScript expected.
- `View Files` can open a selected drive letter or mount point.
- Folders are browsable; readable text files can be previewed.
- No edit, rename, delete, upload, move, execute, format, or resize operation is exposed.

After replacing the project, hard refresh the browser with Ctrl+F5.
