-- =============================================
-- ROSports — Limpiar signups inconsistentes y recalcular spots_taken
-- Ejecutar en Supabase SQL Editor
-- =============================================

-- Ver estado actual de signups
SELECT ms.match_id, ms.user_id, ms.status, p.email, p.name
FROM match_signups ms
JOIN profiles p ON ms.user_id = p.id
ORDER BY ms.match_id, ms.created_at;

-- Recalcular spots_taken en todos los matches basándose en signups reales
UPDATE matches m
SET spots_taken = (
  SELECT COUNT(*)
  FROM match_signups ms
  WHERE ms.match_id = m.id
    AND ms.status = 'signed'
);

-- Actualizar status de matches basándose en spots recalculados
UPDATE matches
SET status = CASE
  WHEN spots_taken >= spots_total THEN 'full'
  ELSE 'open'
END
WHERE status IN ('open', 'full');

-- Verificar resultado
SELECT id, spots_total, spots_taken, status
FROM matches
ORDER BY created_at DESC;
