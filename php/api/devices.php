<?php
require_once __DIR__.'/../db.php';
header('Content-Type: application/json; charset=utf-8');
$pdo=get_db();
$rows=$pdo->query("SELECT d.*,s.health_status,s.health_score,s.temperature_c,s.power_on_hours,s.reallocated_sector_count,s.pending_sector_count,s.uncorrectable_sector_count,s.wear_level_percent,s.self_test_status,s.smart_enabled,s.scan_date
FROM devices d LEFT JOIN scans s ON s.id=(SELECT id FROM scans WHERE device_id=d.id ORDER BY scan_date DESC,id DESC LIMIT 1)
ORDER BY d.hostname,d.device_path")->fetchAll();

$parts=$pdo->query("SELECT p.* FROM partitions p ORDER BY p.device_id,p.recorded_at DESC,p.id DESC")->fetchAll();
$latest=[];$seen=[];$byDevice=[];
foreach($parts as $p){
  $did=(string)($p['device_id']??0);
  if(!isset($latest[$did])) $latest[$did]=$p['recorded_at'];
  if(($latest[$did]??null)!==($p['recorded_at']??null)) continue;
  $key=$did.'|'.($p['disk_number']??'-').'|'.($p['partition_number']??'-').'|'.($p['drive_letter']??'-');
  if(isset($seen[$key])) continue;
  $seen[$key]=true;
  $byDevice[$did][]=$p;
}
foreach($rows as &$r){
  $did=(string)$r['id'];
  $items=$byDevice[$did]??[];
  $size=0;$free=0;
  foreach($items as $p){$size+=(float)($p['size_bytes']??0);$free+=(float)($p['free_bytes']??0);}
  $r['partitions']=$items;
  $r['partition_summary']=['c'=>count($items),'size'=>$size,'free'=>$free];
}
unset($r);
echo json_encode($rows,JSON_UNESCAPED_SLASHES);
