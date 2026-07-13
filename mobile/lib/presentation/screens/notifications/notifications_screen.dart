import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Modelo simple de notificación
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}

/// Provider de notificaciones del usuario
final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from(AppConstants.tableNotifications)
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);

  return data.map((j) => NotificationItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        type: j['type'] as String? ?? 'in-app',
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        readAt: j['read_at'] != null
            ? DateTime.parse(j['read_at'] as String).toLocal()
            : null,
      )).toList();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(ref),
            child: const Text('Marcar todas',
                style: TextStyle(color: AppTheme.primary, fontSize: 13)),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No tienes notificaciones',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (_, i) => _NotificationTile(
                notification: notifications[i],
                onTap: () => _markRead(ref, notifications[i].id),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markRead(WidgetRef ref, String notifId) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from(AppConstants.tableNotifications)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notifId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _markAllRead(WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client
        .from(AppConstants.tableNotifications)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
    ref.invalidate(notificationsProvider);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('d MMM — HH:mm', 'es_CO');

    IconData icon;
    Color iconColor;
    switch (notification.type) {
      case 'push':
        icon = Icons.notifications_active;
        iconColor = AppTheme.primary;
        break;
      case 'email':
        icon = Icons.email_outlined;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
    }

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(notification.body,
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeFmt.format(notification.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          if (!notification.isRead) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
