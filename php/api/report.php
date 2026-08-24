<?php
require_once __DIR__ . '/../db.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'POST only']);
    exit;
}

// --- Authenticate ---
$apiKey = $_SERVER['HTTP_X_API_KEY'] ?? '';
$pdo = get_db();
$stmt = $pdo->prepare('SELECT id FROM api_keys WHERE api_key = ?');
$stmt->execute([$apiKey]);
if (!$stmt->fetch()) {
    http_response_code(401);
    echo json_encode(['error' => 'invalid api key']);
    exit;
}

// --- Parse payload ---
$body = json_decode(file_get_contents('php://input'), true);
if (!$body || empty($body['device_path']) || empty($body['hostname'])) {
    http_response_code(400);
    echo json_encode(['error' => 'missing required fields (hostname, device_path)']);
    exit;
}

// --- Upsert device ---
$stmt = $pdo->prepare(
    'SELECT id FROM devices WHERE hostname = ? AND device_path = ? AND
     (serial_number = ? OR (serial_number IS NULL AND ? IS NULL))'
);
$serial = $body['serial_number'] ?? null;
$stmt->execute([$body['hostname'], $body['device_path'], $serial, $serial]);
$device = $stmt->fetch();

if ($device) {
    $deviceId = $device['id'];
    $upd = $pdo->prepare('UPDATE devices SET model=?, interface_type=?, drive_type=?, last_seen=NOW() WHERE id=?');
    $upd->execute([$body['model'] ?? null, $body['interface_type'] ?? null, $body['drive_type'] ?? null, $deviceId]);
} else {
    $ins = $pdo->prepare(
        'INSERT INTO devices (hostname, device_path, model, serial_number, interface_type, drive_type)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    $ins->execute([
        $body['hostname'], $body['device_path'], $body['model'] ?? null,
        $serial, $body['interface_type'] ?? null, $body['drive_type'] ?? null,
    ]);
    $deviceId = $pdo->lastInsertId();
}

// --- Insert scan result ---
$ins = $pdo->prepare(
    'INSERT INTO scans (device_id, health_status, temperature_c, power_on_hours,
        reallocated_sector_count, pending_sector_count, uncorrectable_sector_count,
        wear_level_percent, raw_smart_json)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
);
$ins->execute([
    $deviceId,
    $body['health_status'] ?? 'UNKNOWN',
    $body['temperature_c'] ?? null,
    $body['power_on_hours'] ?? null,
    $body['reallocated_sector_count'] ?? null,
    $body['pending_sector_count'] ?? null,
    $body['uncorrectable_sector_count'] ?? null,
    $body['wear_level_percent'] ?? null,
    isset($body['raw']) ? json_encode($body['raw']) : null,
]);

echo json_encode(['status' => 'ok', 'device_id' => $deviceId, 'scan_id' => $pdo->lastInsertId()]);
