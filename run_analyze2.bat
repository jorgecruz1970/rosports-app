@echo off
chcp 65001 > nul
set DART=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\extract-sdk\flutter\bin\dart.bat
set MOBILE=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\rosports-app\mobile
set LOG=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\analyze2.log

cd /d "%MOBILE%"
"%DART%" analyze lib\ > "%LOG%" 2>&1
echo EXIT=%ERRORLEVEL% >> "%LOG%"
