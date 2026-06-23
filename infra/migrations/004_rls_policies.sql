-- =============================================
-- ROSports.app — Migración 004: Row Level Security
-- Todas las tablas protegidas por defecto
-- =============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE venues            ENABLE ROW LEVEL SECURITY;
ALTER TABLE courts            ENABLE ROW LEVEL SECURITY;
ALTER TABLE court_policies    ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations      ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches           ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_signups     ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications     ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tokens       ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards             ENABLE ROW LEVEL SECURITY;

-- ============ PROFILES ============
-- Cualquier usuario autenticado puede ver perfiles públicos
CREATE POLICY "profiles_select_all" ON profiles
    FOR SELECT USING (auth.role() = 'authenticated');

-- Solo el propio usuario puede editar su perfil
CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- ============ VENUES Y COURTS — lectura pública autenticada ============
CREATE POLICY "venues_select_active" ON venues
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = TRUE);

CREATE POLICY "courts_select_active" ON courts
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = TRUE);

-- Solo court_admin o super_admin pueden crear/editar venues
CREATE POLICY "venues_insert_admin" ON venues
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

CREATE POLICY "courts_insert_admin" ON courts
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

-- ============ SLOTS — lectura pública autenticada ============
CREATE POLICY "slots_select" ON availability_slots
    FOR SELECT USING (auth.role() = 'authenticated');

-- Solo admin puede crear/modificar slots
CREATE POLICY "slots_insert_admin" ON availability_slots
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

-- ============ RESERVATIONS ============
-- Jugador solo ve sus propias reservas; admin ve las de su cancha
CREATE POLICY "reservations_select_own" ON reservations
    FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM courts c
            JOIN venues v ON c.venue_id = v.id
            JOIN profiles p ON p.id = auth.uid()
            WHERE c.id = reservations.court_id
            AND (v.owner_user_id = auth.uid() OR p.role = 'super_admin')
        )
    );

-- Solo el propio jugador puede crear reservas
CREATE POLICY "reservations_insert_own" ON reservations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============ PAYMENTS ============
-- Solo el propio usuario ve sus pagos
CREATE POLICY "payments_select_own" ON payments
    FOR SELECT USING (auth.uid() = user_id);

-- ============ MATCHES — lectura pública para partidos abiertos ============
CREATE POLICY "matches_select_public" ON matches
    FOR SELECT USING (
        auth.role() = 'authenticated'
        AND (is_public = TRUE OR auth.uid() = creator_user_id)
    );

-- Solo usuarios autenticados pueden crear partidos
CREATE POLICY "matches_insert_auth" ON matches
    FOR INSERT WITH CHECK (auth.uid() = creator_user_id);

-- ============ MATCH SIGNUPS ============
CREATE POLICY "signups_select_own" ON match_signups
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "signups_insert_own" ON match_signups
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============ NOTIFICATIONS ============
CREATE POLICY "notifications_select_own" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

-- ============ USER TOKENS ============
CREATE POLICY "tokens_select_own" ON user_tokens
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "tokens_insert_own" ON user_tokens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tokens_update_own" ON user_tokens
    FOR UPDATE USING (auth.uid() = user_id);
