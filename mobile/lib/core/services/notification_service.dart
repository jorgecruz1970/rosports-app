import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/notification_datasource.dart';

/// Servicio de notificaciones — wrapper para inicialización de FCM.
/// Se llama desde [main.dart] una sola vez al arrancar la app.
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  late final NotificationDatasource _datasource;
  bool _initialized = false;

  // ── Inicializar ─────────────────────────────────────────────────────────────
  /// Inicializa Firebase Messaging y configura todos los listeners.
  /// Debe llamarse después de [Firebase.initializeApp()].
  Future<void> init() async {
    if (_initialized) return;

    _datasource = NotificationDatasource(
      FirebaseMessaging.instance,
      Supabase.instance.client,
    );

    try {
      await _datasource.initialize();
      _initialized = true;
    } catch (e) {
      // Los errores de notificaciones no deben bloquear el inicio de la app
      // En producción esto se reportaría a Sentry
    }
  }

  // ── Token actual ─────────────────────────────────────────────────────────────
  Future<String?> getToken() async {
    if (!_initialized) return null;
    return _datasource.getToken();
  }
}
