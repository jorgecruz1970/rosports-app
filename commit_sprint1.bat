@echo off
chcp 65001 > nul
set REPO=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\rosports-app
set LOG=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\commit_sprint1.log
cd /d "%REPO%"

echo [1] Checkout feature branch >> "%LOG%" 2>&1
git checkout -b feature/ROSP-sprint1-auth-supabase >> "%LOG%" 2>&1

echo [2] Stage all >> "%LOG%" 2>&1
git add . >> "%LOG%" 2>&1

echo [3] Commit >> "%LOG%" 2>&1
git commit -m "feat(sprint1): Supabase auth + Clean Architecture + Sprint 1 foundation

- Connect Supabase (ROSP-30): project jbhcxsortawvezgqbubn, South America region
- Auth implementation (ROSP-01, ROSP-02, ROSP-03): register/login/Google/Apple/reset
- Clean Architecture layers: domain entities, repository contracts, data impl
- RoAuthException to avoid collision with supabase_flutter AuthException  
- ProfileNotifier + ProfileProvider connected to Supabase profiles table
- Router redirect guard: unauthenticated users redirected to login
- UserModel + ProfileModel data layer
- AppConstants: table names, bucket names, commission rate
- AppException hierarchy: RoAuthException, NetworkException, ValidationException
- Sentry initialized (DSN configurable via env)
- All screens connected to real providers (auth, profile)
- 0 errors, 0 code warnings in dart analyze" >> "%LOG%" 2>&1

echo [4] Push >> "%LOG%" 2>&1
git push -u origin feature/ROSP-sprint1-auth-supabase >> "%LOG%" 2>&1

echo [5] Log >> "%LOG%" 2>&1
git log --oneline -5 >> "%LOG%" 2>&1

echo DONE >> "%LOG%"
type "%LOG%"
