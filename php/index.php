<?php
require_once __DIR__ . '/db.php';
$pdo = get_db();

$devices = $pdo->query(
    "SELECT d.*, s.id AS scan_id, s.health_status, s.temperature_c, s.power_on_hours,
            s.reallocated_sector_count, s.pending_sector_count, s.wear_level_percent, s.scan_date
     FROM devices d
     LEFT JOIN scans s ON s.id = (
         SELECT id FROM scans WHERE device_id = d.id ORDER BY scan_date DESC LIMIT 1
     )
     ORDER BY d.hostname, d.device_path"
)->fetchAll();

$total = count($devices);
$failed = count(array_filter($devices, fn($d) => strtoupper((string)$d['health_status']) === 'FAILED'));
$warning = count(array_filter($devices, fn($d) => strtoupper((string)$d['health_status']) === 'WARNING'));
$ok = $total - $failed - $warning;
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Storage Health Monitor</title>
<link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header>
    <h1>Storage Health Monitor</h1>
    <p>SMART health across all reporting machines. Reports pushed by the agent script.</p>
</header>
<main>
    <div class="stat-row">
        <div class="stat"><div class="num"><?= $total ?></div><div class="label">Drives</div></div>
        <div class="stat"><div class="num" style="color:var(--ok)"><?= $ok ?></div><div class="label">Healthy</div></div>
        <div class="stat"><div class="num" style="color:var(--warn)"><?= $warning ?></div><div class="label">Warning</div></div>
        <div class="stat"><div class="num" style="color:var(--fail)"><?= $failed ?></div><div class="label">Failed</div></div>
    </div>

    <?php if (!$devices): ?>
        <div class="empty">No reports yet. Run the agent (see /agent/README) to send your first scan.</div>
    <?php else: ?>
    <table>
        <thead>
        <tr>
            <th>Host</th><th>Device</th><th>Model</th><th>Type</th>
            <th>Status</th><th>Temp</th><th>Power-On Hrs</th><th>Reallocated</th><th>Wear</th><th>Last Scan</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($devices as $d): ?>
        <tr>
            <td><?= htmlspecialchars($d['hostname']) ?></td>
            <td><a href="device.php?id=<?= $d['id'] ?>"><?= htmlspecialchars($d['device_path']) ?></a></td>
            <td><?= htmlspecialchars($d['model'] ?? '—') ?></td>
            <td><?= htmlspecialchars($d['drive_type'] ?? '—') ?></td>
            <td><span class="badge <?= health_class($d['health_status'] ?? 'UNKNOWN') ?>"><?= htmlspecialchars($d['health_status'] ?? 'UNKNOWN') ?></span></td>
            <td><?= $d['temperature_c'] !== null ? htmlspecialchars($d['temperature_c']) . '°C' : '—' ?></td>
            <td><?= $d['power_on_hours'] !== null ? htmlspecialchars($d['power_on_hours']) : '—' ?></td>
            <td><?= $d['reallocated_sector_count'] !== null ? htmlspecialchars($d['reallocated_sector_count']) : '—' ?></td>
            <td><?= $d['wear_level_percent'] !== null ? htmlspecialchars($d['wear_level_percent']) . '%' : '—' ?></td>
            <td><?= $d['scan_date'] ? htmlspecialchars($d['scan_date']) : '—' ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php endif; ?>
</main>
</body>
</html>
