<?php
require_once __DIR__ . '/../db.php';
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['error'=>'POST only']); exit; }
$apiKey=$_SERVER['HTTP_X_API_KEY']??''; $pdo=get_db();
$s=$pdo->prepare('SELECT id FROM api_keys WHERE api_key=?'); $s->execute([$apiKey]);
if(!$s->fetch()){http_response_code(401);echo json_encode(['error'=>'invalid api key']);exit;}
$body=json_decode(file_get_contents('php://input'),true);
if(!$body||empty($body['device_path'])||empty($body['hostname'])){http_response_code(400);echo json_encode(['error'=>'missing hostname/device_path']);exit;}
$serial=$body['serial_number']??null;
$s=$pdo->prepare('SELECT id FROM devices WHERE hostname=? AND device_path=? AND (serial_number=? OR (serial_number IS NULL AND ? IS NULL))');
$s->execute([$body['hostname'],$body['device_path'],$serial,$serial]); $d=$s->fetch();
if($d){$deviceId=$d['id'];$u=$pdo->prepare('UPDATE devices SET model=?,interface_type=?,drive_type=?,last_seen=NOW() WHERE id=?');$u->execute([$body['model']??null,$body['interface_type']??null,$body['drive_type']??null,$deviceId]);}
else{$i=$pdo->prepare('INSERT INTO devices(hostname,device_path,model,serial_number,interface_type,drive_type) VALUES(?,?,?,?,?,?)');$i->execute([$body['hostname'],$body['device_path'],$body['model']??null,$serial,$body['interface_type']??null,$body['drive_type']??null]);$deviceId=$pdo->lastInsertId();}
$i=$pdo->prepare('INSERT INTO scans(device_id,health_status,health_score,temperature_c,power_on_hours,reallocated_sector_count,pending_sector_count,uncorrectable_sector_count,wear_level_percent,self_test_status,smart_enabled,raw_smart_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)');
$i->execute([$deviceId,$body['health_status']??'UNKNOWN',$body['health_score']??null,$body['temperature_c']??null,$body['power_on_hours']??null,$body['reallocated_sector_count']??null,$body['pending_sector_count']??null,$body['uncorrectable_sector_count']??null,$body['wear_level_percent']??null,$body['self_test_status']??null,isset($body['smart_enabled'])?(int)$body['smart_enabled']:null,isset($body['raw'])?json_encode($body['raw']):null]);
$scanId=$pdo->lastInsertId();
if(!empty($body['partitions'])&&is_array($body['partitions'])){
 $pi=$pdo->prepare('INSERT INTO partitions(hostname,device_id,disk_number,partition_number,drive_letter,device_path,label,filesystem,partition_type,gpt_type,mount_point,size_bytes,free_bytes,usage_percent,health) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
 foreach($body['partitions'] as $p){$total=$p['total_bytes']??$p['size_bytes']??null;$free=$p['free_bytes']??null;$usage=$p['usage_percent']??(($total&&$free!==null)?round((1-$free/$total)*100,2):null);
  $pi->execute([$body['hostname'],$deviceId,$p['disk_number']??null,$p['partition_number']??null,$p['drive_letter']??null,$p['device_path']??null,$p['label']??null,$p['filesystem']??null,$p['type']??null,$p['gpt_type']??null,$p['mount_point']??$p['mountpoint']??null,$total,$free,$usage,$p['health']??null]);
 }
}
echo json_encode(['status'=>'ok','device_id'=>$deviceId,'scan_id'=>$scanId]);
