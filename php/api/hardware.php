<?php
require_once __DIR__.'/../db.php';
header('Content-Type: application/json; charset=utf-8');
$pdo=get_db();
try {
  $rows=$pdo->query("SELECT id,hostname,category,identifier,name,status,details_json,last_seen FROM hardware_devices WHERE last_seen >= DATE_SUB(NOW(), INTERVAL 20 SECOND) ORDER BY category,name")->fetchAll();
  $groups=[]; $seen=[];
  foreach($rows as $r){
    $cat=$r['category'] ?: 'other';
    $r['details']=$r['details_json']?json_decode($r['details_json'],true):[]; unset($r['details_json']);
    // Storage can be reported by both SMART and the OS inventory. Prefer one
    // entry per physical serial; fall back to the device path/identifier.
    $d=$r['details'];
    $serial=strtolower(trim((string)($d['serial_number']??$d['serial']??'')));
    $path=strtolower(trim((string)($d['device_path']??$d['name']??$r['identifier']??'')));
    $name=strtolower(trim((string)($r['name']??'')));
    $key=$cat.'|'.($serial!==''?'serial:'.$serial:($path!==''?'path:'.$path:'name:'.$name));
    if(isset($seen[$key])) continue;
    $seen[$key]=true;
    $groups[$cat][]=$r;
  }
  foreach(['storage','printers','ram','smartphones','usb','network','media','other'] as $c) if(!isset($groups[$c])) $groups[$c]=[];
  $ram=['total_bytes'=>null,'free_bytes'=>null,'used_bytes'=>null,'usage_percent'=>null]; if(!empty($groups['ram'][0]['details'])) $ram=$groups['ram'][0]['details']+$ram;
  echo json_encode(['ok'=>true,'hostname'=>$rows[0]['hostname']??gethostname(),'updated_at'=>date('c'),'groups'=>$groups,'ram'=>$ram],JSON_UNESCAPED_SLASHES);
} catch(Throwable $e){ http_response_code(500); echo json_encode(['ok'=>false,'message'=>'Hardware inventory unavailable']); }
