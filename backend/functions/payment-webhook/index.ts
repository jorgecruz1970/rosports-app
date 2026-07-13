/**
 * ROSports — Payment Webhook (Supabase Edge Function)
 * 
 * Recibe confirmaciones de PayU y actualiza el estado del pago + reserva.
 * URL: https://{project}.supabase.co/functions/v1/payment-webhook
 * 
 * PayU envía un POST con los parámetros del resultado de la transacción.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createHash } from 'https://deno.land/std@0.208.0/crypto/mod.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const PAYU_API_KEY = Deno.env.get('PAYU_API_KEY')!;

interface PayUConfirmation {
  merchant_id: string;
  state_pol: string;           // 4=Aprobada, 6=Rechazada, 5=Expirada
  risk: string;
  response_code_pol: string;
  reference_sale: string;      // Nuestro reference_code
  reference_pol: string;
  sign: string;                // Firma MD5 para validar
  extra1: string;
  extra2: string;
  payment_method: string;
  payment_method_type: string;
  installments_number: string;
  value: string;
  tax: string;
  transaction_date: string;
  currency: string;
  email_buyer: string;
  cus: string;
  pse_bank: string;
  description: string;
  billing_address: string;
  shipping_address: string;
  phone: string;
  office_phone: string;
  account_number_ach: string;
  account_type_ach: string;
  administrative_fee: string;
  administrative_fee_base: string;
  administrative_fee_tax: string;
  airline_code: string;
  attempts: string;
  authorization_code: string;
  bank_id: string;
  billing_city: string;
  billing_country: string;
  commision_pol: string;
  commision_pol_currency: string;
  customer_number: string;
  date: string;
  error_code_bank: string;
  error_message_bank: string;
  exchange_rate: string;
  ip: string;
  nickname_buyer: string;
  nickname_seller: string;
  payment_method_id: string;
  payment_request_state: string;
  response_message_pol: string;
  transaction_bank_id: string;
  transaction_id: string;
  payment_method_name: string;
}

Deno.serve(async (req: Request) => {
  // Solo POST
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const formData = await req.formData();
    const params: Record<string, string> = {};
    formData.forEach((value, key) => {
      params[key] = value.toString();
    });

    const {
      merchant_id,
      state_pol,
      reference_sale,
      sign,
      value: txValue,
      currency,
      transaction_id,
    } = params as unknown as PayUConfirmation;

    // Validar firma de PayU
    // Firma: MD5(ApiKey~merchantId~referenceCode~value~currency~state_pol)
    const signRaw = `${PAYU_API_KEY}~${merchant_id}~${reference_sale}~${txValue}~${currency}~${state_pol}`;
    const encoder = new TextEncoder();
    const data = encoder.encode(signRaw);
    const hashBuffer = await crypto.subtle.digest('MD5', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const expectedSign = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    if (expectedSign !== sign) {
      console.error('Invalid signature', { expected: expectedSign, received: sign });
      return new Response('Invalid signature', { status: 401 });
    }

    // Mapear state_pol de PayU a nuestro status
    let paymentStatus: string;
    let reservationStatus: string;

    switch (state_pol) {
      case '4': // Aprobada
        paymentStatus = 'captured';
        reservationStatus = 'confirmed';
        break;
      case '6': // Rechazada
        paymentStatus = 'failed';
        reservationStatus = 'pending'; // Mantener pending para retry
        break;
      case '5': // Expirada
        paymentStatus = 'failed';
        reservationStatus = 'pending';
        break;
      default:
        paymentStatus = 'initiated';
        reservationStatus = 'pending';
    }

    // Conectar a Supabase con service role
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Buscar el pago por reference_code en raw_response
    const { data: payments, error: findError } = await supabase
      .from('payments')
      .select('id, reservation_id')
      .contains('raw_response', { reference_code: reference_sale })
      .limit(1);

    if (findError || !payments || payments.length === 0) {
      console.error('Payment not found for reference:', reference_sale);
      return new Response('Payment not found', { status: 404 });
    }

    const payment = payments[0];

    // Actualizar el pago
    const { error: updatePaymentError } = await supabase
      .from('payments')
      .update({
        status: paymentStatus,
        provider_payment_id: transaction_id,
        raw_response: params,
        updated_at: new Date().toISOString(),
      })
      .eq('id', payment.id);

    if (updatePaymentError) {
      console.error('Error updating payment:', updatePaymentError);
      return new Response('Error updating payment', { status: 500 });
    }

    // Actualizar la reserva
    if (payment.reservation_id) {
      const { error: updateReservationError } = await supabase
        .from('reservations')
        .update({
          status: reservationStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.reservation_id);

      if (updateReservationError) {
        console.error('Error updating reservation:', updateReservationError);
      }
    }

    console.log(`Payment ${payment.id} updated to ${paymentStatus}`);
    return new Response('OK', { status: 200 });

  } catch (error) {
    console.error('Webhook error:', error);
    return new Response('Internal error', { status: 500 });
  }
});
