-- =============================================
-- ROSports.app — Migración 001: Schema inicial
-- Compatible con Supabase / PostgreSQL 15+
-- =============================================

-- Extensiones requeridas
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============ CIUDADES ============
CREATE TABLE cities (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,
    country     TEXT NOT NULL DEFAULT 'Colombia',
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ DEPORTES ============
CREATE TABLE sports (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT UNIQUE NOT NULL,
    icon_url    TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ USUARIOS ============
-- Extiende auth.users de Supabase
CREATE TABLE profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email           TEXT UNIQUE NOT NULL,
    name            TEXT NOT NULL,
    phone           TEXT,
    avatar_url      TEXT,
    level           TEXT CHECK (level IN ('beginner','intermediate','advanced')),
    points          INT DEFAULT 0,
    role            TEXT CHECK (role IN ('player','court_admin','super_admin')) DEFAULT 'player',
    stats           JSONB DEFAULT '{}',
    preferences     JSONB DEFAULT '{}',
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ AMONESTACIONES ============
CREATE TABLE cards (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type        TEXT CHECK (type IN ('yellow','red')) NOT NULL,
    reason      TEXT,
    match_id    UUID,   -- FK a matches se agrega después
    issued_by   UUID REFERENCES profiles(id),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ SEDES (VENUES) ============
CREATE TABLE venues (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    owner_user_id   UUID REFERENCES profiles(id),
    address         TEXT,
    city_id         UUID REFERENCES cities(id),
    lat             DOUBLE PRECISION,
    lng             DOUBLE PRECISION,
    contact_info    JSONB DEFAULT '{}',
    is_active       BOOLEAN DEFAULT TRUE,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ CANCHAS ============
CREATE TABLE courts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venue_id        UUID REFERENCES venues(id) ON DELETE CASCADE,
    sport_id        UUID REFERENCES sports(id),
    name            TEXT,
    surface_type    TEXT,
    lights          BOOLEAN DEFAULT FALSE,
    price_per_hour  DECIMAL(12,2) NOT NULL,
    attributes      JSONB DEFAULT '{}',
    is_active       BOOLEAN DEFAULT TRUE,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ POLÍTICAS DE CANCELACIÓN ============
CREATE TABLE court_policies (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    court_id                UUID REFERENCES courts(id) ON DELETE CASCADE,
    cancel_hours_before     INT NOT NULL DEFAULT 24,
    penalty_percentage      DECIMAL(5,2) DEFAULT 0,
    no_show_fee             DECIMAL(12,2) DEFAULT 0,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============ SLOTS DE DISPONIBILIDAD ============
CREATE TABLE availability_slots (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    court_id        UUID REFERENCES courts(id) ON DELETE CASCADE,
    start_time      TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time        TIMESTAMP WITH TIME ZONE NOT NULL,
    status          TEXT CHECK (status IN ('available','booked','blocked')) DEFAULT 'available',
    price_override  DECIMAL(12,2),
    blocked_reason  TEXT,
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_slots_court_time ON availability_slots(court_id, start_time);
CREATE INDEX idx_slots_status ON availability_slots(status);
