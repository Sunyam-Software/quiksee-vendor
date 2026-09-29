import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

bool isLocalOrPrivateHost(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host.isEmpty) return false;
  if (host == 'localhost' || host == '127.0.0.1') return true;
  if (host.startsWith('192.168.') || host.startsWith('10.')) return true;
  if (host.startsWith('172.')) {
    final secondOctet = int.tryParse(host.split('.').elementAtOrNull(1) ?? '');
    if (secondOctet != null && secondOctet >= 16 && secondOctet <= 31) {
      return true;
    }
  }
  return false;
}

void configureLocalSslTrust() {
  if (kIsWeb) return;
  final scheme = Uri.tryParse(AppConstants.baseUrl)?.scheme;
  if (scheme != 'https' || !isLocalOrPrivateHost(AppConstants.baseUrl)) {
    return;
  }
  HttpOverrides.global = _LocalDevHttpOverrides();
}

String resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final baseScheme = Uri.tryParse(AppConstants.baseUrl)?.scheme ?? 'http';
  if (baseScheme != 'http') return url;

  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (uri.scheme == 'https' && isLocalOrPrivateHost(url)) {
    return uri.replace(scheme: 'http').toString();
  }
  return url;
}

class _LocalDevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final HttpClient client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}
