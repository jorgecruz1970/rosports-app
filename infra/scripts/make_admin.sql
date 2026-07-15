-- =============================================
-- ROSports — Hacer un usuario admin
-- Ejecutar en Supabase SQL Editor
-- =============================================

-- Opción 1: Hacer admin por email
UPDATE profiles
SET role = 'court_admin'
WHERE email = 'TU_EMAIL_AQUI';

-- Opción 2: Hacer super_admin por email
-- UPDATE profiles
-- SET role = 'super_admin'
-- WHERE email = 'TU_EMAIL_AQUI';

-- Verificar:
-- SELECT id, email, name, role FROM profiles WHERE email = 'TU_EMAIL_AQUI';
