/**
 * ROSports — Send Notification Edge Function
 * 
 * Envía push notifications vía FCM y guarda en tabla notifications.
 * Se invoca desde triggers de DB o directamente.
 * 
 * Body esperado:
 * {
 *   "user_id": "uuid",
 *   "title": "string",
 *   "body": "string",
 *   "type": "push" | "in-app",
 *   "payload": {} // datos extra opcionales
 * }
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') ?? '';

interface NotificationRequest {
  user_id: string;
  title: string;
  body: string;
  type?: 'push' | 'in-app' | 'email';
  payload?: Record<string, unknown>;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const { user_id, title, body, type = 'push', payload = {} } =
      await req.json() as NotificationRequest;

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'user_id, title, and body are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Guardar notificación in-app
    await supabase.from('notifications').insert({
      user_id,
      type,
      title,
      body,
      payload,
      sent_at: new Date().toISOString(),
    });

    // 2. Si es push, enviar vía FCM
    if (type === 'push' && FCM_SERVER_KEY) {
      // Obtener tokens del usuario
      const { data: tokens } = await supabase
        .from('user_tokens')
        .select('token')
        .eq('user_id', user_id);

      if (tokens && tokens.length > 0) {
        const fcmTokens = tokens.map((t: { token: string }) => t.token);

        // Enviar a cada token vía FCM HTTP v1
        for (const token of fcmTokens) {
          try {
            await fetch('https://fcm.googleapis.com/fcm/send', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `key=${FCM_SERVER_KEY}`,
              },
              body: JSON.stringify({
                to: token,
                notification: { title, body },
                data: payload,
              }),
            });
          } catch (fcmError) {
            console.error(`FCM error for token ${token}:`, fcmError);
          }
        }

        console.log(`Push sent to ${fcmTokens.length} device(s) for user ${user_id}`);
      }
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Notification sent' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    console.error('Notification error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
