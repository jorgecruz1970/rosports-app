@echo off
chcp 65001 > nul
set REPO=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\rosports-app
set LOG=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\git_init.log

cd /d "%REPO%"

echo [1] Init git repo >> "%LOG%" 2>&1
git init >> "%LOG%" 2>&1

echo [2] Set branch main >> "%LOG%" 2>&1
git branch -M main >> "%LOG%" 2>&1

echo [3] Stage all files >> "%LOG%" 2>&1
git add . >> "%LOG%" 2>&1

echo [4] First commit >> "%LOG%" 2>&1
git commit -m "feat: initial project scaffold - ROSports MVP" >> "%LOG%" 2>&1

echo [5] Git log >> "%LOG%" 2>&1
git log --oneline >> "%LOG%" 2>&1

echo [6] Git status >> "%LOG%" 2>&1
git status >> "%LOG%" 2>&1

echo DONE >> "%LOG%"
type "%LOG%"
