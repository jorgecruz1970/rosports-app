import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Servicio de Push Notifications con Firebase Cloud Messaging.
/// Registra el token FCM en Supabase y maneja mensajes entrantes.
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inicializar FCM — solicitar permisos y registrar token
  static Future<void> initialize() async {
    // Solicitar permisos (iOS requiere esto explícitamente)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notifications denied by user');
      return;
    }

    // Obtener token
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      await _saveToken(token);
    }

    // Escuchar refresh de token
    _messaging.onTokenRefresh.listen(_saveToken);

    // Manejar mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar tap en notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Verificar si la app se abrió desde una notificación
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// Guardar token FCM en Supabase
  static Future<void> _saveToken(String token) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';

    try {
      await client.from(AppConstants.tableUserTokens).upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'device_id': '${platform}_${user.id.substring(0, 8)}',
        },
        onConflict: 'user_id,device_id',
      );
      debugPrint('[FCM] Token saved to Supabase');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  /// Manejar notificación recibida con app en primer plano
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    // Las notificaciones en foreground no se muestran por defecto en Android
    // Se puede usar flutter_local_notifications para mostrarlas
    // Por ahora solo loggeamos
  }

  /// Manejar tap en notificación
  static void _handleMessageTap(RemoteMessage message) {
    debugPrint('[FCM] Message tap: ${message.data}');
    // Navegar según el payload
    // Ejemplo: {'type': 'reservation', 'id': 'xxx'}
    // Se implementará con deep link routing en el futuro
  }

  /// Eliminar token al cerrar sesión
  static Future<void> removeToken() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final platform = Platform.isIOS ? 'ios' : 'android';
    final deviceId = '${platform}_${user.id.substring(0, 8)}';

    try {
      await client
          .from(AppConstants.tableUserTokens)
          .delete()
          .eq('user_id', user.id)
          .eq('device_id', deviceId);
    } catch (e) {
      debugPrint('[FCM] Error removing token: $e');
    }
  }
}
