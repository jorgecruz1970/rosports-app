-- =============================================
-- ROSports.app — Migración 008: Ratings de canchas
-- =============================================

CREATE TABLE court_ratings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    court_id    UUID REFERENCES courts(id) ON DELETE CASCADE,
    user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reservation_id UUID REFERENCES reservations(id),
    rating      INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Un usuario solo puede calificar una vez por reserva
    CONSTRAINT unique_user_reservation_rating UNIQUE (user_id, reservation_id)
);

CREATE INDEX idx_court_ratings_court ON court_ratings(court_id);

-- RLS
ALTER TABLE court_ratings ENABLE ROW LEVEL SECURITY;

-- Cualquier autenticado puede ver ratings
CREATE POLICY "ratings_select" ON court_ratings
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- Solo puedes crear tu propio rating
CREATE POLICY "ratings_insert" ON court_ratings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Permisos
GRANT ALL ON public.court_ratings TO authenticated;
