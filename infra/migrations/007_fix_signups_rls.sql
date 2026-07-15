-- =============================================
-- ROSports.app — Migración 007: Fix RLS match_signups
-- Permitir que cualquier usuario inscrito en un partido vea los demás inscritos
-- =============================================

-- Eliminar la policy restrictiva anterior
DROP POLICY IF EXISTS "signups_select" ON match_signups;

-- Nueva policy: puedes ver signups de un partido si:
-- 1. Eres tú mismo (tu propio signup)
-- 2. Eres el creador del partido
-- 3. Estás inscrito en el mismo partido (para ver a los demás jugadores)
CREATE POLICY "signups_select_v2" ON match_signups
    FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = match_signups.match_id
            AND m.creator_user_id = auth.uid()
        )
        OR EXISTS (
            SELECT 1 FROM match_signups ms2
            WHERE ms2.match_id = match_signups.match_id
            AND ms2.user_id = auth.uid()
            AND ms2.status = 'signed'
        )
    );

-- También permitir que cualquier autenticado vea signups de partidos públicos
-- (para ver cuántas plazas quedan antes de unirse)
DROP POLICY IF EXISTS "signups_select_v2" ON match_signups;

CREATE POLICY "signups_select_v3" ON match_signups
    FOR SELECT USING (
        auth.uid() IS NOT NULL
        AND (
            -- Ver tus propios signups siempre
            auth.uid() = user_id
            -- Ver signups de partidos públicos (para ver jugadores inscritos)
            OR EXISTS (
                SELECT 1 FROM matches m
                WHERE m.id = match_signups.match_id
                AND (m.is_public = TRUE OR m.creator_user_id = auth.uid())
            )
        )
    );
