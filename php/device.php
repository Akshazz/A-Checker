<?php
require_once __DIR__ . '/db.php';
$pdo = get_db();

$id = (int)($_GET['id'] ?? 0);
$stmt = $pdo->prepare('SELECT * FROM devices WHERE id = ?');
$stmt->execute([$id]);
$device = $stmt->fetch();

if (!$device) {
    http_response_code(404);
    echo 'Device not found. <a href="index.php">Back</a>';
    exit;
}

$stmt = $pdo->prepare('SELECT * FROM scans WHERE device_id = ? ORDER BY scan_date DESC LIMIT 50');
$stmt->execute([$id]);
$scans = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title><?= htmlspecialchars($device['device_path']) ?> — Storage Health Monitor</title>
<link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header>
    <h1><?= htmlspecialchars($device['hostname']) ?> — <?= htmlspecialchars($device['device_path']) ?></h1>
    <p><?= htmlspecialchars($device['model'] ?? 'Unknown model') ?> · <?= htmlspecialchars($device['serial_number'] ?? 'no serial') ?> · <a href="index.php">&larr; back to all drives</a></p>
</header>
<main>
    <?php if (!$scans): ?>
        <div class="empty">No scans recorded for this device yet.</div>
    <?php else: ?>
    <table>
        <thead>
        <tr>
            <th>Date</th><th>Status</th><th>Temp</th><th>Power-On Hrs</th>
            <th>Reallocated</th><th>Pending</th><th>Uncorrectable</th><th>Wear</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($scans as $s): ?>
        <tr>
            <td><?= htmlspecialchars($s['scan_date']) ?></td>
            <td><span class="badge <?= health_class($s['health_status']) ?>"><?= htmlspecialchars($s['health_status']) ?></span></td>
            <td><?= $s['temperature_c'] !== null ? htmlspecialchars($s['temperature_c']) . '°C' : '—' ?></td>
            <td><?= $s['power_on_hours'] ?? '—' ?></td>
            <td><?= $s['reallocated_sector_count'] ?? '—' ?></td>
            <td><?= $s['pending_sector_count'] ?? '—' ?></td>
            <td><?= $s['uncorrectable_sector_count'] ?? '—' ?></td>
            <td><?= $s['wear_level_percent'] !== null ? htmlspecialchars($s['wear_level_percent']) . '%' : '—' ?></td>
        </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <?php endif; ?>
</main>
</body>
</html>
