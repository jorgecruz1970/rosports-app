import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isChangingPass = false;
  bool _isDeletingAccount = false;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isChangingPass = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPassCtrl.text),
      );
      if (mounted) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    }
    setState(() => _isChangingPass = false);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Eliminar cuenta'),
        content: const Text(
          'Esta acción es irreversible.\n\n'
          '• Se eliminarán todos tus datos\n'
          '• Se cancelarán tus reservas activas\n'
          '• No podrás recuperar tu cuenta\n\n'
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR MI CUENTA',
                style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Segunda confirmación
    final confirmText = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escribe "ELIMINAR" para confirmar:'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'ELIMINAR',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Confirmar',
                  style: TextStyle(color: AppTheme.error)),
            ),
          ],
        );
      },
    );

    if (confirmText != 'ELIMINAR') {
      _showError('Escribe "ELIMINAR" exactamente para confirmar');
      return;
    }

    setState(() => _isDeletingAccount = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser!.id;

      // Soft delete: marcar perfil como eliminado
      await client.from('profiles').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'name': 'Usuario eliminado',
        'email': 'deleted_$userId@rosports.app',
        'phone': null,
        'avatar_url': null,
      }).eq('id', userId);

      // Cancelar reservas activas
      await client.from('reservations').update({
        'status': 'cancelled',
        'cancel_reason': 'Cuenta eliminada',
        'cancelled_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId).inFilter('status', ['pending', 'confirmed']);

      // Cerrar sesión
      await client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta eliminada. Lamentamos verte ir.')),
        );
        context.go(AppRoutes.login);
      }
    } catch (e) {
      _showError('Error al eliminar cuenta: $e');
    }
    setState(() => _isDeletingAccount = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cambiar contraseña
            const Text('Cambiar contraseña',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isChangingPass ? null : _changePassword,
              child: _isChangingPass
                  ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  : const Text('Cambiar contraseña'),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            // Zona de peligro
            const Text('Zona de peligro',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.error)),
            const SizedBox(height: 8),
            const Text(
              'Al eliminar tu cuenta se borran todos tus datos y se cancelan tus reservas activas. Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isDeletingAccount ? null : _deleteAccount,
              icon: _isDeletingAccount
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.error))
                  : const Icon(Icons.delete_forever, color: AppTheme.error),
              label: Text(
                _isDeletingAccount ? 'Eliminando...' : 'Eliminar mi cuenta',
                style: const TextStyle(color: AppTheme.error),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
