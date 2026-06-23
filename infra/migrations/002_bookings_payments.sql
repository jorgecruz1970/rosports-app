-- =============================================
-- ROSports.app — Migración 002: Reservas y Pagos
-- =============================================

-- ============ RESERVAS ============
CREATE TABLE reservations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    court_id        UUID REFERENCES courts(id),
    user_id         UUID REFERENCES profiles(id),
    slot_id         UUID REFERENCES availability_slots(id),
    start_time      TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time        TIMESTAMP WITH TIME ZONE NOT NULL,
    status          TEXT CHECK (status IN ('pending','confirmed','cancelled','completed','no_show'))
                    DEFAULT 'pending',
    payment_id      UUID,  -- FK a payments, se agrega después
    total_amount    DECIMAL(12,2) NOT NULL,
    commission      DECIMAL(12,2) NOT NULL,  -- 10% Año 1
    net_amount      DECIMAL(12,2) NOT NULL,  -- total - commission
    currency        TEXT DEFAULT 'COP',
    cancelled_at    TIMESTAMP WITH TIME ZONE,
    cancel_reason   TEXT,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Evitar doble booking: una cancha no puede tener dos reservas en el mismo slot
    CONSTRAINT unique_court_slot UNIQUE (court_id, start_time)
);

CREATE INDEX idx_reservations_user ON reservations(user_id);
CREATE INDEX idx_reservations_court ON reservations(court_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_start ON reservations(start_time);

-- ============ PAGOS ============
CREATE TABLE payments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reservation_id      UUID REFERENCES reservations(id),
    match_id            UUID,  -- FK a matches, se agrega después
    user_id             UUID REFERENCES profiles(id),
    provider            TEXT CHECK (provider IN ('payu','mercadopago','stripe')) NOT NULL,
    provider_payment_id TEXT,
    amount              DECIMAL(12,2) NOT NULL,
    currency            TEXT DEFAULT 'COP',
    status              TEXT CHECK (status IN ('initiated','authorized','captured','refunded','failed'))
                        DEFAULT 'initiated',
    raw_response        JSONB DEFAULT '{}',
    refunded_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_payments_reservation ON payments(reservation_id);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);

-- Actualizar FK de reservations a payments
ALTER TABLE reservations
    ADD CONSTRAINT fk_reservation_payment
    FOREIGN KEY (payment_id) REFERENCES payments(id);
