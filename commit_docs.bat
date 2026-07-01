@echo off
chcp 65001 > nul
set REPO=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\rosports-app
set LOG=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\commit_docs.log

cd /d "%REPO%"

echo [1] Checkout develop >> "%LOG%" 2>&1
git checkout develop >> "%LOG%" 2>&1

echo [2] Stage docs >> "%LOG%" 2>&1
git add docs/github-setup.md >> "%LOG%" 2>&1

echo [3] Commit >> "%LOG%" 2>&1
git commit -m "docs: add GitHub setup guide - secrets, branches and CI/CD" >> "%LOG%" 2>&1

echo [4] Push >> "%LOG%" 2>&1
git push origin develop >> "%LOG%" 2>&1

echo [5] Status >> "%LOG%" 2>&1
git log --oneline -5 >> "%LOG%" 2>&1

echo DONE >> "%LOG%"
type "%LOG%"
