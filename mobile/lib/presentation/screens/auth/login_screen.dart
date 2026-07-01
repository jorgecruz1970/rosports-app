import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      data: (user) { if (user != null) context.go(AppRoutes.home); },
      error: (e, _) => _showError(e.toString()),
    );
  }

  Future<void> _loginGoogle() async {
    await ref.read(authNotifierProvider.notifier).loginWithGoogle();
  }

  void _showError(String msg) {
    // Limpia el prefijo técnico del mensaje
    final clean = msg.replaceFirst(RegExp(r'^AppException\(\w*\):\s*'), '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(clean), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    // Escuchar cambios de estado para navegar
    ref.listen(authNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (user) { if (user != null && mounted) context.go(AppRoutes.home); },
        error: (e, _) { if (mounted) _showError(e.toString()); },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.sports_soccer, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Bienvenido',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Inicia sesión para reservar tu cancha',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                const SizedBox(height: 32),
                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primary),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.primary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: const Text('¿Olvidaste tu contraseña?',
                        style: TextStyle(color: AppTheme.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                // Botón login
                ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o continúa con',
                        style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                ]),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _loginGoogle,
                  icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                  label: const Text('Continuar con Google',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes cuenta?',
                        style: TextStyle(color: Colors.white.withOpacity(0.7))),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.register),
                      child: const Text('Regístrate',
                          style: TextStyle(
                              color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
