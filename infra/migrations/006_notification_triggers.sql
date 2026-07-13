-- =============================================
-- ROSports.app — Migración 006: Triggers de Notificaciones
-- Envía notificaciones automáticas al cambiar estado de reserva/partido
-- =============================================

-- Trigger: notificar cuando una reserva cambia de estado
CREATE OR REPLACE FUNCTION notify_reservation_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _title TEXT;
  _body TEXT;
  _court_name TEXT;
BEGIN
  -- Solo actuar si el status cambió
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Obtener nombre de la cancha
  SELECT COALESCE(c.name, v.name)
  INTO _court_name
  FROM courts c
  JOIN venues v ON c.venue_id = v.id
  WHERE c.id = NEW.court_id;

  -- Construir mensaje según nuevo estado
  CASE NEW.status
    WHEN 'confirmed' THEN
      _title := '¡Reserva confirmada!';
      _body := 'Tu reserva en ' || _court_name || ' ha sido confirmada.';
    WHEN 'cancelled' THEN
      _title := 'Reserva cancelada';
      _body := 'Tu reserva en ' || _court_name || ' fue cancelada.';
    WHEN 'completed' THEN
      _title := '¡Partido completado!';
      _body := 'Esperamos que hayas disfrutado tu partido en ' || _court_name || '.';
    ELSE
      RETURN NEW;
  END CASE;

  -- Insertar notificación in-app
  INSERT INTO notifications (user_id, type, title, body, payload, sent_at)
  VALUES (
    NEW.user_id,
    'in-app',
    _title,
    _body,
    jsonb_build_object('reservation_id', NEW.id, 'status', NEW.status),
    NOW()
  );

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_reservation_status_notify
  AFTER UPDATE OF status ON reservations
  FOR EACH ROW
  EXECUTE FUNCTION notify_reservation_status_change();

-- Trigger: notificar al creador cuando alguien se une a su partido
CREATE OR REPLACE FUNCTION notify_match_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _creator_id UUID;
  _player_name TEXT;
  _match_info TEXT;
BEGIN
  -- Solo en inscripciones nuevas con status 'signed'
  IF NEW.status != 'signed' THEN
    RETURN NEW;
  END IF;

  -- Obtener creador del partido
  SELECT m.creator_user_id
  INTO _creator_id
  FROM matches m
  WHERE m.id = NEW.match_id;

  -- No notificar al creador si es él mismo
  IF _creator_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Obtener nombre del jugador
  SELECT name INTO _player_name
  FROM profiles WHERE id = NEW.user_id;

  -- Info del partido
  SELECT s.name || ' — ' || COALESCE(c.name, v.name)
  INTO _match_info
  FROM matches m
  JOIN courts c ON m.court_id = c.id
  JOIN venues v ON c.venue_id = v.id
  JOIN sports s ON m.sport_id = s.id
  WHERE m.id = NEW.match_id;

  -- Notificar al creador
  INSERT INTO notifications (user_id, type, title, body, payload, sent_at)
  VALUES (
    _creator_id,
    'in-app',
    '¡Nuevo jugador!',
    COALESCE(_player_name, 'Un jugador') || ' se unió a tu partido de ' || COALESCE(_match_info, 'deporte'),
    jsonb_build_object('match_id', NEW.match_id, 'player_id', NEW.user_id),
    NOW()
  );

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_match_signup_notify
  AFTER INSERT ON match_signups
  FOR EACH ROW
  EXECUTE FUNCTION notify_match_signup();

-- Función programada: recordatorio 1h antes de la reserva
-- (Se ejecuta con pg_cron o Supabase scheduled function)
CREATE OR REPLACE FUNCTION send_upcoming_reminders()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO notifications (user_id, type, title, body, payload, sent_at)
  SELECT
    r.user_id,
    'in-app',
    '⏰ Tu reserva es en 1 hora',
    'Recuerda tu partido en ' || COALESCE(c.name, v.name) || ' a las ' ||
      TO_CHAR(r.start_time AT TIME ZONE 'America/Bogota', 'HH24:MI'),
    jsonb_build_object('reservation_id', r.id),
    NOW()
  FROM reservations r
  JOIN courts c ON r.court_id = c.id
  JOIN venues v ON c.venue_id = v.id
  WHERE r.status IN ('pending', 'confirmed')
    AND r.start_time BETWEEN NOW() + INTERVAL '55 minutes'
                         AND NOW() + INTERVAL '65 minutes'
    AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.user_id = r.user_id
        AND n.payload->>'reservation_id' = r.id::text
        AND n.title LIKE '%1 hora%'
    );
END;
$$;
