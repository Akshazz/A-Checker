<?php
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo json_encode(['ok'=>false,'message'=>'POST only']); exit; }
// Local-machine helper: starts the existing read-only agent in the background.
$root=realpath(__DIR__.'/../..');
$agent=$root.DIRECTORY_SEPARATOR.'agent'.DIRECTORY_SEPARATOR.'agent.js';
if(!is_file($agent)){http_response_code(500);echo json_encode(['ok'=>false,'message'=>'Agent not found.']);exit;}
$node='node';
if(PHP_OS_FAMILY==='Windows'){
  $cmd='where node'; @exec($cmd,$o,$code);
  if($code!==0){http_response_code(503);echo json_encode(['ok'=>false,'message'=>'Node.js is not available to the web server. Start the agent with START-A-TestChecker.bat.']);exit;}
  $cwd=dirname($agent);
  $command='start "A-TestChecker Scan" /b cmd /c "cd /d "'.str_replace('/','\\',$cwd).'" && "node" "'.str_replace('/','\\',$agent).'""';
  @pclose(@popen($command,'r'));
}else{
  @exec('cd '.escapeshellarg(dirname($agent)).' && nohup node '.escapeshellarg($agent).' >/tmp/a-testchecker-scan.log 2>&1 &');
}
echo json_encode(['ok'=>true,'message'=>'The read-only storage scan was started. The dashboard will update when the agent reports results.']);
