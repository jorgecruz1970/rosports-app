@echo off
chcp 65001 > nul
set REPO=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\rosports-app
set LOG=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\push_result.log

cd /d "%REPO%"

echo [1] Agregar remote origin >> "%LOG%" 2>&1
git remote add origin https://github.com/jorgecruz1970/rosports-app.git >> "%LOG%" 2>&1

echo [2] Verificar remote >> "%LOG%" 2>&1
git remote -v >> "%LOG%" 2>&1

echo [3] Push a main >> "%LOG%" 2>&1
git push -u origin main >> "%LOG%" 2>&1

echo PUSH_EXIT=%ERRORLEVEL% >> "%LOG%"
type "%LOG%"
