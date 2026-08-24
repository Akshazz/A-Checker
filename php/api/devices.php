<?php
require_once __DIR__ . '/../db.php';
header('Content-Type: application/json');

$pdo = get_db();
$rows = $pdo->query(
    "SELECT d.*, s.health_status, s.temperature_c, s.power_on_hours,
            s.reallocated_sector_count, s.wear_level_percent, s.scan_date
     FROM devices d
     LEFT JOIN scans s ON s.id = (
         SELECT id FROM scans WHERE device_id = d.id ORDER BY scan_date DESC LIMIT 1
     )
     ORDER BY d.hostname, d.device_path"
)->fetchAll();

echo json_encode($rows);
