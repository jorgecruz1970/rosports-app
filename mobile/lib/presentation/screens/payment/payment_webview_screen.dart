import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla que abre el WebView de PayU para que el usuario complete el pago.
/// Escucha el deep link de respuesta (rosports://payment/response) para volver.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.paymentId,
  });

  final String checkoutUrl;
  final String paymentId;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onNavigationRequest: (request) {
          // Interceptar deep link de respuesta de PayU
          if (request.url.startsWith('rosports://payment/response')) {
            _handlePaymentResponse(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handlePaymentResponse(String url) {
    // Navegar a la pantalla de resultado del pago
    context.go(
      '${AppRoutes.paymentResult}?paymentId=${widget.paymentId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago seguro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('Cargando pasarela de pago...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar pago?'),
        content: const Text(
          'Si sales ahora, tu reserva quedará pendiente de pago. '
          'Podrás reintentar desde tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar pagando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (cancel == true && context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}
