import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

abstract final class IndiaPhoneConfig {
  static const String isoCode = 'IN';
  static const String dialCode = '+91';
  static const List<String> countryFilter = [isoCode];
  static const List<String> favorite = [isoCode, dialCode];
}

class CountryCodeHelper {
  static String dialCodeOrDefault(String? value) => IndiaPhoneConfig.dialCode;

  static String isoCodeOrDefault(String? value) => IndiaPhoneConfig.isoCode;

  static String? getCountryCode(String? number) {
    if (number == null || number.trim().isEmpty) {
      return IndiaPhoneConfig.dialCode;
    }
    String? countryCode;
    try {
      countryCode = codes.firstWhere(
        (item) => number.contains('${item['dial_code']}'),
      )['dial_code'];
    } catch (error) {
      debugPrint('country error: $error');
    }
    return dialCodeOrDefault(countryCode);
  }

  static String? getCountryCodebyCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return IndiaPhoneConfig.dialCode;
    }
    final String upper = code.toUpperCase();
    if (upper == IndiaPhoneConfig.isoCode || upper == IndiaPhoneConfig.dialCode) {
      return IndiaPhoneConfig.dialCode;
    }
    try {
      final String? fromIso = codes.firstWhere(
        (item) => item['code']?.toUpperCase() == upper,
      )['dial_code'];
      return dialCodeOrDefault(fromIso);
    } catch (error) {
      debugPrint('country error: $error');
    }
    return IndiaPhoneConfig.dialCode;
  }

  static String extractPhoneNumber(String countryCode, String phoneNumber) {
    String local = phoneNumber.replaceAll(countryCode, '');
    for (final item in codes) {
      final String? dial = item['dial_code'];
      if (dial != null && dial.isNotEmpty && phoneNumber.startsWith(dial)) {
        local = phoneNumber.substring(dial.length);
        break;
      }
    }
    return local.trim();
  }
}
