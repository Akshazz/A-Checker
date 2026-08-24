# A-TestChecker Realtime Storage Reader

The dashboard now polls the API every 3 seconds and the agent continuously scans/report telemetry every 5 seconds by default.

## Dashboard
- Storage device dropdown instead of an always-expanded device list
- Live/offline status indicator
- Selected-device Sentinel-style health telemetry
- This PC-style volume/storage display with capacity, free space and usage bars
- Connected-device compact selector cards
- Automatic refresh when devices appear/disappear

## Agent
`agent/config.json` now contains `scanIntervalMs: 5000` and `once: false`.
Set `once: true` if you only want one scan.

SMART remains controller dependent. When SMART is unavailable, partition/volume inventory is still reported.
