<?php
// Read-only local file browser. Access is restricted to OS storage roots and never writes/deletes/executes files.
header('Content-Type: application/json; charset=utf-8');

function json_out($data,$code=200){http_response_code($code);echo json_encode($data,JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);exit;}
function is_win(){return PHP_OS_FAMILY==='Windows';}
function roots(){
  $configured=getenv('ATESTCHECKER_FILE_ROOTS');
  if($configured){$r=preg_split('/[;|]+/', $configured,-1,PREG_SPLIT_NO_EMPTY); return array_values(array_filter(array_map('realpath',$r)));}
  if(is_win()){
    $out=[];
    foreach(range('A','Z') as $l){$p=$l.':'.DIRECTORY_SEPARATOR;if(is_dir($p))$out[]=realpath($p);}
    return $out;
  }
  $candidates=is_dir('/Volumes')?['/Users','/Volumes','/media','/mnt','/run/media']:['/home','/media','/mnt','/run/media'];
  return array_values(array_filter(array_unique(array_map('realpath',$candidates)),'is_string'));
}
function inside($path,$root){$p=strtolower(rtrim($path,DIRECTORY_SEPARATOR).DIRECTORY_SEPARATOR);$r=strtolower(rtrim($root,DIRECTORY_SEPARATOR).DIRECTORY_SEPARATOR);return $p===$r || str_starts_with($p,$r);}
function normalize_requested_path($requested){
  $requested=trim((string)$requested);
  if($requested==='') return '';
  if(is_win()){
    // Accept drive letters from the device inventory: C, C:, C:\, or C:/.
    if(preg_match('/^([A-Za-z])(?::)?[\\\/]*$/',$requested,$m)) return strtoupper($m[1]).':\\';
    $requested=str_replace('/','\\',$requested);
  }
  return $requested;
}
function drive_root($drive){
  if(!is_win()) return null;
  $drive=preg_replace('/[^A-Za-z]/','',(string)$drive);
  if($drive==='') return null;
  $root=strtoupper($drive[0]).':\\';
  return is_dir($root)?realpath($root):null;
}
function resolve_allowed($requested){
  $requested=normalize_requested_path($requested); $requested=$requested!==''?$requested:null; $rs=roots();
  if(!$requested){return [$rs[0]??null,$rs];}
  $real=realpath($requested); if($real===false) json_out(['ok'=>false,'message'=>'Folder does not exist or is not accessible.'],404);
  foreach($rs as $root) if(inside($real,$root)) return [$real,$rs];
  json_out(['ok'=>false,'message'=>'Access denied: this path is outside the configured read-only roots.'],403);
}
function file_info($p){$isDir=is_dir($p);$st=@stat($p);return ['name'=>basename($p),'path'=>$p,'type'=>$isDir?'directory':'file','size'=>$isDir?null:($st['size']??null),'modified'=>$st?date('c',$st['mtime']):null,'readable'=>is_readable($p)];}
$action=$_GET['action']??'list';
if($action==='roots') json_out(['ok'=>true,'roots'=>array_map(fn($r)=>file_info($r),roots())]);
if($action==='drive'){
  $root=drive_root($_GET['drive']??'');
  if(!$root) json_out(['ok'=>false,'message'=>'The requested storage drive is not mounted or readable.'],404);
  json_out(['ok'=>true,'root'=>file_info($root)]);
}
if($action==='preview'){
  [$path]=resolve_allowed($_GET['path']??''); if(!is_file($path)||!is_readable($path))json_out(['ok'=>false,'message'=>'File is not readable.'],403);
  $size=filesize($path); if($size===false||$size>1048576)json_out(['ok'=>false,'message'=>'Preview is limited to readable text files up to 1 MB.'],413);
  $sample=file_get_contents($path); if($sample===false)json_out(['ok'=>false,'message'=>'Unable to read file.'],403);
  if(strpos($sample,"\0")!==false)json_out(['ok'=>false,'message'=>'Binary files are metadata-only and cannot be previewed.'],415);
  $sample=mb_convert_encoding($sample,'UTF-8','UTF-8,ISO-8859-1,Windows-1252');
  json_out(['ok'=>true,'file'=>file_info($path),'content'=>$sample]);
}
[$path,$rs]=resolve_allowed($_GET['path']??'');
if(!$path) json_out(['ok'=>false,'message'=>'No readable storage root was found.'],404);
if(!is_dir($path)||!is_readable($path))json_out(['ok'=>false,'message'=>'Folder is not readable.'],403);
$items=[]; $dh=@opendir($path); if($dh===false)json_out(['ok'=>false,'message'=>'Unable to open folder.'],403);
while(($name=readdir($dh))!==false){if($name==='.'||$name==='..')continue;$full=$path.DIRECTORY_SEPARATOR.$name;if(!is_readable($full))continue;$items[]=file_info($full);}closedir($dh);
usort($items,function($a,$b){if($a['type']!==$b['type'])return $a['type']==='directory'?-1:1;return strnatcasecmp($a['name'],$b['name']);});
$parent=dirname($path);$parentAllowed=null;foreach($rs as $r)if(inside($parent,$r)){$parentAllowed=$parent;break;}
json_out(['ok'=>true,'current'=>file_info($path),'parent'=>$parentAllowed,'items'=>$items,'roots'=>array_map(fn($r)=>file_info($r),$rs)]);
