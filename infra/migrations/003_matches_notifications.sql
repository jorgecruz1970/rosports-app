-- =============================================
-- ROSports.app — Migración 003: Partidos y Notificaciones
-- =============================================

-- ============ PARTIDOS ABIERTOS ============
CREATE TABLE matches (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_user_id     UUID REFERENCES profiles(id),
    court_id            UUID REFERENCES courts(id),
    reservation_id      UUID REFERENCES reservations(id),
    sport_id            UUID REFERENCES sports(id),
    start_time          TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time            TIMESTAMP WITH TIME ZONE NOT NULL,
    spots_total         INT NOT NULL CHECK (spots_total > 0),
    spots_taken         INT DEFAULT 0 CHECK (spots_taken >= 0),
    price_per_player    DECIMAL(12,2) NOT NULL,
    level_min           TEXT CHECK (level_min IN ('beginner','intermediate','advanced')),
    level_max           TEXT CHECK (level_max IN ('beginner','intermediate','advanced')),
    is_public           BOOLEAN DEFAULT TRUE,
    signup_policy       TEXT CHECK (signup_policy IN ('auto','manual')) DEFAULT 'auto',
    status              TEXT CHECK (status IN ('open','full','cancelled','completed')) DEFAULT 'open',
    cancelled_at        TIMESTAMP WITH TIME ZONE,
    deleted_at          TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT spots_not_exceeded CHECK (spots_taken <= spots_total)
);

CREATE INDEX idx_matches_sport ON matches(sport_id);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_start ON matches(start_time);

-- ============ INSCRIPCIONES A PARTIDOS ============
CREATE TABLE match_signups (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id    UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id     UUID REFERENCES profiles(id),
    payment_id  UUID REFERENCES payments(id),
    status      TEXT CHECK (status IN ('signed','waiting','cancelled')) DEFAULT 'signed',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT unique_match_user UNIQUE (match_id, user_id)
);

-- FK de cards a matches (ahora que matches existe)
ALTER TABLE cards
    ADD CONSTRAINT fk_card_match
    FOREIGN KEY (match_id) REFERENCES matches(id);

-- FK de payments a matches
ALTER TABLE payments
    ADD CONSTRAINT fk_payment_match
    FOREIGN KEY (match_id) REFERENCES matches(id);

-- ============ FCM TOKENS (Push) ============
CREATE TABLE user_tokens (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    platform    TEXT CHECK (platform IN ('android','ios')) NOT NULL,
    device_id   TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT unique_device_token UNIQUE (user_id, device_id)
);

-- ============ NOTIFICACIONES ============
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type        TEXT CHECK (type IN ('push','email','in-app')) NOT NULL,
    title       TEXT,
    body        TEXT,
    payload     JSONB DEFAULT '{}',
    sent_at     TIMESTAMP WITH TIME ZONE,
    read_at     TIMESTAMP WITH TIME ZONE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, read_at);
