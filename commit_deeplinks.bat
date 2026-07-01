@echo off
chcp 65001 > nul
set REPO=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\rosports-app
set LOG=C:\Users\jorge\Documents\Personal\PY Familiar\App Gestión Reservas\PY-Kiro App\commit_deeplinks.log
cd /d "%REPO%"

git add . >> "%LOG%" 2>&1
git commit -m "feat(auth): deep links OAuth + PKCE flow + Supabase auth config

- Android: intent-filter for app.rosports.mobile:// scheme (login-callback, reset-password)
- iOS: CFBundleURLSchemes in Info.plist for app.rosports.mobile://
- AppDelegate.swift: URL open handler for OAuth deep link
- Supabase.initialize: PKCE auth flow (more secure for mobile)
- RLS migration 004: fixed auth.role() -> auth.uid() IS NOT NULL (Supabase v2)
- Added trigger on_auth_user_created in auth schema (verified)
- infra/supabase-auth-config.md: redirect URLs setup guide" >> "%LOG%" 2>&1

git push origin feature/ROSP-sprint1-auth-supabase >> "%LOG%" 2>&1
echo DONE >> "%LOG%"
type "%LOG%"
