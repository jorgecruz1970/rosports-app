import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../providers/payment_provider.dart';
import '../../providers/reservation_provider.dart';

/// Pantalla de resultado del pago — hace polling al estado hasta obtener
/// un estado final (captured/failed/authorized).
class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({super.key, required this.paymentId});
  final String paymentId;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  Timer? _pollTimer;
  PaymentEntity? _payment;
  bool _isPolling = true;
  int _pollCount = 0;
  static const int _maxPolls = 12; // 12 * 5s = 60s max

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _checkStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollCount++;
      if (_pollCount >= _maxPolls) {
        _pollTimer?.cancel();
        setState(() => _isPolling = false);
        return;
      }
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    try {
      final repo = ref.read(paymentRepositoryProvider);
      final payment = await repo.getPaymentStatus(widget.paymentId);
      setState(() => _payment = payment);

      if (payment.status != PaymentStatus.initiated) {
        _pollTimer?.cancel();
        setState(() => _isPolling = false);
        // Invalidar reservas para refrescar
        ref.invalidate(myReservationsProvider);
      }
    } catch (_) {
      // Seguir polling
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isPolling ? _buildPolling() : _buildResult(),
        ),
      ),
    );
  }

  Widget _buildPolling() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 24),
          Text('Verificando tu pago...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(
            'Esto puede tomar unos segundos.\nNo cierres la aplicación.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_payment == null) return _buildTimeout();

    switch (_payment!.status) {
      case PaymentStatus.authorized:
      case PaymentStatus.captured:
        return _buildSuccess();
      case PaymentStatus.failed:
        return _buildFailed();
      default:
        return _buildTimeout();
    }
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 56),
        ),
        const SizedBox(height: 24),
        const Text('¡Pago exitoso!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Tu reserva ha sido confirmada.\nTe esperamos en la cancha.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Ir al inicio'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(AppRoutes.profile),
          child: const Text('Ver mis reservas',
              style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: AppTheme.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 56),
        ),
        const SizedBox(height: 24),
        const Text('Pago rechazado',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'No se pudo procesar tu pago.\nTu reserva sigue pendiente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Volver al inicio'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Reintentar pago',
              style: TextStyle(color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildTimeout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hourglass_top,
              color: Colors.orange, size: 48),
        ),
        const SizedBox(height: 24),
        const Text('Pago en proceso',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Tu pago está siendo procesado.\n'
          'Te notificaremos cuando se confirme.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Ir al inicio'),
        ),
      ],
    );
  }
}
