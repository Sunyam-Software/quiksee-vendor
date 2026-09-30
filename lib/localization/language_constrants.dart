import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/localization/app_localization.dart';

String? getTranslated(String? key, BuildContext context) {
  String? text = key;
  try {
    text = AppLocalization.of(context)!.translate(key);
  } catch (error) {
    debugPrint('error --- $error');
  }
  return text;
}

String gstDisplayText(String? text, {String? fallback}) {
  final raw =
      (text == null || text.isEmpty || text == 'null') ? fallback : text;
  if (raw == null || raw.isEmpty) return fallback ?? '';
  return raw
      .replaceAll('VAT', 'GST')
      .replaceAll('Vat', 'GST')
      .replaceAll('vat', 'gst');
}

String? getGstTranslated(String? key, BuildContext context,
    {String? fallback}) {
  return gstDisplayText(getTranslated(key, context), fallback: fallback);
}
