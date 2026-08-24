

const ATC={devices:[],selected:null,volumeFilter:'',poll:null};
const esc=s=>String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));
const bytes=n=>{if(n===null||n===undefined||n==='')return '—';let x=Number(n),u=['B','KB','MB','GB','TB','PB'],i=0;while(x>=1024&&i<u.length-1){x/=1024;i++}return (i?x.toFixed(1):Math.round(x))+' '+u[i]};
const healthClass=s=>{s=(s||'UNKNOWN').toUpperCase();return s==='PASSED'||s==='HEALTHY'?'ok':s==='WARNING'?'warn':s==='FAILED'?'fail':'unknown'};
const $=id=>document.getElementById(id);
function renderSummary(){let healthy=0,warning=0,failed=0,scores=[];ATC.devices.forEach(d=>{let s=(d.health_status||'UNKNOWN').toUpperCase();if(s==='PASSED'||s==='HEALTHY')healthy++;else if(s==='WARNING')warning++;else if(s==='FAILED')failed++;if(d.health_score!=null)scores.push(Number(d.health_score))});$('sumTotal').textContent=ATC.devices.length;$('sumHealthy').textContent=healthy;$('sumWarning').textContent=warning;$('sumFailed').textContent=failed;$('sumAttention').textContent=warning+failed;$('sumHealth').textContent=(scores.length?Math.round(scores.reduce((a,b)=>a+b,0)/scores.length):0)+'%'}
function getDriveLetter(p){return String(p?.drive_letter||'').trim().replace(/:$/,'').toUpperCase()}
function populateVolumeFilters(device){
 const parts=(device?.partitions||[]).filter(p=>getDriveLetter(p));
 const seen=new Set(), options=[];
 parts.forEach(p=>{const l=getDriveLetter(p);if(seen.has(l))return;seen.add(l);options.push({letter:l,label:p.label||'Local Disk',fs:p.filesystem||'Unknown',mount:p.mount_point||p.mountpoint||`${l}:`})});
 const html='<option value="">All drive letters</option>'+options.map(o=>`<option value="${esc(o.letter)}">${esc(o.letter)}: · ${esc(o.label)} · ${esc(o.fs)}</option>`).join('');
 const top=$('volumeFilter'); if(top){top.innerHTML=html;if(ATC.volumeFilter && !options.some(o=>o.letter===ATC.volumeFilter))ATC.volumeFilter='';top.value=ATC.volumeFilter||'';}
 const pm=$('partitionVolumeFilter'); if(pm){pm.innerHTML='<option value="">All volumes on selected storage</option>'+options.map(o=>`<option value="${esc(o.letter)}">${esc(o.letter)}: · ${esc(o.label)} · ${esc(o.fs)}</option>`).join('');pm.value=ATC.volumeFilter||'';}
}
function applyPartitionLetterFilter(letter){
 const wanted=String(letter||'').toUpperCase();
 document.querySelectorAll('.storage-device-view').forEach(view=>{
   const isSelected=!ATC.selected || view.id===`storage-view-${ATC.selected}`;
   view.hidden=!isSelected;
   if(!isSelected)return;
   let visible=0;
   view.querySelectorAll('.storage-disk-group').forEach(group=>{
     let groupVisible=0;
     group.querySelectorAll('[data-drive-letter]').forEach(el=>{
       const match=!wanted || String(el.dataset.driveLetter||'').toUpperCase()===wanted;
       el.hidden=!match;
       if(match)groupVisible++;
     });
     group.hidden=groupVisible===0;
     if(groupVisible)visible+=groupVisible;
   });
   const hint=$('storageFilterHint');
   if(hint){hint.textContent=wanted?`Showing ${wanted}: only. This volume belongs to the selected physical storage.`:'Showing all drive letters assigned to the selected physical storage.';}
   const body=view.querySelector('.storage-device-body');
   if(body){let empty=body.querySelector('.storage-filter-empty');if(!visible&&wanted){if(!empty){empty=document.createElement('div');empty.className='storage-filter-empty';empty.innerHTML='<b>Drive letter not found on this storage</b><span>Choose another assigned volume or select all drive letters.</span>';body.appendChild(empty)}}else if(empty)empty.remove();}
 });
}
function selectStorageDevice(id, preserveLetter=false){
 ATC.selected=id||null;
 const d=ATC.devices.find(x=>String(x.id)===String(ATC.selected));
 if(!preserveLetter)ATC.volumeFilter='';
 populateVolumeFilters(d);
 renderRealtime();
 applyPartitionLetterFilter(ATC.volumeFilter);
}
function renderRealtime(){
 const current=ATC.devices.find(d=>String(d.id)===String(ATC.selected));
 const sel=$('deviceSelect');
 sel.innerHTML='<option value="">Select physical storage…</option>'+ATC.devices.map(d=>{
   const letters=[...(new Set((d.partitions||[]).map(getDriveLetter).filter(Boolean)))].join(', ');
   return `<option value="${esc(d.id)}">${esc(d.model||d.device_path||'Storage device')} · ${esc(d.drive_type||'Drive')}${letters?` · ${esc(letters)}`:''}</option>`
 }).join('');
 if(current)sel.value=String(current.id); else if(ATC.devices.length===1){ATC.selected=String(ATC.devices[0].id);return renderRealtime()}
 populateVolumeFilters(current);
 $('deviceCount').textContent=`${ATC.devices.length} connected device${ATC.devices.length===1?'':'s'}`;renderSummary();
 const list=$('deviceList');
 const visibleDevices=ATC.devices.filter(matchesDevice);
 list.innerHTML=visibleDevices.length?visibleDevices.map(d=>{const hs=healthClass(d.health_status);const letters=[...(new Set((d.partitions||[]).map(getDriveLetter).filter(Boolean)))];return `<article class="device-card ${String(d.id)===String(ATC.selected)?'active':''}" data-id="${esc(d.id)}"><button class="device-card-main" type="button"><span class="device-led ${hs}"></span><div class="device-main"><b>${esc(d.model||d.device_path||'Storage device')}</b><small>${esc(d.device_path||'—')} · ${esc(d.interface_type||d.drive_type||'Drive')}</small>${letters.length?`<span class="device-drive-letters">${letters.map(l=>`<i>${esc(l)}:</i>`).join('')}</span>`:''}</div><div class="device-score"><strong>${d.health_score??'—'}</strong><small>/100</small></div><span class="mini-status ${hs}">${esc(d.health_status||'UNKNOWN')}</span></button><button class="view-files-btn" type="button" data-device-id="${esc(d.id)}">▰ View Files</button></article>`}).join(''):(ATC.devices.length?'<div class="empty-state compact"><div class="empty-icon">⌕</div><b>No matching devices</b><span>Try another search term.</span></div>':'<div class="empty-state compact"><div class="empty-icon">◉</div><b>No devices reported</b><span>Start the local agent or run a storage scan.</span></div>');
 list.querySelectorAll('.device-card-main').forEach(b=>b.onclick=()=>selectStorageDevice(b.closest('.device-card').dataset.id));
 list.querySelectorAll('.view-files-btn').forEach(b=>b.onclick=e=>{e.stopPropagation();const d=ATC.devices.find(x=>String(x.id)===String(b.dataset.deviceId));const part=(d?.partitions||[]).find(x=>x.mount_point||x.mountpoint||x.drive_letter);if(part)openVolumeFiles(part);else openFiles('')});
 if(!current){$('selectedDeviceTitle').textContent='Select a storage device';$('selectedDevicePath').textContent='Choose a device to see its live capacity and telemetry.';$('pcHealthBadge').textContent='UNKNOWN';$('pcHealthBadge').className='badge unknown';$('pcCapacity').textContent='—';applyPartitionLetterFilter('');return}
 const ps=current.partition_summary||{}, health=current.health_status||'UNKNOWN';
 $('selectedDeviceTitle').textContent=current.model||current.device_path||'Storage device';$('selectedDevicePath').textContent=[current.device_path,current.hostname,current.interface_type].filter(Boolean).join(' · ')||'Storage device';$('pcHealthBadge').textContent=health;$('pcHealthBadge').className='badge '+healthClass(health);$('pcCapacity').textContent=ps.size?bytes(ps.size):'—';
 $('tHealth').textContent=health;$('tHealthScore').textContent=current.health_score!=null?`${current.health_score}/100 score`:'No score reported';$('tPerformance').textContent=current.health_score!=null?`${Math.max(0,Math.min(100,Number(current.health_score)))}%`:'—';$('tTemp').textContent=current.temperature_c!=null?`${current.temperature_c} °C`:'—';$('tWear').textContent=current.wear_level_percent!=null?`${current.wear_level_percent}%`:'—';$('tPower').textContent=current.power_on_hours!=null?`${Number(current.power_on_hours).toLocaleString()} h`:'—';$('tSmart').textContent=Number(current.smart_enabled)===1?'Enabled':Number(current.smart_enabled)===0?'Unavailable':current.self_test_status||'—';$('telemetryStatus').textContent=current.scan_date?'Updated '+current.scan_date:'Waiting';
 const wanted=String(ATC.volumeFilter||'').toUpperCase();
 const rawParts=(current.partitions||[]).filter(p=>!wanted||getDriveLetter(p)===wanted);
 const seenVolumeLetters=new Set();
 const parts=[];
 rawParts.forEach(p=>{const l=getDriveLetter(p);if(l){if(seenVolumeLetters.has(l))return;seenVolumeLetters.add(l);}parts.push(p);});
 $('storageOverview').innerHTML=parts.length?parts.map(p=>{const total=Number(p.size_bytes||0),free=Number(p.free_bytes||0),used=total?Math.max(0,Math.min(100,((total-free)/total)*100)):0;const tone=used>=90?'critical':used>=75?'warning':'normal';const letter=String(p.drive_letter||'').replace(/:$/,'')||'·';return `<details class="volume-card compact-volume"${wanted?' open':''}><summary class="volume-summary"><span class="volume-icon">${esc(letter)}</span><span class="volume-main"><span class="volume-title"><b>${esc(p.drive_letter||p.label||'Volume')}</b><span>${esc(p.label||'Local Disk')}</span></span><span class="volume-bar"><i class="${tone}" style="width:${used}%"></i></span><span class="volume-meta"><span>${bytes(total)}</span><span>${bytes(free)} free</span><span>${used.toFixed(0)}% used</span></span></span><span class="volume-fs"><b>${esc(p.filesystem||'Unknown')}</b><small>${esc(p.health||'ONLINE')}</small></span><span class="volume-chevron">›</span></summary><div class="volume-expanded"><div class="volume-detail-grid"><div><span>Capacity</span><b>${bytes(total)}</b></div><div><span>Free space</span><b>${bytes(free)}</b></div><div><span>Usage</span><b>${used.toFixed(0)}%</b></div><div><span>Mount</span><b>${esc(p.mount_point||p.mountpoint||p.drive_letter||'—')}</b></div></div><button class="view-files-volume" type="button" data-mount="${esc(p.mount_point||p.mountpoint||'')}" data-drive="${esc(p.drive_letter||'')}" ${p.mount_point||p.mountpoint||p.drive_letter?'':'disabled'}>▰ View Files</button></div></details>`}).join(''):`<div class="empty-state"><div class="empty-icon">▱</div><b>${wanted?`Drive ${esc(wanted)}: is not assigned to this storage`:'No mounted volumes reported'}</b><span>${wanted?'Choose another drive letter or select all volumes.':'The physical device is connected, but Windows has not exposed a volume for it.'}</span></div>`;
 document.querySelectorAll('.view-files-volume').forEach(b=>b.onclick=()=>openVolumeFiles({mount_point:b.dataset.mount||'',drive_letter:b.dataset.drive||''}));
 applyPartitionLetterFilter(wanted);
 $('lastUpdate').textContent='Updated '+new Date().toLocaleTimeString();$('agentState').textContent='Telemetry is updating automatically';
}
async function pollRealtime(){try{const r=await fetch('api/devices.php?realtime=1&t='+Date.now(),{cache:'no-store'});if(!r.ok)throw new Error();const data=await r.json();ATC.devices=Array.isArray(data)?data:[];if(ATC.selected&&!ATC.devices.some(d=>String(d.id)===String(ATC.selected)))ATC.selected=null;renderRealtime();$('liveState').textContent='LIVE';$('connectionTitle').textContent='Agent connected';$('connectionText').textContent='Live telemetry is updating automatically';$('connectionDot').className='state-dot connected';$('telemetryStatus').classList.remove('offline')}catch(e){$('liveState').textContent='OFFLINE';$('agentState').textContent='Unable to reach local agent';$('connectionTitle').textContent='Agent offline';$('connectionText').textContent='Start the agent, then press Refresh now';$('connectionDot').className='state-dot offline';$('telemetryStatus').textContent='Reader offline';$('telemetryStatus').classList.add('offline')}}
$('deviceSelect').onchange=e=>selectStorageDevice(e.target.value||null);
$('volumeFilter').onchange=e=>{ATC.volumeFilter=e.target.value||'';renderRealtime();applyPartitionLetterFilter(ATC.volumeFilter)};
$('refreshRealtime').onclick=pollRealtime;pollRealtime();ATC.poll=setInterval(pollRealtime,3000);

let selectedPartition=null;function humanBytes(n){return bytes(n)}
function selectPartition(p,el){selectedPartition=p;$('selectedLetter').textContent=p.drive_letter||'Partition';$('partitionHealth').textContent=p.health||'UNKNOWN';$('partitionHealth').className='badge '+healthClass(p.health);$('partitionDetails').innerHTML=`<div class="detail-row"><span>Volume</span><b>${esc(p.drive_letter||'—')} ${esc(p.label||'')}</b></div><div class="detail-row"><span>Filesystem</span><b>${esc(p.filesystem||'—')}</b></div><div class="detail-row"><span>Capacity</span><b>${humanBytes(p.size_bytes)}</b></div><div class="detail-row"><span>Free space</span><b>${humanBytes(p.free_bytes)}</b></div><div class="detail-row"><span>Usage</span><b>${p.usage_percent!=null?esc(p.usage_percent)+'%':'—'}</b></div><div class="detail-row"><span>Partition type</span><b>${esc(p.partition_type||'—')}</b></div><div class="detail-row"><span>Mount point</span><b>${esc(p.mount_point||'—')}</b></div>`;document.querySelectorAll('.partition-block').forEach(x=>x.classList.remove('selected'));if(el)el.classList.add('selected')}
const partitionDeviceSelect=$('partitionDeviceSelect');
function showPartitionStorageView(id){document.querySelectorAll('.storage-device-view').forEach(v=>v.hidden=v.id!==id); const d=ATC.devices.find(x=>`storage-view-${x.id}`===id); if(d){ATC.selected=String(d.id);ATC.volumeFilter='';populateVolumeFilters(d);renderRealtime();}else{applyPartitionLetterFilter('');}}
if(partitionDeviceSelect){partitionDeviceSelect.addEventListener('change',()=>showPartitionStorageView(partitionDeviceSelect.value)); if(partitionDeviceSelect.value)showPartitionStorageView(partitionDeviceSelect.value);}
const partitionVolumeFilter=$('partitionVolumeFilter');
if(partitionVolumeFilter){partitionVolumeFilter.addEventListener('change',()=>{ATC.volumeFilter=partitionVolumeFilter.value||'';const top=$('volumeFilter');if(top)top.value=ATC.volumeFilter;renderRealtime();applyPartitionLetterFilter(ATC.volumeFilter);});}

$('pmRefresh').onclick=()=>location.reload();$('pmProperties').onclick=()=>{if(!selectedPartition){$('partitions').scrollIntoView({behavior:'smooth',block:'start'});return}$('partitions').scrollIntoView({behavior:'smooth',block:'start'})};

let hardwareState={groups:{storage:[],printers:[],ram:[],smartphones:[],usb:[],network:[],media:[],other:[]},ram:{}};
const categoryMeta={storage:['Storage','Physical drives, health and partitions.'],printers:['Printers','Connected and installed printers.'],ram:['RAM','System memory capacity and utilization.'],smartphones:['Smartphones','Connected Android and iOS devices.'],usb:['USB & Peripherals','USB, Bluetooth, HID and attached peripherals.'],network:['Network Devices','Network adapters and PCI network hardware.'],media:['Audio / Display','Audio, display, camera and media hardware.'],other:['Other Devices','Additional hardware reported by the operating system.']};
let activeCategory='storage';
function hardwareCard(h,category){const d=h.details||{};let sub='';if(category==='printers')sub=[d.driver,d.port].filter(Boolean).join(' · ')||'Printer device';if(category==='smartphones')sub=d.platform?`${d.platform} · ${d.serial||d.udid||h.identifier}`:h.identifier;if(category==='ram')sub=`${bytes(d.total_bytes)} total · ${d.usage_percent??'—'}% used`;if(category==='usb')sub=[d.manufacturer,d.class,d.instance_id||d.bluetooth_id].filter(Boolean).join(' · ')||h.identifier;if(category==='network'||category==='media')sub=d.raw||d.class||d.description||h.identifier;if(category==='other')sub=d.description||d.class||h.identifier;return `<article class="hardware-card"><div class="hardware-icon">${category==='printers'?'▤':category==='smartphones'?'▯':category==='ram'?'▥':category==='usb'?'⌁':category==='network'?'⌁':category==='media'?'◉':'◈'}</div><div class="hardware-main"><b>${esc(h.name||h.identifier)}</b><small>${esc(sub)}</small></div><div class="hardware-status"><span class="mini-status ${String(h.status).toUpperCase()==='ONLINE'||String(h.status).toUpperCase()==='OK'?'ok':'warn'}">${esc(h.status||'UNKNOWN')}</span><small>${esc(h.last_seen||'')}</small></div></article>`}
function renderHardware(){const g=hardwareState.groups||{};const ids={storage:'navStorageCount',printers:'navPrinterCount',ram:'navRamCount',smartphones:'navPhoneCount',usb:'navUsbCount',network:'navNetworkCount',media:'navMediaCount',other:'navOtherCount'};Object.entries(ids).forEach(([c,id])=>{const el=$(id);if(el)el.textContent=c==='ram'?((g.ram||[]).length?'1':'0'):(g[c]||[]).length});const items=g[activeCategory]||[];$('hardwareTitle').textContent=categoryMeta[activeCategory][0];$('hardwareSubtitle').textContent=categoryMeta[activeCategory][1];$('hardwareStatus').textContent=hardwareState.updated_at?'UPDATED '+new Date(hardwareState.updated_at).toLocaleTimeString():'WAITING';if(activeCategory==='ram'){const d=(g.ram&&g.ram[0]&&g.ram[0].details)||hardwareState.ram||{};const total=Number(d.total_bytes||0),free=Number(d.free_bytes||0),used=Number(d.used_bytes||Math.max(0,total-free)),pct=d.usage_percent!=null?Number(d.usage_percent):(total?Math.round(used/total*100):0);$('hardwareContent').innerHTML=`<div class="ram-dashboard"><div class="ram-ring" style="--pct:${pct}%"><div><strong>${pct}%</strong><span>used</span></div></div><div class="ram-stats"><article><span>Total memory</span><b>${bytes(total)}</b></article><article><span>Used memory</span><b>${bytes(used)}</b></article><article><span>Available</span><b>${bytes(free)}</b></article></div></div>`;return}$('hardwareContent').innerHTML=items.length?`<div class="hardware-grid">${items.map(h=>hardwareCard(h,activeCategory)).join('')}</div>`:`<div class="empty-state"><div class="empty-icon">◌</div><b>No ${categoryMeta[activeCategory][0].toLowerCase()} detected</b><span>Run “Scan connected devices” or connect the hardware to the local computer.</span></div>`}
async function pollHardware(){try{const r=await fetch('api/hardware.php?t='+Date.now(),{cache:'no-store'});if(!r.ok)throw new Error();hardwareState=await r.json();renderHardware();$('sidebarAgentDot').className='state-dot connected';$('sidebarAgentTitle').textContent='Agent connected';$('sidebarAgentText').textContent='Live hardware inventory';}catch(e){$('sidebarAgentDot').className='state-dot offline';$('sidebarAgentTitle').textContent='Agent offline';$('sidebarAgentText').textContent='Start the local agent'}}

let fileCurrent=null;
function fileEsc(v){return esc(v)}
async function fileLoad(path=''){try{const r=await fetch('api/files.php?action=list&path='+encodeURIComponent(path),{cache:'no-store'});const j=await r.json();if(!j.ok)throw new Error(j.message||'Unable to read folder');fileCurrent=j.current.path;$('filePath').value=j.current.path;$('fileBreadcrumb').textContent=j.current.path;$('fileRoots').innerHTML=j.roots.map(x=>`<option value="${fileEsc(x.path)}">${fileEsc(x.path)}</option>`).join('');const items=j.items||[];$('fileList').innerHTML=items.length?items.map(x=>`<button class="file-row" data-path="${fileEsc(x.path)}" data-type="${x.type}"><span class="file-icon">${x.type==='directory'?'▰':'▱'}</span><span><b>${fileEsc(x.name)}</b><small>${x.type==='directory'?'Folder':bytes(x.size||0)+' · '+(x.modified||'')}</small></span><em>${x.type==='directory'?'›':'VIEW'}</em></button>`).join(''):`<div class="empty-state compact"><b>Folder is empty</b><span>No readable entries were found.</span></div>`;document.querySelectorAll('.file-row').forEach(b=>b.onclick=()=>b.dataset.type==='directory'?fileLoad(b.dataset.path):filePreview(b.dataset.path));$('fileUp').disabled=!j.parent;}catch(e){$('fileList').innerHTML=`<div class="empty-state compact"><b>Unable to open folder</b><span>${fileEsc(e.message)}</span></div>`}}
async function filePreview(path){try{const r=await fetch('api/files.php?action=preview&path='+encodeURIComponent(path),{cache:'no-store'});const j=await r.json();if(!j.ok)throw new Error(j.message||'Preview unavailable');$('filePreview').innerHTML=`<div class="preview-head"><div><span class="eyebrow">TEXT PREVIEW</span><b>${fileEsc(j.file.name)}</b><small>${fileEsc(j.file.path)}</small></div></div><pre>${fileEsc(j.content)}</pre>`}catch(e){$('filePreview').innerHTML=`<div class="empty-state compact"><b>Preview unavailable</b><span>${fileEsc(e.message)}</span></div>`}}
$('fileOpen').onclick=()=>fileLoad($('filePath').value.trim());$('fileRoots').onchange=e=>{if(e.target.value)fileLoad(e.target.value)};$('fileUp').onclick=()=>{if(fileCurrent)fileLoad(fileCurrent.replace(/[\\\/]([^\\\/]+)[\\\/]?$/,'')||'')};
async function openFiles(targetPath=''){
  activeCategory='files';
  document.querySelectorAll('.nav-item').forEach(x=>x.classList.toggle('active',x.dataset.category==='files'));
  document.querySelectorAll('.content-column > section:not(#hardwareCenter):not(#fileCenter)').forEach(x=>x.hidden=true);
  $('hardwareCenter').hidden=true; $('fileCenter').hidden=false;
  try{
    const r=await fetch('api/files.php?action=roots',{cache:'no-store'}); const j=await r.json();
    if(!j.ok) throw new Error(j.message||'Unable to detect storage roots');
    if(!j.roots.length){$('fileList').innerHTML='<div class="empty-state compact"><b>No readable storage volumes</b><span>Connect or mount a storage volume, then scan devices again.</span></div>';return;}
    $('fileRoots').innerHTML=j.roots.map(x=>`<option value="${fileEsc(x.path)}">${fileEsc(x.path)}</option>`).join('');
    const requested=targetPath&&j.roots.some(x=>String(targetPath).toLowerCase().startsWith(String(x.path).toLowerCase()));
    await fileLoad(requested?targetPath:j.roots[0].path);
  }catch(e){$('fileList').innerHTML=`<div class="empty-state compact"><b>Storage file access unavailable</b><span>${fileEsc(e.message||'Unable to detect storage roots.')}</span></div>`}
  window.scrollTo({top:0,behavior:'smooth'});
}
async function openVolumeFiles(p){
  const mount=String(p?.mount_point||p?.mountpoint||'').trim();
  if(mount) return openFiles(mount);
  const drive=String(p?.drive_letter||'').replace(/[^A-Za-z]/g,'');
  if(drive){
    try{
      const r=await fetch('api/files.php?action=drive&drive='+encodeURIComponent(drive),{cache:'no-store'}); const j=await r.json();
      if(!j.ok) throw new Error(j.message||'Drive is not mounted or readable');
      return openFiles(j.root.path);
    }catch(e){
      activeCategory='files'; document.querySelectorAll('.nav-item').forEach(x=>x.classList.toggle('active',x.dataset.category==='files'));
      $('hardwareCenter').hidden=true; $('fileCenter').hidden=false;
      $('fileList').innerHTML=`<div class="empty-state compact"><b>Unable to open ${fileEsc(drive+':')}</b><span>${fileEsc(e.message||'The volume is not readable.')}</span></div>`;
      return;
    }
  }
  return openFiles('');
}
$('viewSelectedFiles').onclick=()=>{const d=ATC.devices.find(x=>String(x.id)===String(ATC.selected));const p=(d?.partitions||[]).find(x=>x.mount_point||x.mountpoint||x.drive_letter);openVolumeFiles(p)};
const deviceSearch=$('deviceSearch');
function matchesDevice(d){const q=String(deviceSearch?.value||'').trim().toLowerCase();if(!q)return true;return [d.model,d.device_path,d.hostname,d.interface_type,d.drive_type,d.serial_number].filter(Boolean).join(' ').toLowerCase().includes(q)}
if(deviceSearch)deviceSearch.addEventListener('input',()=>renderRealtime());
document.querySelectorAll('.nav-item').forEach(b=>b.onclick=()=>{activeCategory=b.dataset.category;if(activeCategory==='files'){openFiles();return}document.querySelectorAll('.nav-item').forEach(x=>x.classList.toggle('active',x===b));const storage=document.querySelectorAll('.content-column > section:not(#hardwareCenter):not(#fileCenter)');const center=$('hardwareCenter');$('fileCenter').hidden=true;if(activeCategory==='storage'){center.hidden=true;storage.forEach(x=>x.hidden=false)}else{storage.forEach(x=>x.hidden=true);center.hidden=false;renderHardware()}window.scrollTo({top:0,behavior:'smooth'})});
pollHardware();setInterval(pollHardware,5000);
const scanModal=$('scanModal'),confirmBox=$('scanConfirm'),progress=$('scanProgress'),result=$('scanResult');function openScan(){scanModal.classList.add('show');scanModal.setAttribute('aria-hidden','false');confirmBox.hidden=false;progress.hidden=true;result.hidden=true}function closeScan(){scanModal.classList.remove('show');scanModal.setAttribute('aria-hidden','true')}document.querySelectorAll('[data-scan-open]').forEach(b=>b.onclick=openScan);$('scanCancel').onclick=closeScan;$('scanClose').onclick=closeScan;$('scanDone').onclick=()=>{closeScan();pollRealtime()};scanModal.onclick=e=>{if(e.target===scanModal)closeScan()};document.addEventListener('keydown',e=>{if(e.key==='Escape')closeScan();});$('scanConfirmBtn').onclick=async()=>{confirmBox.hidden=true;progress.hidden=false;try{const r=await fetch('api/scan.php',{method:'POST',headers:{'X-Requested-With':'XMLHttpRequest'}});const j=await r.json();progress.hidden=true;result.hidden=false;$('scanResultTitle').textContent=j.ok?'Scan started':'Scan could not start';$('scanResultText').textContent=j.message||'The scan request finished. The dashboard will update when telemetry arrives.'}catch(e){progress.hidden=true;result.hidden=false;$('scanResultTitle').textContent='Scan failed';$('scanResultText').textContent='Unable to contact the scan service. You can run the agent manually.'}};

