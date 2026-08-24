<?php
require_once __DIR__ . '/config.php';

function get_db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4';
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
    return $pdo;
}

function health_class(string $status): string {
    return match (strtoupper($status)) {
        'PASSED' => 'ok',
        'WARNING' => 'warn',
        'FAILED' => 'fail',
        default => 'unknown',
    };
}

function bytes_human($bytes): string { if($bytes===null) return '—'; $u=['B','KB','MB','GB','TB','PB']; $i=0; $n=(float)$bytes; while($n>=1024&&$i<count($u)-1){$n/=1024;$i++;} return number_format($n,$i?1:0).' '.$u[$i]; }
