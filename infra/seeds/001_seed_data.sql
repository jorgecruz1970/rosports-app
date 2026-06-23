-- =============================================
-- ROSports.app — Seed inicial para desarrollo
-- Ciudad: Bogotá | Deportes: Fútbol 5 y 7
-- =============================================

-- Ciudades
INSERT INTO cities (id, name, country) VALUES
    ('11111111-0000-0000-0000-000000000001', 'Bogotá', 'Colombia'),
    ('11111111-0000-0000-0000-000000000002', 'Medellín', 'Colombia'),
    ('11111111-0000-0000-0000-000000000003', 'Cali', 'Colombia');

-- Deportes
INSERT INTO sports (id, name) VALUES
    ('22222222-0000-0000-0000-000000000001', 'Fútbol 5'),
    ('22222222-0000-0000-0000-000000000002', 'Fútbol 7'),
    ('22222222-0000-0000-0000-000000000003', 'Pádel'),
    ('22222222-0000-0000-0000-000000000004', 'Baloncesto');

-- Venue piloto en Bogotá (datos ficticios para dev)
INSERT INTO venues (id, name, address, city_id, lat, lng) VALUES
    (
        '33333333-0000-0000-0000-000000000001',
        'Complejo Deportivo Norte',
        'Calle 127 #15-40, Bogotá',
        '11111111-0000-0000-0000-000000000001',
        4.7110,
        -74.0721
    ),
    (
        '33333333-0000-0000-0000-000000000002',
        'Centro Deportivo Salitre',
        'Av. El Dorado #68D-11, Bogotá',
        '11111111-0000-0000-0000-000000000001',
        4.6589,
        -74.1058
    );

-- Canchas del venue piloto
INSERT INTO courts (id, venue_id, sport_id, name, surface_type, lights, price_per_hour) VALUES
    (
        '44444444-0000-0000-0000-000000000001',
        '33333333-0000-0000-0000-000000000001',
        '22222222-0000-0000-0000-000000000001',
        'Cancha 1 - Fútbol 5',
        'Grama sintética',
        TRUE,
        120000.00  -- COP
    ),
    (
        '44444444-0000-0000-0000-000000000002',
        '33333333-0000-0000-0000-000000000001',
        '22222222-0000-0000-0000-000000000002',
        'Cancha 2 - Fútbol 7',
        'Grama sintética',
        TRUE,
        150000.00  -- COP
    ),
    (
        '44444444-0000-0000-0000-000000000003',
        '33333333-0000-0000-0000-000000000002',
        '22222222-0000-0000-0000-000000000001',
        'Cancha A - Fútbol 5',
        'Pavimento',
        TRUE,
        100000.00  -- COP
    );

-- Políticas de cancelación para las canchas piloto
INSERT INTO court_policies (court_id, cancel_hours_before, penalty_percentage, no_show_fee) VALUES
    ('44444444-0000-0000-0000-000000000001', 24, 0.00, 30000.00),
    ('44444444-0000-0000-0000-000000000002', 24, 0.00, 40000.00),
    ('44444444-0000-0000-0000-000000000003', 12, 50.00, 25000.00);
