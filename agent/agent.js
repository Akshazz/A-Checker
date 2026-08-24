#!/usr/bin/env node
/**
 * Storage Health Monitor - Advanced Windows/Linux/macOS agent.
 * Collects SMART data plus OS disk/partition inventory and posts it to PHP.
 * Safe by default: partition operations are READ-ONLY; no formatting,
 * deletion, resizing or destructive surface tests are triggered remotely.
 */
const { execFile } = require('child_process');
const os = require('os');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

const CONFIG_PATH = path.join(__dirname, 'config.json');

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) throw new Error('Missing config.json');
  return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
}
function run(cmd, args, options={}) {
  return new Promise(resolve => {
    execFile(cmd, args, {maxBuffer: 20*1024*1024, windowsHide:true, ...options},
      (err, stdout, stderr) => resolve({stdout: stdout || '', stderr: stderr || '', code: err?.code ?? 0}));
  });
}
async function runPowerShell(script) {
  const r = await run('powershell.exe', ['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-Command',script]);
  try { return JSON.parse(r.stdout); } catch { return []; }
}
async function collectPartitions() {
  if (process.platform === 'win32') {
    const ps = `$ErrorActionPreference='SilentlyContinue'; Get-Partition | ForEach-Object {
      $p=$_; $v=Get-Volume -Partition $p -ErrorAction SilentlyContinue;
      [pscustomobject]@{
        disk_number=[int]$p.DiskNumber; partition_number=[int]$p.PartitionNumber;
        device_path=('\\.\PhysicalDrive'+[int]$p.DiskNumber);
        drive_letter=if($p.DriveLetter){[string]$p.DriveLetter}else{$null};
        size_bytes=[int64]$p.Size; offset_bytes=[int64]$p.Offset;
        type=[string]$p.Type; gpt_type=[string]$p.GptType;
        filesystem=if($v){[string]$v.FileSystem}else{$null};
        label=if($v){[string]$v.FileSystemLabel}else{$null};
        total_bytes=if($v){[int64]$v.Size}else{$null};
        free_bytes=if($v){[int64]$v.SizeRemaining}else{$null};
        health=if($v){[string]$v.HealthStatus}else{$null};
        mount_point=if($p.DriveLetter){([string]$p.DriveLetter)+':\'}else{$null};
      }
    } | ConvertTo-Json -Compress -Depth 5`;
    const data=await runPowerShell(ps);
    return Array.isArray(data)?data:(data&&typeof data==='object'?[data]:[]);
  }
  if (process.platform === 'linux') {
    const r=await run('lsblk',['-J','-b','-o','NAME,PATH,SIZE,FSTYPE,LABEL,MOUNTPOINT,FSAVAIL,FSUSE%,TYPE']);
    try {
      const flat=[];
      const walk=(xs,parentPath=null)=>{for(const x of xs||[]){
        const currentPath=x.path||('/dev/'+x.name);
        if(x.type==='part'||x.mountpoint||x.fstype) flat.push({
          device_path:currentPath, parent_device_path:parentPath, size_bytes:Number(x.size)||null, filesystem:x.fstype||null,
          label:x.label||null, mount_point:x.mountpoint||null, free_bytes:x.fsavail?Number(x.fsavail):null,
          usage_percent:x['fsuse%']?parseFloat(x['fsuse%']):null});
        walk(x.children,currentPath);
      }};
      walk(JSON.parse(r.stdout).blockdevices); return flat;
    } catch { return []; }
  }
  if (process.platform === 'darwin') {
    const r=await run('diskutil',['list','-plist','physical']);
    return [{device_path:'macOS diskutil inventory', raw:r.stdout}];
  }
  return [];
}
async function commandExists(cmd){
  const r=await run(process.platform==='win32'?'where':'which',[cmd]);
  return r.code===0;
}
function normalizeDeviceCategory(cls=''){
  const c=String(cls).toLowerCase();
  if(/usb|bluetooth|hid|keyboard|mouse|game|scsi|1394|port|modem/.test(c)) return 'usb';
  if(/net|wifi|wireless/.test(c)) return 'network';
  if(/camera|image|media|audio|sound|display|monitor/.test(c)) return 'media';
  return 'other';
}
async function collectGenericHardware(){
  const out=[];
  if(process.platform==='win32'){
    const ps=`$ErrorActionPreference='SilentlyContinue'; Get-PnpDevice | ForEach-Object { $d=$_; $p=Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_Manufacturer' -ErrorAction SilentlyContinue; [pscustomobject]@{name=[string]$d.FriendlyName; class=[string]$d.Class; status=[string]$d.Status; instance_id=[string]$d.InstanceId; manufacturer=if($p){[string]$p.Data}else{$null}} } | ConvertTo-Json -Compress -Depth 5`;
    const rows=await runPowerShell(ps); const arr=Array.isArray(rows)?rows:(rows&&typeof rows==='object'?[rows]:[]);
    for(const d of arr){ if(!d.name && !d.instance_id) continue; const cat=normalizeDeviceCategory(d.class); out.push({category:cat,identifier:d.instance_id||d.name,name:d.name||d.instance_id,status:String(d.status||'UNKNOWN').toUpperCase(),details:{class:d.class,manufacturer:d.manufacturer,instance_id:d.instance_id}}); }
  } else if(process.platform==='linux'){
    if(await commandExists('lsusb')){
      const r=await run('lsusb',[]); for(const line of (r.stdout||'').split(/\r?\n/).filter(Boolean)){ const m=line.match(/^Bus\s+(\S+)\s+Device\s+(\S+):\s+ID\s+(\S+)\s+(.*)$/); if(m) out.push({category:'usb',identifier:`${m[1]}-${m[2]}`,name:m[4],status:'ONLINE',details:{bus:m[1],device:m[2],id:m[3],raw:line}}); }
    }
    if(await commandExists('lspci')){ const r=await run('lspci',[]); for(const line of (r.stdout||'').split(/\r?\n/).filter(Boolean)){ const cat=/network|ethernet|wireless/i.test(line)?'network':/audio|display|vga|3d/i.test(line)?'media':'other'; const id=line.split(' ')[0]||line; out.push({category:cat,identifier:`pci:${id}`,name:line,status:'ONLINE',details:{raw:line}}); } }
    if(await commandExists('bluetoothctl')){ const r=await run('bluetoothctl',['devices']); for(const line of (r.stdout||'').split(/\r?\n/).filter(Boolean)){ const m=line.match(/^Device\s+(\S+)\s+(.*)$/); if(m) out.push({category:'usb',identifier:`bt:${m[1]}`,name:m[2],status:'ONLINE',details:{bluetooth_id:m[1]}}); } }
  } else if(process.platform==='darwin'){
    const specs=[['SPUSBDataType','usb'],['SPBluetoothDataType','usb'],['SPDisplaysDataType','media'],['SPAudioDataType','media'],['SPNetworkDataType','network']];
    for(const [type,cat] of specs){ const r=await run('system_profiler',[type,'-json']); try{const obj=JSON.parse(r.stdout||'{}'); const root=Object.values(obj)[0]; const walk=(v)=>{if(Array.isArray(v)){for(const x of v)walk(x);return} if(v&&typeof v==='object'){const name=v._name||v.name; const id=v.serial_num||v.device_serial_num||v.address||v.vendor_id; if(name) out.push({category:cat,identifier:`${type}:${id||name}`,name,status:'ONLINE',details:v}); for(const x of Object.values(v))walk(x);}}; walk(root);}catch{} }
  }
  return out;
}
async function collectHardware(){
  const hardware=[]; const host=os.hostname();
  // Memory and printers are normalized across supported platforms.
  if(process.platform==='win32'){
    const psRam=`$ErrorActionPreference='SilentlyContinue'; $o=Get-CimInstance Win32_OperatingSystem; [pscustomobject]@{total_bytes=[int64]$o.TotalVisibleMemorySize*1024; free_bytes=[int64]$o.FreePhysicalMemory*1024; used_bytes=([int64]$o.TotalVisibleMemorySize-[int64]$o.FreePhysicalMemory)*1024} | ConvertTo-Json -Compress`;
    const ram=await runPowerShell(psRam); if(ram&&typeof ram==='object'){const total=Number(ram.total_bytes)||0,free=Number(ram.free_bytes)||0; hardware.push({category:'ram',identifier:'system-memory',name:`System RAM · ${formatBytes(total)}`,status:'ONLINE',details:{...ram,usage_percent:total?Math.round((1-free/total)*100):null}});}
    const psPrinters=`$ErrorActionPreference='SilentlyContinue'; Get-Printer | ForEach-Object { [pscustomobject]@{name=[string]$_.Name; driver=[string]$_.DriverName; port=[string]$_.PortName; status=[string]$_.PrinterStatus; work_offline=[bool]$_.WorkOffline} } | ConvertTo-Json -Compress -Depth 4`;
    const printers=await runPowerShell(psPrinters); const parr=Array.isArray(printers)?printers:(printers&&typeof printers==='object'?[printers]:[]); for(const pr of parr) hardware.push({category:'printers',identifier:String(pr.name||pr.port||Math.random()),name:pr.name||'Printer',status:pr.work_offline?'OFFLINE':'ONLINE',details:pr});
  } else if(process.platform==='linux'||process.platform==='darwin'){
    if(await commandExists('lpstat')){const r=await run('lpstat',['-p']); for(const line of (r.stdout||'').split(/\r?\n/)){const m=line.match(/^printer\s+(\S+)\s+(.*)$/i);if(m)hardware.push({category:'printers',identifier:m[1],name:m[1],status:/disabled/i.test(m[2])?'OFFLINE':'ONLINE',details:{description:m[2]}});}}
    const total=os.totalmem(),free=os.freemem(); hardware.push({category:'ram',identifier:'system-memory',name:`System RAM · ${formatBytes(total)}`,status:'ONLINE',details:{total_bytes:total,free_bytes:free,used_bytes:total-free,usage_percent:Math.round((1-free/total)*100)}});
  }
  // Android and iOS bridges are optional and read-only.
  if(await commandExists('adb')){const adb=await run('adb',['devices','-l']);for(const line of (adb.stdout||'').split(/\r?\n/).slice(1)){if(!line.trim()||/\boffline\b/i.test(line)||/\bunauthorized\b/i.test(line))continue;const m=line.trim().match(/^(\S+)\s+device\s*(.*)$/);if(m)hardware.push({category:'smartphones',identifier:m[1],name:`Android · ${m[1]}`,status:'ONLINE',details:{platform:'Android',serial:m[1],raw:m[2]}});}}
  if(await commandExists('idevice_id')){const ios=await run('idevice_id',['-l']);for(const id of (ios.stdout||'').split(/\r?\n/).map(x=>x.trim()).filter(Boolean))hardware.push({category:'smartphones',identifier:id,name:`iPhone/iPad · ${id.slice(0,8)}`,status:'ONLINE',details:{platform:'iOS',udid:id}});}
  hardware.push(...await collectGenericHardware());
  return hardware;
}
function formatBytes(n){ const u=['B','KB','MB','GB','TB']; let i=0,x=Number(n)||0; while(x>=1024&&i<u.length-1){x/=1024;i++;} return `${x.toFixed(i?1:0)} ${u[i]}`; }

async function discoverOsStorage() {
  const out=[];
  if(process.platform==='win32'){
    const ps=`$ErrorActionPreference='SilentlyContinue'; Get-Disk | ForEach-Object { [pscustomobject]@{number=[int]$_.Number; name=[string]$_.FriendlyName; serial=[string]$_.SerialNumber; size_bytes=[int64]$_.Size; bus=[string]$_.BusType; health=[string]$_.HealthStatus; operational=[string]$_.OperationalStatus} } | ConvertTo-Json -Compress -Depth 4`;
    const rows=await runPowerShell(ps); const arr=Array.isArray(rows)?rows:(rows&&typeof rows==='object'?[rows]:[]);
    for(const d of arr){
      if(d.number===undefined) continue;
      out.push({name:`\\\\.\\PhysicalDrive${d.number}`, model:d.name||null, serial_number:d.serial||null, size_bytes:Number(d.size_bytes)||null, interface_type:d.bus||null, os_health:d.health||null});
    }
  } else if(process.platform==='linux'){
    const r=await run('lsblk',['-J','-b','-d','-o','NAME,PATH,SIZE,MODEL,SERIAL,TRAN,TYPE']);
    try{const data=JSON.parse(r.stdout||'{}');for(const d of data.blockdevices||[]){if(d.type!=='disk')continue;out.push({name:d.path||('/dev/'+d.name),model:d.model||null,serial_number:d.serial||null,size_bytes:Number(d.size)||null,interface_type:d.tran||null});}}catch{}
  } else if(process.platform==='darwin'){
    const r=await run('diskutil',['list','physical']);
    for(const line of (r.stdout||'').split(/\r?\n/)){const m=line.match(/^(?:\s*\d+:\s+[^\s]+\s+[^\s]+\s+[^\s]+\s+)(disk\d+)/);if(m)out.push({name:'/dev/'+m[1],model:null,serial_number:null,size_bytes:null,interface_type:null});}
  }
  return out;
}

async function discoverDevices(smartctlPath) {
  // Windows smartctl can require an open probe to enumerate USB/SATA/NVMe
  // devices. Try scan-open first, then regular scan as a fallback.
  const candidates = [
    ['--scan-open', '--json'],
    ['--scan', '--json']
  ];
  for (const args of candidates) {
    const r = await run(smartctlPath, args);
    const text = r.stdout || '';
    try {
      const parsed = JSON.parse(text);
      const devices = Array.isArray(parsed.devices) ? parsed.devices : [];
      if (devices.length) {
        return devices.map(d => ({name:d.name, type:d.type}));
      }
    } catch {}
  }
  return [];
}
function getAttr(table,id){const row=(table||[]).find(a=>a.id===id); return row?row.raw?.value:null;}
function healthScore({health,reallocated,pending,uncorrectable,temp,wear}) {
  if(health==='FAILED') return 0;
  let s=100;
  if((reallocated??0)>0) s-=Math.min(35,10+(reallocated??0));
  if((pending??0)>0) s-=Math.min(35,15+(pending??0));
  if((uncorrectable??0)>0) s-=40;
  if(typeof temp==='number' && temp>=60) s-=Math.min(25,5+Math.floor(temp-60));
  if(typeof wear==='number') s=Math.min(s, Math.max(0,wear));
  return Math.max(0,Math.min(100,Math.round(s)));
}
async function scanDevice(smartctlPath, devicePath, devType) {
  const args=['-a','--json=c',devicePath]; if(devType) args.push('-d',devType);
  const out=(await run(smartctlPath,args)).stdout; let data;
  try { data=JSON.parse(out); } catch { console.error(`Could not parse ${devicePath}`); return null; }
  const isNvme=!!data.nvme_smart_health_information_log;
  let health='UNKNOWN', reallocated=null,pending=null,uncorrectable=null,wear=null;
  if(data.smart_status && typeof data.smart_status.passed==='boolean') health=data.smart_status.passed?'PASSED':'FAILED';
  if(isNvme){
    const n=data.nvme_smart_health_information_log;
    wear=n.percentage_used!==undefined?Math.max(0,100-n.percentage_used):null;
    if(n.critical_warning) health='WARNING';
  } else if(data.ata_smart_attributes){
    const t=data.ata_smart_attributes.table;
    reallocated=getAttr(t,5); pending=getAttr(t,197); uncorrectable=getAttr(t,198);
    const w=getAttr(t,177) ?? getAttr(t,173); if(w!==null) wear=Math.max(0,Math.min(100,100-Number(w)));
    if(health==='PASSED' && ((reallocated??0)>0||(pending??0)>0||(uncorrectable??0)>0)) health='WARNING';
  }
  const temp=data.temperature?.current ?? data.nvme_smart_health_information_log?.temperature ?? null;
  const score=healthScore({health,reallocated,pending,uncorrectable,temp,wear});
  const selfTest=data.ata_smart_data?.self_test?.status?.string || data.nvme_self_test_log?.current_selftest_operation?.string || null;
  return {
    hostname:os.hostname(), device_path:devicePath, model:data.model_name||data.model_family||null,
    serial_number:data.serial_number||null, interface_type:data.device?.protocol||null,
    drive_type:isNvme?'SSD':(data.rotation_rate===0?'SSD':(data.rotation_rate?'HDD':null)),
    health_status: score<50?'FAILED':(score<80?'WARNING':health),
    health_score:score, temperature_c:temp,
    power_on_hours:data.power_on_time?.hours||null,
    reallocated_sector_count:reallocated,pending_sector_count:pending,
    uncorrectable_sector_count:uncorrectable,wear_level_percent:wear,
    self_test_status:selfTest, smart_enabled:data.smart_support?.enabled ?? null, raw:data
  };
}
async function report(config,payload){
  const res=await fetch(config.serverUrl,{method:'POST',
    headers:{'Content-Type':'application/json','X-API-Key':config.apiKey},
    body:JSON.stringify(payload)});
  const raw=await res.text();
  let body={};
  try { body=JSON.parse(raw); } catch { body={raw:raw.slice(0,500)}; }
  if(!res.ok) {
    throw new Error(`Server ${res.status} at ${config.serverUrl}: ${JSON.stringify(body)}`);
  }
  console.log(`Reported ${payload.device_path} -> scan ${body.scan_id ?? 'ok'}`);
}
function partitionBelongsToDevice(partition, devicePath){
  const p=String(partition?.device_path||'').replace(/\\/g,'/').toLowerCase();
  const parent=String(partition?.parent_device_path||'').replace(/\\/g,'/').toLowerCase();
  const d=String(devicePath||'').replace(/\\/g,'/').toLowerCase();
  if(process.platform==='win32'){
    const m=d.match(/physicaldrive(\d+)/i);
    if(m && partition?.disk_number!=null) return String(partition.disk_number)===m[1];
  }
  if(parent && parent===d) return true;
  if(p && p===d) return true;
  if(p && d && p.startsWith(d)){
    const rest=p.slice(d.length);
    return rest.length>0 && (/^\d/.test(rest)||/^p\d/.test(rest)||/^s\d/.test(rest));
  }
  return false;
}

async function scanOnce(config, smartctlPath){
  const partitions=await collectPartitions();
  const hardware=await collectHardware();
  let targets=config.devices&&config.devices[0]!=='auto'
    ? config.devices.map(d=>({name:typeof d==='string'?d:d.name,type:d.type||null}))
    : await discoverDevices(smartctlPath);
  const osStorage=await discoverOsStorage();
  if(!targets.length) targets=osStorage.map(d=>({name:d.name,type:null}));
  if(!targets.length) console.warn('No storage devices discovered; reporting hardware inventory only.');
  const sentHosts=new Set();
  const reportedPaths=new Set();
  for(const t of targets){
    const osInfo=osStorage.find(x=>x.name===t.name);
    const p=await scanDevice(smartctlPath,t.name,t.type);
    const devicePartitions=partitions.filter(x=>partitionBelongsToDevice(x, t.name));
    if(p){
      if(osInfo){p.model=p.model||osInfo.model;p.serial_number=p.serial_number||osInfo.serial_number;p.interface_type=p.interface_type||osInfo.interface_type;p.size_bytes=osInfo.size_bytes||null;}
      p.partitions=devicePartitions; p.hardware=[...hardware,{category:'storage',identifier:`smart:${p.device_path}`,name:p.model||p.device_path,status:p.health_status==='FAILED'?'FAILED':'ONLINE',details:{device_path:p.device_path,model:p.model,serial_number:p.serial_number,drive_type:p.drive_type,health_status:p.health_status,health_score:p.health_score,size_bytes:p.size_bytes}}]; sentHosts.add(p.hostname);reportedPaths.add(p.device_path);
      try { await report(config,p); } catch(e) { console.error(e.message); }
    } else if(osInfo){
      const status=String(osInfo.os_health||'UNKNOWN').toUpperCase();
      const hp=status==='HEALTHY'||status==='ONLINE'?'PASSED':status==='WARNING'?'WARNING':status==='UNHEALTHY'||status==='CRITICAL'?'FAILED':'UNKNOWN';
      const devicePartitions=partitions.filter(x=>partitionBelongsToDevice(x, osInfo.name));
      const p2={hostname:os.hostname(),device_path:osInfo.name,model:osInfo.model,serial_number:osInfo.serial_number,interface_type:osInfo.interface_type,drive_type:'STORAGE',health_status:hp,health_score:hp==='PASSED'?100:null,temperature_c:null,power_on_hours:null,reallocated_sector_count:null,pending_sector_count:null,uncorrectable_sector_count:null,wear_level_percent:null,self_test_status:null,smart_enabled:null,partitions:devicePartitions,hardware:[...hardware,{category:'storage',identifier:`os:${osInfo.name}`,name:osInfo.model||osInfo.name,status:hp==='FAILED'?'FAILED':'ONLINE',details:osInfo}]};
      sentHosts.add(p2.hostname);reportedPaths.add(p2.device_path);try{await report(config,p2);}catch(e){console.error(e.message);}
    }
  }
  // Do not report a synthetic __INVENTORY__ storage device. Real OS-only
  // disks are already reported individually in the fallback above.
  console.log(`[realtime] ${new Date().toISOString()} · SMART devices: ${targets.length} · OS storage: ${osStorage.length} · partitions: ${partitions.length} · hardware: ${hardware.length}`);
}
async function main(){
  const config=loadConfig(), smartctlPath=config.smartctlPath||'smartctl';
  const once=process.argv.includes('--once');
  const interval=Math.max(1000,Number(config.scanIntervalMs||5000));
  do {
    try { await scanOnce(config,smartctlPath); } catch(e) { console.error('Realtime scan failed:',e.message); }
    if(config.once || once) break;
    await new Promise(r=>setTimeout(r,interval));
  } while(true);
}
main().catch(e=>{console.error('Agent failed:',e);process.exit(1);});
