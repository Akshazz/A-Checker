@echo off
setlocal
cd /d "%~dp0"
title A-TestChecker - Ready to Use
echo.
echo ==========================================
echo        A-TestChecker Storage Monitor
echo ==========================================
echo.
if exist "agent\agent.js" (
  echo Starting storage agent...
  where node >nul 2>&1
  if %errorlevel%==0 (
    start "A-TestChecker Agent" /min cmd /c "cd /d "%~dp0agent" && node agent.js"
  ) else (
    echo Node.js is not installed. The dashboard can still be used if PHP is configured.
  )
)
if exist "C:\xampp\xampp-control.exe" (
  echo Starting XAMPP...
  start "" "C:\xampp\xampp-control.exe"
)
timeout /t 2 >nul
start "" "http://localhost/A-Checker/"
echo.
echo A-TestChecker started.
echo.
pause
