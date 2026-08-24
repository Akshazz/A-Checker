# Storage Health Monitor — automated setup for Windows (XAMPP).
# Copies the web app into htdocs, generates a random API key, imports the
# database, wires up the agent config, and installs agent dependencies.
# You do not need to move or edit any files by hand — just run this script.
#
# Run from PowerShell:  .\setup.ps1
# (If scripts are blocked, run once:  Set-ExecutionPolicy -Scope Process Bypass)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Storage Health Monitor - Setup ===" -ForegroundColor Cyan
Write-Host ""

# --- 1. Find/confirm htdocs ---
$DefaultHtdocs = $null
foreach ($candidate in @("C:\xampp\htdocs", "C:\XAMPP\htdocs")) {
    if (Test-Path $candidate) { $DefaultHtdocs = $candidate; break }
}

if ($DefaultHtdocs) {
    $answer = Read-Host "XAMPP htdocs folder found at $DefaultHtdocs - use it? [Y/n]"
    if ($answer -match '^[Nn]') {
        $Htdocs = Read-Host "Enter full path to htdocs"
    } else {
        $Htdocs = $DefaultHtdocs
    }
} else {
    $Htdocs = Read-Host "Could not auto-detect htdocs. Enter full path to it"
}

if (-not (Test-Path $Htdocs)) {
    Write-Host "Error: '$Htdocs' does not exist. Install/start XAMPP first, then re-run this script." -ForegroundColor Red
    exit 1
}

$Target = Join-Path $Htdocs "storage-health-monitor"
Write-Host "Installing app to: $Target"
New-Item -ItemType Directory -Force -Path $Target | Out-Null
Copy-Item -Path (Join-Path $ScriptDir "php\*") -Destination $Target -Recurse -Force
New-Item -ItemType Directory -Force -Path (Join-Path $Target "agent") | Out-Null
Copy-Item -Path (Join-Path $ScriptDir "agent\*") -Destination (Join-Path $Target "agent") -Recurse -Force

# --- 2. Generate a random API key ---
$bytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$ApiKey = ([BitConverter]::ToString($bytes) -replace '-', '').ToLower()
Write-Host "Generated API key."

# --- 3. Find mysql.exe ---
$MysqlBin = $null
foreach ($candidate in @("C:\xampp\mysql\bin\mysql.exe", "C:\XAMPP\mysql\bin\mysql.exe")) {
    if (Test-Path $candidate) { $MysqlBin = $candidate; break }
}
if (-not $MysqlBin) {
    $MysqlBin = Read-Host "Could not find mysql.exe. Enter its full path"
}

$DbUser = Read-Host "MySQL username [root]"
if ([string]::IsNullOrWhiteSpace($DbUser)) { $DbUser = "root" }
$DbPassSecure = Read-Host "MySQL password [blank]" -AsSecureString
$DbPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($DbPassSecure))

# --- 4. Import schema with the generated key baked in ---
$SchemaContent = Get-Content (Join-Path $ScriptDir "database\schema.sql") -Raw
$SchemaContent = $SchemaContent -replace '__API_KEY__', $ApiKey
$TmpSql = [System.IO.Path]::GetTempFileName()
Set-Content -Path $TmpSql -Value $SchemaContent -Encoding UTF8

Write-Host "Importing database..."
if ([string]::IsNullOrEmpty($DbPass)) {
    Get-Content $TmpSql | & $MysqlBin -u $DbUser
} else {
    Get-Content $TmpSql | & $MysqlBin -u $DbUser "-p$DbPass"
}
Remove-Item $TmpSql

# --- 5. Write DB credentials into the deployed config.php ---
$ConfigFile = Join-Path $Target "config.php"
$ConfigContent = Get-Content $ConfigFile -Raw
$ConfigContent = $ConfigContent -replace "define\('DB_USER', 'root'\);", "define('DB_USER', '$DbUser');"
$ConfigContent = $ConfigContent -replace "define\('DB_PASS', ''\);", "define('DB_PASS', '$DbPass');"
Set-Content -Path $ConfigFile -Value $ConfigContent -Encoding UTF8

# --- 6. Generate agent config.json automatically ---
$AgentDir = Join-Path $Target "agent"
$AgentConfig = @"
{
  "serverUrl": "http://localhost/storage-health-monitor/api/report.php",
  "apiKey": "$ApiKey",
  "smartctlPath": "smartctl",
  "devices": ["auto"]
}
"@
Set-Content -Path (Join-Path $AgentDir "config.json") -Value $AgentConfig -Encoding UTF8
Write-Host "Agent config written to agent\config.json"

# --- 7. Install agent dependencies ---
if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "Installing agent dependencies..."
    Push-Location $AgentDir
    npm install --silent
    Pop-Location
} else {
    Write-Host "Note: Node.js/npm not found. Install Node.js, then run: cd agent; npm install" -ForegroundColor Yellow
}

# --- 8. Check for smartmontools ---
if (-not (Get-Command smartctl -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "Note: 'smartctl' was not found on your PATH. Install smartmontools from" -ForegroundColor Yellow
    Write-Host "smartmontools.org and add it to PATH to enable scanning." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Setup complete ===" -ForegroundColor Green
Write-Host "Dashboard:  http://localhost/storage-health-monitor/"
Write-Host "Run a scan: cd agent; npm run scan   (as Administrator)"
