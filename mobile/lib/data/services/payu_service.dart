import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/config/env.dart';

/// Servicio para generar parámetros de pago PayU Latam (Colombia).
/// Usa el flujo WebCheckout (redirect) — el usuario se redirige a PayU
/// y al completar vuelve a la app vía deep link.
class PayUService {
  PayUService._();

  static const String _sandboxUrl =
      'https://sandbox.checkout.payulatam.com/ppp-web-gateway-payu';
  static const String _productionUrl =
      'https://checkout.payulatam.com/ppp-web-gateway-payu';

  static String get _baseUrl =>
      Env.isSandbox ? _sandboxUrl : _productionUrl;

  /// Account ID de PayU Colombia
  static const String _accountId = '512321'; // Sandbox Colombia

  /// Genera la URL de redirect para WebCheckout de PayU
  static String buildCheckoutUrl({
    required String referenceCode,
    required double amount,
    required String currency,
    required String description,
    required String buyerEmail,
    required String buyerName,
  }) {
    final merchantId = Env.payuMerchantId;
    final apiKey = Env.payuApiKey;

    // Signature: MD5(ApiKey~merchantId~referenceCode~amount~currency)
    final signatureRaw = '$apiKey~$merchantId~$referenceCode~$amount~$currency';
    final signature = md5.convert(utf8.encode(signatureRaw)).toString();

    // Response y confirmation URLs (deep links de la app)
    const responseUrl = 'rosports://payment/response';
    const confirmationUrl =
        'https://YOUR_SUPABASE_PROJECT.supabase.co/functions/v1/payment-webhook';

    final params = {
      'merchantId': merchantId,
      'accountId': _accountId,
      'description': description,
      'referenceCode': referenceCode,
      'amount': amount.toStringAsFixed(2),
      'tax': '0',
      'taxReturnBase': '0',
      'currency': currency,
      'signature': signature,
      'buyerEmail': buyerEmail,
      'buyerFullName': buyerName,
      'responseUrl': responseUrl,
      'confirmationUrl': confirmationUrl,
      'test': Env.isSandbox ? '1' : '0',
    };

    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$_baseUrl?$queryString';
  }
}
