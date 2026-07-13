-- =============================================
-- ROSports.app — Migración 005: Funciones RPC para Partidos
-- =============================================

-- Incrementar spots_taken al unirse a un partido
CREATE OR REPLACE FUNCTION increment_match_spots(match_id_param UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE matches
  SET spots_taken = spots_taken + 1,
      status = CASE
        WHEN spots_taken + 1 >= spots_total THEN 'full'
        ELSE status
      END,
      updated_at = NOW()
  WHERE id = match_id_param
    AND status = 'open'
    AND spots_taken < spots_total;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No se puede unir: partido lleno o no disponible';
  END IF;
END;
$$;

-- Decrementar spots_taken al salir de un partido
CREATE OR REPLACE FUNCTION decrement_match_spots(match_id_param UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE matches
  SET spots_taken = GREATEST(spots_taken - 1, 0),
      status = CASE
        WHEN status = 'full' THEN 'open'
        ELSE status
      END,
      updated_at = NOW()
  WHERE id = match_id_param;
END;
$$;

-- Función para auto-completar partidos pasados (scheduled job)
CREATE OR REPLACE FUNCTION complete_past_matches()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE matches
  SET status = 'completed',
      updated_at = NOW()
  WHERE status IN ('open', 'full')
    AND end_time < NOW() - INTERVAL '1 hour';
END;
$$;

-- Función para liberar slots expirados (reservas pending > 10 min)
CREATE OR REPLACE FUNCTION release_expired_slots()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Encontrar reservas pending sin pago por más de 10 minutos
  UPDATE availability_slots
  SET status = 'available'
  WHERE id IN (
    SELECT r.slot_id
    FROM reservations r
    WHERE r.status = 'pending'
      AND r.payment_id IS NULL
      AND r.created_at < NOW() - INTERVAL '10 minutes'
  );

  -- Cancelar las reservas expiradas
  UPDATE reservations
  SET status = 'cancelled',
      cancelled_at = NOW(),
      cancel_reason = 'Tiempo de pago expirado'
  WHERE status = 'pending'
    AND payment_id IS NULL
    AND created_at < NOW() - INTERVAL '10 minutes';
END;
$$;
