import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Handler para mensajes en background (debe ser una función top-level).
/// Se ejecuta fuera del contexto de Flutter, por eso no puede usar setState.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Aquí se podrían guardar notificaciones en local DB si es necesario
  // Por ahora solo registramos el evento
}

/// Datasource para notificaciones push con Firebase Cloud Messaging.
/// Gestiona permisos, token FCM y suscripciones a notificaciones.
class NotificationDatasource {
  NotificationDatasource(this._messaging, this._supabase);

  final FirebaseMessaging _messaging;
  final SupabaseClient _supabase;

  // ── Inicializar FCM ─────────────────────────────────────────────────────────
  /// Configura Firebase Messaging: permisos, token y listeners.
  Future<void> initialize() async {
    // Registrar el handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Solicitar permisos al usuario (iOS y Android 13+)
    await _requestPermissions();

    // Obtener el token y guardarlo en Supabase
    await _saveTokenToSupabase();

    // Escuchar actualizaciones de token (cambio de dispositivo, renovación)
    _messaging.onTokenRefresh.listen((newToken) async {
      await _upsertToken(newToken);
    });

    // Configurar listener para notificaciones en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Configurar listener cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // ── Solicitar permisos ──────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // true permitiría notificaciones silenciosas en iOS
    );
  }

  // ── Guardar token en Supabase ───────────────────────────────────────────────
  Future<void> _saveTokenToSupabase() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _upsertToken(token);
    }
  }

  /// Inserta o actualiza el FCM token del usuario en la tabla `user_tokens`.
  Future<void> _upsertToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    // Si no hay usuario autenticado, no guardamos el token
    if (userId == null) return;

    try {
      await _supabase.from(AppConstants.tableUserTokens).upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': _getPlatform(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // No propagar errores de token para no afectar el flujo principal
    }
  }

  // ── Handlers de mensajes ────────────────────────────────────────────────────
  /// Maneja notificaciones recibidas con la app en primer plano.
  void _handleForegroundMessage(RemoteMessage message) {
    // En una implementación completa aquí mostraríamos un banner local
    // usando flutter_local_notifications
    final notification = message.notification;
    if (notification != null) {
      // Por ahora solo registramos el evento — se ampliará en Sprint 2
    }
  }

  /// Maneja el tap en una notificación cuando la app estaba en background.
  void _handleNotificationTap(RemoteMessage message) {
    // Aquí se navegaría a la pantalla correspondiente según message.data
    // Por ahora dejamos el hook preparado para Sprint 2
  }

  // ── Obtener token actual ─────────────────────────────────────────────────────
  /// Retorna el FCM token actual o null si no está disponible.
  Future<String?> getToken() => _messaging.getToken();

  // ── Helper de plataforma ─────────────────────────────────────────────────────
  String _getPlatform() {
    // dart:io no está disponible en web, pero este proyecto es mobile only
    try {
      // ignore: do_not_use_environment
      const bool isAndroid = bool.fromEnvironment('dart.library.io');
      return isAndroid ? 'android' : 'ios';
    } catch (_) {
      return 'unknown';
    }
  }
}
