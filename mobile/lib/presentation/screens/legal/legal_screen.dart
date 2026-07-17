import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.title, required this.url});
  final String title;
  final String url;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
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
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ],
      ),
    );
  }
}

/// Pantalla temporal con contenido legal inline (mientras no haya URL)
class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({super.key, required this.title, required this.isPrivacy});
  final String title;
  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Última actualización: Julio 2026',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 24),
            if (isPrivacy) ..._privacyContent() else ..._termsContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _privacyContent() => [
        _section('1. Información que recopilamos',
            'Recopilamos la información que nos proporcionas al crear una cuenta: nombre, email, teléfono (opcional) y foto de perfil. También recopilamos datos de uso como reservas realizadas, partidos creados y preferencias.'),
        _section('2. Cómo usamos tu información',
            'Usamos tu información para: proveer el servicio de reserva de canchas, facilitar la creación de partidos, procesar pagos, enviar notificaciones relevantes y mejorar la experiencia de la app.'),
        _section('3. Compartir información',
            'No vendemos tu información personal. Compartimos datos limitados con: proveedores de pago (PayU) para procesar transacciones, y administradores de canchas (solo nombre y hora de reserva).'),
        _section('4. Seguridad',
            'Protegemos tu información usando encriptación, Row Level Security en base de datos y autenticación segura vía Supabase Auth.'),
        _section('5. Tus derechos',
            'Puedes: acceder a tus datos desde tu perfil, corregir tu información, eliminar tu cuenta en cualquier momento desde Configuración, y solicitar una copia de tus datos contactándonos.'),
        _section('6. Contacto',
            'Para consultas sobre privacidad: privacidad@rosports.app'),
      ];

  List<Widget> _termsContent() => [
        _section('1. Aceptación',
            'Al usar ROSports aceptas estos términos. Si no estás de acuerdo, no uses la aplicación.'),
        _section('2. Servicio',
            'ROSports es una plataforma para reservar canchas deportivas y organizar partidos abiertos. No somos propietarios de las canchas ni responsables de su estado.'),
        _section('3. Cuentas',
            'Debes ser mayor de 16 años. Eres responsable de mantener la seguridad de tu cuenta y todas las actividades bajo ella.'),
        _section('4. Reservas y pagos',
            'Las reservas están sujetas a disponibilidad. Los pagos se procesan vía PayU. La comisión del servicio es del 10% sobre el precio de la cancha.'),
        _section('5. Cancelaciones',
            'Cancelación gratuita hasta 24 horas antes. Después puede aplicar penalización según la política de cada cancha.'),
        _section('6. Partidos abiertos',
            'Al crear o unirte a un partido, aceptas respetar el horario y a los demás jugadores. Los no-shows pueden resultar en amonestaciones.'),
        _section('7. Conducta',
            'Nos reservamos el derecho de suspender cuentas por: no-shows repetidos, comportamiento inadecuado reportado o uso fraudulento.'),
        _section('8. Contacto',
            'Consultas generales: soporte@rosports.app'),
      ];

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(body,
                style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
          ],
        ),
      );
}
