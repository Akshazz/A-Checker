<?php
require_once __DIR__.'/../db.php';
header('Content-Type: application/json; charset=utf-8');
$pdo=get_db();

// Only expose real physical storage records. The old __INVENTORY__ record was
// a synthetic report container and must never appear as a storage device.
$rows=$pdo->query("SELECT d.*,s.health_status,s.health_score,s.temperature_c,s.power_on_hours,s.reallocated_sector_count,s.pending_sector_count,s.uncorrectable_sector_count,s.wear_level_percent,s.self_test_status,s.smart_enabled,s.scan_date
FROM devices d LEFT JOIN scans s ON s.id=(SELECT id FROM scans WHERE device_id=d.id ORDER BY scan_date DESC,id DESC LIMIT 1)
WHERE d.device_path <> '__INVENTORY__'
ORDER BY d.hostname,d.last_seen DESC,d.id DESC")->fetchAll();

$parts=$pdo->query("SELECT p.* FROM partitions p ORDER BY p.device_id,p.recorded_at DESC,p.id DESC")->fetchAll();
$latest=[];$seen=[];$byDevice=[];
foreach($parts as $p){
  $did=(string)($p['device_id']??0);
  if(!isset($latest[$did])) $latest[$did]=$p['recorded_at'];
  if(($latest[$did]??null)!==($p['recorded_at']??null)) continue;
  $key=$did.'|'.($p['disk_number']??'-').'|'.($p['partition_number']??'-').'|'.($p['drive_letter']??'-').'|'.($p['device_path']??'-');
  if(isset($seen[$key])) continue;
  $seen[$key]=true;
  $byDevice[$did][]=$p;
}

function partition_matches_device(array $p, array $d): bool {
  $devicePath=strtolower(str_replace('\\','/',trim((string)($d['device_path']??''))));
  $partPath=strtolower(str_replace('\\','/',trim((string)($p['device_path']??''))));
  if($devicePath==='' || $devicePath==='__inventory__') return true;
  if(preg_match('/physicaldrive(\d+)/i',$devicePath,$m) && $p['disk_number']!==null) return (string)$p['disk_number']===$m[1];
  if($partPath!==''){
    if($partPath===$devicePath) return true;
    if(str_starts_with($partPath,$devicePath)){
      $rest=substr($partPath,strlen($devicePath));
      return $rest!=='' && (ctype_digit($rest[0]) || $rest[0]==='p' || $rest[0]==='s');
    }
  }
  return false;
}

// Attach only the newest partition snapshot to each device.
foreach($rows as &$r){
  $did=(string)$r['id'];
  $items=array_values(array_filter($byDevice[$did]??[],fn($p)=>partition_matches_device($p,$r)));
  $size=0;$free=0;
  foreach($items as $p){$size+=(float)($p['size_bytes']??0);$free+=(float)($p['free_bytes']??0);}
  $r['partitions']=$items;
  $r['partition_summary']=['c'=>count($items),'size'=>$size,'free'=>$free];
}
unset($r);

// De-duplicate records produced by older agents. Prefer serial number when
// available; otherwise the physical device path is the stable identity.
$unique=[];$aliases=[];
foreach($rows as $r){
  $host=strtolower(trim((string)($r['hostname']??'')));
  $serial=strtolower(trim((string)($r['serial_number']??'')));
  $path=strtolower(trim((string)($r['device_path']??'')));
  $key=$host.'|'.($serial!=='' ? 'serial:'.$serial : 'path:'.$path);
  if(!isset($unique[$key])){$unique[$key]=$r;continue;}
  // Keep the freshest/best populated record.
  $old=$unique[$key];
  $scoreOld=(int)!empty($old['model'])+(int)!empty($old['serial_number'])+(int)!empty($old['health_status'])+count($old['partitions']??[]);
  $scoreNew=(int)!empty($r['model'])+(int)!empty($r['serial_number'])+(int)!empty($r['health_status'])+count($r['partitions']??[]);
  if($scoreNew>$scoreOld || strtotime((string)$r['last_seen'])>strtotime((string)$old['last_seen'])) $unique[$key]=$r;
  $aliases[]=$r['id'];
}

$out=array_values($unique);
echo json_encode($out,JSON_UNESCAPED_SLASHES);
