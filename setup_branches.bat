@echo off
chcp 65001 > nul
set REPO=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\rosports-app
set LOG=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\branches_result.log

cd /d "%REPO%"

echo [1] Crear rama develop >> "%LOG%" 2>&1
git checkout -b develop >> "%LOG%" 2>&1
git push -u origin develop >> "%LOG%" 2>&1

echo [2] Crear rama feature/sprint-1-foundation >> "%LOG%" 2>&1
git checkout -b feature/sprint-1-foundation >> "%LOG%" 2>&1
git push -u origin feature/sprint-1-foundation >> "%LOG%" 2>&1

echo [3] Volver a develop >> "%LOG%" 2>&1
git checkout develop >> "%LOG%" 2>&1

echo [4] Estado final >> "%LOG%" 2>&1
git branch -a >> "%LOG%" 2>&1

echo DONE >> "%LOG%"
type "%LOG%"
