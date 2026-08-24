<?php
require_once __DIR__.'/db.php';
$pdo = get_db();

$devices = $pdo->query("SELECT d.*,s.health_status,s.health_score,s.temperature_c,s.power_on_hours,s.reallocated_sector_count,s.pending_sector_count,s.uncorrectable_sector_count,s.wear_level_percent,s.self_test_status,s.smart_enabled,s.scan_date
FROM devices d LEFT JOIN scans s ON s.id=(SELECT id FROM scans WHERE device_id=d.id ORDER BY scan_date DESC,id DESC LIMIT 1)
ORDER BY d.hostname,d.device_path")->fetchAll();

$rawParts = $pdo->query("SELECT p.* FROM partitions p ORDER BY p.device_id,p.recorded_at DESC,p.id DESC")->fetchAll();
$latestTimes = [];
foreach ($rawParts as $p) {
    $key = (string)($p['device_id'] ?? 0);
    if (!isset($latestTimes[$key])) $latestTimes[$key] = $p['recorded_at'];
}
$partsByDevice = [];
$seenParts = [];
foreach ($rawParts as $p) {
    $key = (string)($p['device_id'] ?? 0);
    if (($latestTimes[$key] ?? null) !== ($p['recorded_at'] ?? null)) continue;
    $partKey = $key.'|'.($p['disk_number'] ?? '-').'|'.($p['partition_number'] ?? '-').'|'.($p['drive_letter'] ?? '-');
    if (isset($seenParts[$partKey])) continue;
    $seenParts[$partKey] = true;
    $partsByDevice[$key][] = $p;
}

$total = count($devices); $healthy = $warning = $failed = 0; $scores = [];
foreach ($devices as $d) {
    $st = strtoupper($d['health_status'] ?? 'UNKNOWN');
    if (in_array($st,['PASSED','HEALTHY'],true)) $healthy++;
    elseif ($st === 'WARNING') $warning++;
    elseif ($st === 'FAILED') $failed++;
    if ($d['health_score'] !== null) $scores[] = (float)$d['health_score'];
}
$unknown = max(0,$total-$healthy-$warning-$failed);
$avgHealth = $scores ? round(array_sum($scores)/count($scores)) : 0;
function h($v){ return htmlspecialchars((string)($v ?? ''), ENT_QUOTES, 'UTF-8'); }
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Storage Health Pro</title>
<link rel="stylesheet" href="assets/style.css?v=20260824.2">
</head>
<body>
<header class="topbar">
  <div class="brand-wrap">
    <div class="brand-mark" aria-hidden="true"><span></span><span></span><span></span></div>
    <div><h1>Storage Health <strong>Pro</strong></h1><p>SMART diagnostics · drive health · temperature · partition inventory</p></div>
  </div>
  <div class="header-actions">
    <span class="readonly-pill"><i></i> Read-only monitor</span>
    <button class="btn" data-scan-open>Scan Storage</button>
    <a class="btn" href="#partitions">Partitions</a>
    <a class="btn" href="api/devices.php" target="_blank" rel="noopener">JSON API</a>
  </div>
</header>

<main class="shell">
<section class="hero realtime-hero">
  <div class="hero-copy">
    <div class="eyebrow">REALTIME STORAGE MONITOR</div>
    <h2>Storage health at a glance</h2>
    <p>Monitor connected storage without leaving the dashboard. Telemetry refreshes automatically and all browser actions remain read-only.</p>
    <div class="hero-meta"><span>● Auto refresh every 3 seconds</span><span>● Local agent telemetry</span><span>● No destructive operations</span></div>
  </div>
  <div class="live-card"><div class="live-top"><span class="live-dot"></span><b id="liveState">LIVE</b></div><strong id="lastUpdate">Waiting for telemetry…</strong><small id="agentState">Connecting to local agent</small></div>
</section>

<section class="summary-grid" aria-label="Storage summary">
  <article class="summary-card blue"><div class="summary-icon">◉</div><div><span>Connected drives</span><strong id="sumTotal"><?=h($total)?></strong><small>Detected by the agent</small></div></article>
  <article class="summary-card green"><div class="summary-icon">✓</div><div><span>Healthy</span><strong id="sumHealthy"><?=h($healthy)?></strong><small>Operating normally</small></div></article>
  <article class="summary-card amber"><div class="summary-icon">!</div><div><span>Needs attention</span><strong id="sumAttention"><?=h($warning+$failed)?></strong><small><b id="sumWarning"><?=h($warning)?></b> warning · <b id="sumFailed"><?=h($failed)?></b> failed</small></div></article>
  <article class="summary-card purple"><div class="summary-icon">↗</div><div><span>Average health</span><strong id="sumHealth"><?=h($avgHealth)?>%</strong><small>Across reported scores</small></div></article>
</section>

<section class="control-strip">
  <div class="connection-state"><span class="state-dot" id="connectionDot"></span><div><b id="connectionTitle">Agent connecting</b><small id="connectionText">Waiting for the first telemetry response</small></div></div>
  <div class="control-actions"><label class="select-wrap"><span>Storage device</span><select id="deviceSelect"><option value="">Detecting devices…</option></select></label><button class="btn" id="refreshRealtime">↻ Refresh now</button><button class="btn primary" data-scan-open>Scan Storage</button></div>
</section>

<section class="device-focus">
  <div class="section-heading"><div><span class="eyebrow">SELECTED DEVICE</span><h3 id="selectedDeviceTitle">Select a storage device</h3><p id="selectedDevicePath">Choose a device to see its live capacity and telemetry.</p></div><div class="device-status"><span class="badge unknown" id="pcHealthBadge">UNKNOWN</span><strong id="pcCapacity">—</strong></div></div>
  <div class="volume-list" id="storageOverview"><div class="empty-state"><div class="empty-icon">◫</div><b>Waiting for device telemetry</b><span>Connect or select a storage device and the system will populate its live information.</span></div></div>
</section>

<section class="panel telemetry-panel">
  <div class="panel-head"><div><span class="eyebrow">DEVICE TELEMETRY</span><h3>Selected Device Telemetry</h3><p>Health, temperature, SMART and endurance indicators</p></div><span class="status-chip" id="telemetryStatus">Waiting</span></div>
  <div class="telemetry-grid">
    <article class="metric-card health"><span>Health</span><strong id="tHealth">—</strong><small id="tHealthScore">No score reported</small></article>
    <article class="metric-card"><span>Performance</span><strong id="tPerformance">—</strong><small>Windows telemetry score</small></article>
    <article class="metric-card temp"><span>Temperature</span><strong id="tTemp">—</strong><small>Current controller reading</small></article>
    <article class="metric-card"><span>Wear / Life</span><strong id="tWear">—</strong><small>SSD/NVMe where available</small></article>
    <article class="metric-card"><span>Power-on</span><strong id="tPower">—</strong><small>Total reported hours</small></article>
    <article class="metric-card"><span>SMART</span><strong id="tSmart">—</strong><small>Controller dependent</small></article>
  </div>
</section>

<section class="panel devices-panel">
  <div class="panel-head"><div><span class="eyebrow">CONNECTED HARDWARE</span><h3>Storage devices</h3><p>Select a device to focus the dashboard.</p></div><span class="muted" id="deviceCount">0 devices</span></div>
  <div id="deviceList" class="device-grid"></div>
</section>

<section class="panel partition-manager" id="partitions">
  <div class="panel-head"><div><span class="eyebrow">PARTITION INVENTORY</span><h3>Disk map &amp; volumes</h3><p>Read-only disk layout with filesystem, capacity and usage indicators.</p></div><div class="pm-actions"><button class="btn" id="pmRefresh">↻ Refresh</button><button class="btn" id="pmProperties">Properties</button></div></div>
  <div class="partition-layout">
    <div class="disk-list">
      <?php $diskGroups=[]; foreach($partsByDevice as $deviceId=>$items){ foreach($items as $p){ $k=$deviceId.':'.($p['disk_number']??'unknown'); $diskGroups[$k]['device_id']=$deviceId; $diskGroups[$k]['hostname']=$p['hostname']??'—'; $diskGroups[$k]['disk']=$p['disk_number']??'—'; $diskGroups[$k]['items'][]=$p; } }
      foreach($diskGroups as $g): ?>
      <article class="disk-card">
        <div class="disk-card-head"><div><div class="disk-title"><span class="disk-icon">▣</span><div><b>Disk <?=h($g['disk'])?></b><small><?=h($g['hostname'])?></small></div></div></div><span class="online-chip"><i></i> ONLINE</span></div>
        <div class="disk-map">
          <?php $diskTotal=array_sum(array_map(fn($x)=>(float)($x['size_bytes']??0),$g['items'])); foreach($g['items'] as $p): $size=(float)($p['size_bytes']??0); $grow=$diskTotal>0?max(.04,$size/$diskTotal):1; $fs=strtoupper($p['filesystem']??'UNFORMATTED'); $usage=(float)($p['usage_percent']??0); $tone=$usage>=90?'critical':($usage>=75?'warning':'normal'); ?>
          <button class="partition-block <?=$tone?>" style="--grow:<?=$grow?>" onclick='selectPartition(<?=json_encode($p,JSON_HEX_TAG|JSON_HEX_APOS|JSON_HEX_AMP|JSON_HEX_QUOT)?>,this)'><span class="part-letter"><?=h($p['drive_letter']?:'·')?></span><span class="part-name"><?=h($p['label']?:$fs)?></span><small><?=h($fs)?> · <?=h(bytes_human($p['size_bytes']))?></small></button>
          <?php endforeach; ?>
        </div>
      </article>
      <?php endforeach; ?>
      <?php if(!$diskGroups): ?><div class="empty-state"><div class="empty-icon">▤</div><b>No partition inventory yet</b><span>Run Scan Storage to populate the disk map.</span></div><?php endif; ?>
    </div>
    <aside class="partition-inspector">
      <div class="inspector-title"><div><span class="eyebrow">VOLUME DETAILS</span><h3 id="selectedLetter">None selected</h3></div><span class="badge unknown" id="partitionHealth">UNKNOWN</span></div>
      <div id="partitionDetails" class="details"><div class="inspector-empty"><span>◌</span><p>Select a partition from the disk map to inspect it.</p></div></div>
      <div class="readonly-note"><span>🔒</span><div><b>Read-only by design</b><p>This dashboard does not expose format, delete, resize, move, or other data-modifying operations.</p></div></div>
    </aside>
  </div>
  <div class="table-section"><div class="table-title"><div><b>Volume inventory</b><span>Latest reported partitions</span></div><span class="muted"><?=count($rawParts)?> records available</span></div><div class="table-wrap"><table id="partitionTable"><thead><tr><th>Host</th><th>Disk / Partition</th><th>Letter</th><th>Label</th><th>File system</th><th>Size</th><th>Free</th><th>Usage</th><th>Health</th></tr></thead><tbody>
  <?php foreach($partsByDevice as $items): foreach($items as $p): $hc=health_class($p['health']??'UNKNOWN'); ?><tr><td><b><?=h($p['hostname'])?></b></td><td><b><?=h(($p['disk_number']!==null?'Disk '.$p['disk_number']:'—').($p['partition_number']!==null?' / Part '.$p['partition_number']:''))?></b><small><?=h($p['device_path']??'')?></small></td><td><?=h($p['drive_letter']??'—')?></td><td><?=h($p['label']??'—')?></td><td><span class="fs-pill"><?=h($p['filesystem']??'—')?></span></td><td><?=h(bytes_human($p['size_bytes']))?></td><td><?=h(bytes_human($p['free_bytes']))?></td><td><?= $p['usage_percent']!==null?h($p['usage_percent']).'%':'—'?></td><td><span class="badge <?=$hc?>"><?=h($p['health']??'UNKNOWN')?></span></td></tr><?php endforeach; endforeach; ?>
  </tbody></table></div></div>
</section>
</main>

<div class="modal-backdrop" id="scanModal" aria-hidden="true"><div class="modal scan-modal" role="dialog" aria-modal="true"><button class="modal-close" id="scanClose">×</button><div class="modal-icon blue-icon">⌁</div><span class="eyebrow">READ-ONLY SCAN</span><div id="scanConfirm"><h3>Scan all storage devices?</h3><p>This checks physical disks, SMART information and partitions. Nothing is formatted, deleted, resized, moved or modified.</p><div class="scan-safe"><span>🔒</span><div><b>Safe monitoring operation</b><small>The local agent performs inventory collection only.</small></div></div><div class="modal-actions"><button class="btn" id="scanCancel">Cancel</button><button class="btn primary" id="scanConfirmBtn">Start Scan</button></div></div><div id="scanProgress" hidden><h3>Scanning storage…</h3><div class="progress"><i></i></div><p id="scanStatus">Detecting disks and partitions. Please wait.</p></div><div id="scanResult" hidden><h3 id="scanResultTitle">Scan complete</h3><p id="scanResultText"></p><div class="modal-actions"><button class="btn primary" id="scanDone">Done</button></div></div></div></div>

<script>
const ATC={devices:[],selected:null,poll:null};
const esc=s=>String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
const bytes=n=>{if(n===null||n===undefined||n==='')return '—';let x=Number(n),u=['B','KB','MB','GB','TB','PB'],i=0;while(x>=1024&&i<u.length-1){x/=1024;i++}return (i?x.toFixed(1):Math.round(x))+' '+u[i]};
const healthClass=s=>{s=(s||'UNKNOWN').toUpperCase();return s==='PASSED'||s==='HEALTHY'?'ok':s==='WARNING'?'warn':s==='FAILED'?'fail':'unknown'};
const $=id=>document.getElementById(id);
function renderSummary(){let healthy=0,warning=0,failed=0,scores=[];ATC.devices.forEach(d=>{let s=(d.health_status||'UNKNOWN').toUpperCase();if(s==='PASSED'||s==='HEALTHY')healthy++;else if(s==='WARNING')warning++;else if(s==='FAILED')failed++;if(d.health_score!=null)scores.push(Number(d.health_score))});$('sumTotal').textContent=ATC.devices.length;$('sumHealthy').textContent=healthy;$('sumWarning').textContent=warning;$('sumFailed').textContent=failed;$('sumAttention').textContent=warning+failed;$('sumHealth').textContent=(scores.length?Math.round(scores.reduce((a,b)=>a+b,0)/scores.length):0)+'%'}
function renderRealtime(){
 const current=ATC.devices.find(d=>String(d.id)===String(ATC.selected));
 const sel=$('deviceSelect');sel.innerHTML='<option value="">Select storage device…</option>'+ATC.devices.map(d=>`<option value="${esc(d.id)}">${esc(d.model||d.device_path||'Storage device')} · ${esc(d.drive_type||'Drive')}</option>`).join('');
 if(current)sel.value=String(current.id); else if(ATC.devices.length===1){ATC.selected=String(ATC.devices[0].id);sel.value=ATC.selected}
 $('deviceCount').textContent=`${ATC.devices.length} connected device${ATC.devices.length===1?'':'s'}`;renderSummary();
 const list=$('deviceList');list.innerHTML=ATC.devices.length?ATC.devices.map(d=>{const hs=healthClass(d.health_status);return `<button class="device-card ${String(d.id)===String(ATC.selected)?'active':''}" data-id="${esc(d.id)}"><span class="device-led ${hs}"></span><div class="device-main"><b>${esc(d.model||d.device_path||'Storage device')}</b><small>${esc(d.device_path||'—')} · ${esc(d.interface_type||d.drive_type||'Drive')}</small></div><div class="device-score"><strong>${d.health_score??'—'}</strong><small>/100</small></div><span class="mini-status ${hs}">${esc(d.health_status||'UNKNOWN')}</span></button>`}).join(''):'<div class="empty-state compact"><div class="empty-icon">◉</div><b>No devices reported</b><span>Start the local agent or run a storage scan.</span></div>';
 list.querySelectorAll('.device-card').forEach(b=>b.onclick=()=>{ATC.selected=b.dataset.id;renderRealtime()});
 if(!current){$('selectedDeviceTitle').textContent='Select a storage device';$('selectedDevicePath').textContent='Choose a device to see its live capacity and telemetry.';$('pcHealthBadge').textContent='UNKNOWN';$('pcHealthBadge').className='badge unknown';$('pcCapacity').textContent='—';return}
 const ps=current.partition_summary||{}, health=current.health_status||'UNKNOWN';
 $('selectedDeviceTitle').textContent=current.model||current.device_path||'Storage device';$('selectedDevicePath').textContent=[current.device_path,current.hostname,current.interface_type].filter(Boolean).join(' · ')||'Storage device';$('pcHealthBadge').textContent=health;$('pcHealthBadge').className='badge '+healthClass(health);$('pcCapacity').textContent=ps.size?bytes(ps.size):'—';
 $('tHealth').textContent=health;$('tHealthScore').textContent=current.health_score!=null?`${current.health_score}/100 score`:'No score reported';$('tPerformance').textContent=current.health_score!=null?`${Math.max(0,Math.min(100,Number(current.health_score)))}%`:'—';$('tTemp').textContent=current.temperature_c!=null?`${current.temperature_c} °C`:'—';$('tWear').textContent=current.wear_level_percent!=null?`${current.wear_level_percent}%`:'—';$('tPower').textContent=current.power_on_hours!=null?`${Number(current.power_on_hours).toLocaleString()} h`:'—';$('tSmart').textContent=Number(current.smart_enabled)===1?'Enabled':Number(current.smart_enabled)===0?'Unavailable':current.self_test_status||'—';$('telemetryStatus').textContent=current.scan_date?'Updated '+current.scan_date:'Waiting';
 const parts=current.partitions||[];$('storageOverview').innerHTML=parts.length?parts.map(p=>{const total=Number(p.size_bytes||0),free=Number(p.free_bytes||0),used=total?Math.max(0,Math.min(100,((total-free)/total)*100)):0;const tone=used>=90?'critical':used>=75?'warning':'normal';return `<article class="volume-card"><div class="volume-icon">${esc((p.drive_letter||'').replace(':','')||'•')}</div><div class="volume-main"><div class="volume-title"><b>${esc(p.drive_letter||p.label||'Volume')}</b><span>${esc(p.label||'Local Disk')}</span></div><div class="volume-bar"><i class="${tone}" style="width:${used}%"></i></div><div class="volume-meta"><span>${bytes(total)} total</span><span>${bytes(free)} free</span><span>${used.toFixed(0)}% used</span></div></div><div class="volume-fs"><b>${esc(p.filesystem||'Unknown')}</b><small>${esc(p.health||'ONLINE')}</small></div></article>`}).join(''):`<div class="empty-state"><div class="empty-icon">▱</div><b>No mounted volumes reported</b><span>The physical device is connected, but Windows has not exposed a volume for it.</span></div>`;
 $('lastUpdate').textContent='Updated '+new Date().toLocaleTimeString();$('agentState').textContent='Telemetry is updating automatically';
}
async function pollRealtime(){try{const r=await fetch('api/devices.php?realtime=1&t='+Date.now(),{cache:'no-store'});if(!r.ok)throw new Error();const data=await r.json();ATC.devices=Array.isArray(data)?data:[];if(ATC.selected&&!ATC.devices.some(d=>String(d.id)===String(ATC.selected)))ATC.selected=null;renderRealtime();$('liveState').textContent='LIVE';$('connectionTitle').textContent='Agent connected';$('connectionText').textContent='Live telemetry is updating automatically';$('connectionDot').className='state-dot connected';$('telemetryStatus').classList.remove('offline')}catch(e){$('liveState').textContent='OFFLINE';$('agentState').textContent='Unable to reach local agent';$('connectionTitle').textContent='Agent offline';$('connectionText').textContent='Start the agent, then press Refresh now';$('connectionDot').className='state-dot offline';$('telemetryStatus').textContent='Reader offline';$('telemetryStatus').classList.add('offline')}}
$('deviceSelect').onchange=e=>{ATC.selected=e.target.value||null;renderRealtime()};$('refreshRealtime').onclick=pollRealtime;pollRealtime();ATC.poll=setInterval(pollRealtime,3000);

let selectedPartition=null;function humanBytes(n){return bytes(n)}
function selectPartition(p,el){selectedPartition=p;$('selectedLetter').textContent=p.drive_letter||'Partition';$('partitionHealth').textContent=p.health||'UNKNOWN';$('partitionHealth').className='badge '+healthClass(p.health);$('partitionDetails').innerHTML=`<div class="detail-row"><span>Volume</span><b>${esc(p.drive_letter||'—')} ${esc(p.label||'')}</b></div><div class="detail-row"><span>Filesystem</span><b>${esc(p.filesystem||'—')}</b></div><div class="detail-row"><span>Capacity</span><b>${humanBytes(p.size_bytes)}</b></div><div class="detail-row"><span>Free space</span><b>${humanBytes(p.free_bytes)}</b></div><div class="detail-row"><span>Usage</span><b>${p.usage_percent!=null?esc(p.usage_percent)+'%':'—'}</b></div><div class="detail-row"><span>Partition type</span><b>${esc(p.partition_type||'—')}</b></div><div class="detail-row"><span>Mount point</span><b>${esc(p.mount_point||'—')}</b></div>`;document.querySelectorAll('.partition-block').forEach(x=>x.classList.remove('selected'));if(el)el.classList.add('selected')}
$('pmRefresh').onclick=()=>location.reload();$('pmProperties').onclick=()=>{if(!selectedPartition){$('partitions').scrollIntoView({behavior:'smooth',block:'start'});return}$('partitions').scrollIntoView({behavior:'smooth',block:'start'})};

const scanModal=$('scanModal'),confirmBox=$('scanConfirm'),progress=$('scanProgress'),result=$('scanResult');function openScan(){scanModal.classList.add('show');scanModal.setAttribute('aria-hidden','false');confirmBox.hidden=false;progress.hidden=true;result.hidden=true}function closeScan(){scanModal.classList.remove('show');scanModal.setAttribute('aria-hidden','true')}document.querySelectorAll('[data-scan-open]').forEach(b=>b.onclick=openScan);$('scanCancel').onclick=closeScan;$('scanClose').onclick=closeScan;$('scanDone').onclick=()=>{closeScan();pollRealtime()};scanModal.onclick=e=>{if(e.target===scanModal)closeScan()};document.addEventListener('keydown',e=>{if(e.key==='Escape')closeScan();});$('scanConfirmBtn').onclick=async()=>{confirmBox.hidden=true;progress.hidden=false;try{const r=await fetch('api/scan.php',{method:'POST',headers:{'X-Requested-With':'XMLHttpRequest'}});const j=await r.json();progress.hidden=true;result.hidden=false;$('scanResultTitle').textContent=j.ok?'Scan started':'Scan could not start';$('scanResultText').textContent=j.message||'The scan request finished. The dashboard will update when telemetry arrives.'}catch(e){progress.hidden=true;result.hidden=false;$('scanResultTitle').textContent='Scan failed';$('scanResultText').textContent='Unable to contact the scan service. You can run the agent manually.'}};
</script>
</body></html>
