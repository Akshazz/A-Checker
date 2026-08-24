<?php
require_once __DIR__ . '/../db.php';
header('Content-Type: application/json; charset=utf-8');
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok'=>false,'message'=>'POST only']);
    exit;
}

$root = realpath(__DIR__ . '/../..');
$agent = $root . DIRECTORY_SEPARATOR . 'agent' . DIRECTORY_SEPARATOR . 'agent.js';
$configFile = dirname($agent) . DIRECTORY_SEPARATOR . 'config.json';
if (!is_file($agent) || !is_file($configFile)) {
    http_response_code(500);
    echo json_encode(['ok'=>false,'message'=>'Agent or agent configuration is missing.']);
    exit;
}

$config = json_decode((string)@file_get_contents($configFile), true);
if (!is_array($config)) $config = [];

// Always point the one-shot scan at this exact installation. This avoids a
// common failure where a copied project still contains an old localhost path.
$scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$phpRoot = rtrim(dirname(dirname($_SERVER['SCRIPT_NAME'] ?? '/php/api/scan.php')), '/\\');
$config['serverUrl'] = $scheme . '://' . $host . $phpRoot . '/api/report.php';

// The default key is also installed by schema.sql. Keep it usable for a
// fresh installation; setup scripts can replace it with a generated key.
if (empty($config['apiKey'])) $config['apiKey'] = '__API_KEY__';
@file_put_contents($configFile, json_encode($config, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

$node = PHP_OS_FAMILY === 'Windows' ? 'node.exe' : 'node';
$nodeCheck = [];
@exec(PHP_OS_FAMILY === 'Windows' ? 'where node' : 'command -v node', $nodeCheck, $nodeCode);
if ($nodeCode !== 0) {
    http_response_code(503);
    echo json_encode(['ok'=>false,'message'=>'Node.js is not available to the web server. Start the local agent manually or install Node.js.']);
    exit;
}

$cwd = dirname($agent);
$agentPath = $agent;
if (PHP_OS_FAMILY === 'Windows') {
    $cmd = 'start "" /b cmd /c "cd /d "' . str_replace('"','\\"',str_replace('/','\\',$cwd)) . '" && node "' . str_replace('"','\\"',str_replace('/','\\',$agentPath)) . '" --once"';
    @pclose(@popen($cmd, 'r'));
} else {
    $log = '/tmp/a-testchecker-scan.log';
    $cmd = 'cd ' . escapeshellarg($cwd) . ' && nohup node ' . escapeshellarg($agentPath) . ' --once >> ' . escapeshellarg($log) . ' 2>&1 &';
    @exec($cmd);
}

echo json_encode([
    'ok'=>true,
    'message'=>'Read-only device scan started. Storage, printers, RAM, smartphones, USB/peripherals, network and other detected hardware will be refreshed shortly.',
    'serverUrl'=>$config['serverUrl']
]);
