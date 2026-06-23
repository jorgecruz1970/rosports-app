import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

/**
 * Edge Function: payment-webhook
 * Recibe la confirmación de pago de PayU / MercadoPago
 * y actualiza el estado de la reserva en DB
 */
serve(async (req: Request) => {
  try {
    // Solo aceptar POST
    if (req.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405 })
    }

    const body = await req.json()
    const provider = req.headers.get('x-payment-provider') ?? 'unknown'

    // Inicializar Supabase con service role (acceso total, solo en backend)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Mapear el payload según proveedor
    const paymentData = parsePaymentPayload(provider, body)

    if (!paymentData) {
      return new Response('Invalid payload', { status: 400 })
    }

    // Actualizar estado del pago
    const { error: paymentError } = await supabase
      .from('payments')
      .update({
        status: paymentData.status,
        provider_payment_id: paymentData.providerPaymentId,
        raw_response: body,
        updated_at: new Date().toISOString(),
      })
      .eq('id', paymentData.paymentId)

    if (paymentError) throw paymentError

    // Si el pago fue capturado, confirmar la reserva
    if (paymentData.status === 'captured') {
      const { error: reservationError } = await supabase
        .from('reservations')
        .update({
          status: 'confirmed',
          updated_at: new Date().toISOString(),
        })
        .eq('payment_id', paymentData.paymentId)

      if (reservationError) throw reservationError

      // Actualizar slot a 'booked'
      await supabase
        .from('availability_slots')
        .update({ status: 'booked' })
        .eq('id', paymentData.slotId)

      // TODO: disparar notificación push al usuario
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('[payment-webhook] Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Normaliza el payload según el proveedor de pago
 */
function parsePaymentPayload(provider: string, body: Record<string, unknown>) {
  if (provider === 'payu') {
    // PayU envía: transactionResponse.state, transactionId
    const txResponse = body.transactionResponse as Record<string, unknown>
    if (!txResponse) return null

    const statusMap: Record<string, string> = {
      APPROVED: 'captured',
      DECLINED: 'failed',
      PENDING: 'authorized',
    }

    return {
      paymentId: body.merchantTransactionId as string,
      providerPaymentId: txResponse.transactionId as string,
      status: statusMap[txResponse.state as string] ?? 'failed',
      slotId: body.additionalInfo as string,
    }
  }

  if (provider === 'mercadopago') {
    // MercadoPago envía: action, data.id
    const statusMap: Record<string, string> = {
      'payment.created': 'authorized',
      'payment.updated': 'captured',
    }

    return {
      paymentId: body.external_reference as string,
      providerPaymentId: String((body.data as Record<string, unknown>)?.id),
      status: statusMap[body.action as string] ?? 'failed',
      slotId: body.slot_id as string,
    }
  }

  return null
}
