-- =============================================
-- ROSports.app — Migración 004: Row Level Security
-- Compatible con Supabase PostgreSQL 15+
-- =============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE venues             ENABLE ROW LEVEL SECURITY;
ALTER TABLE courts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE court_policies     ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches            ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_signups      ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications      ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tokens        ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards              ENABLE ROW LEVEL SECURITY;

-- ============ PROFILES ============
CREATE POLICY "profiles_select_all" ON profiles
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "profiles_insert_own" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- ============ CITIES / SPORTS — lectura pública ============
-- (no tienen RLS, son tablas de referencia — acceso via service role en seed)

-- ============ VENUES ============
CREATE POLICY "venues_select_active" ON venues
    FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY "venues_insert_admin" ON venues
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

CREATE POLICY "venues_update_owner" ON venues
    FOR UPDATE USING (
        owner_user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- ============ COURTS ============
CREATE POLICY "courts_select_active" ON courts
    FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = TRUE);

CREATE POLICY "courts_insert_admin" ON courts
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

CREATE POLICY "courts_update_admin" ON courts
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

-- ============ COURT POLICIES ============
CREATE POLICY "court_policies_select" ON court_policies
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "court_policies_manage_admin" ON court_policies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

-- ============ AVAILABILITY SLOTS ============
CREATE POLICY "slots_select" ON availability_slots
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "slots_manage_admin" ON availability_slots
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

-- ============ RESERVATIONS ============
CREATE POLICY "reservations_select_own" ON reservations
    FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM courts c
            JOIN venues v ON c.venue_id = v.id
            WHERE c.id = reservations.court_id
            AND (
                v.owner_user_id = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM profiles
                    WHERE id = auth.uid() AND role = 'super_admin'
                )
            )
        )
    );

CREATE POLICY "reservations_insert_own" ON reservations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "reservations_update_own" ON reservations
    FOR UPDATE USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role IN ('court_admin', 'super_admin')
        )
    );

-- ============ PAYMENTS ============
CREATE POLICY "payments_select_own" ON payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "payments_insert_own" ON payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============ MATCHES ============
CREATE POLICY "matches_select_public" ON matches
    FOR SELECT USING (
        auth.uid() IS NOT NULL
        AND (is_public = TRUE OR auth.uid() = creator_user_id)
    );

CREATE POLICY "matches_insert_auth" ON matches
    FOR INSERT WITH CHECK (auth.uid() = creator_user_id);

CREATE POLICY "matches_update_creator" ON matches
    FOR UPDATE USING (auth.uid() = creator_user_id);

-- ============ MATCH SIGNUPS ============
CREATE POLICY "signups_select" ON match_signups
    FOR SELECT USING (
        auth.uid() = user_id
        OR EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = match_signups.match_id
            AND m.creator_user_id = auth.uid()
        )
    );

CREATE POLICY "signups_insert_own" ON match_signups
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "signups_update_own" ON match_signups
    FOR UPDATE USING (auth.uid() = user_id);

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

-- ============ CARDS ============
CREATE POLICY "cards_select_own" ON cards
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "cards_insert_admin" ON cards
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role IN ('court_admin', 'super_admin')
        )
    );

-- =============================================
-- TRIGGER: Auto-crear profile al registrarse
-- Cuando un usuario se registra en auth.users,
-- se crea automáticamente su fila en profiles
-- =============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'name',
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    ),
    'player'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
