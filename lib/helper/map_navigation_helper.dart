import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class MapNavigationHelper {
  static const String _mapsPackage = 'com.google.android.apps.maps';
  static const MethodChannel _androidMapsChannel =
      MethodChannel('in.quiksee.dman/maps');

  static bool _isValidCoordinate(double lat, double lng) {
    return lat != 0 &&
        lng != 0 &&
        lat.abs() <= 90 &&
        lng.abs() <= 180;
  }

  static Future<bool> _launchMaps(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) debugPrint('Maps launch failed ($uri): $e');
      return false;
    }
  }

  static Future<bool> openDrivingNavigation({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final String? trimmedAddress =
        address != null && address.trim().isNotEmpty ? address.trim() : null;
    final bool hasAddress = trimmedAddress != null;
    final bool hasCoords = latitude != null &&
        longitude != null &&
        _isValidCoordinate(latitude, longitude);

    if (!hasAddress && !hasCoords) {
      return false;
    }

    // (e.g. store street → nearby hospital).
    if (hasCoords) {
      final String destCoords =
          '${latitude!.toStringAsFixed(7)},${longitude!.toStringAsFixed(7)}';
      if (kDebugMode) {
        debugPrint('Google Maps navigation → coords=$destCoords'
            '${hasAddress ? ' (label=$trimmedAddress)' : ''}');
      }
      return _openWithCoordinates(latitude, longitude, destCoords);
    }

    if (kDebugMode) {
      debugPrint('Google Maps navigation → address=$trimmedAddress');
    }
    return _openWithAddress(trimmedAddress!);
  }

  static Future<bool> _openWithAddress(
    String address, {
    double? latitude,
    double? longitude,
  }) async {
    final String encoded = Uri.encodeComponent(address);

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final opened = await _androidMapsChannel.invokeMethod<bool>(
          'openNavigation',
          {
            'address': address,
            if (latitude != null && longitude != null) ...{
              'latitude': latitude,
              'longitude': longitude,
            },
          },
        );
        if (opened == true) return true;
      } catch (e) {
        if (kDebugMode) debugPrint('Native Maps launch failed: $e');
      }

      final intentUri = Uri.parse(
        'intent://maps.google.com/maps?daddr=$encoded&directionsmode=driving'
        '#Intent;scheme=https;package=$_mapsPackage;end',
      );
      if (await _launchMaps(intentUri)) {
        return true;
      }
    }

    if (!kIsWeb && Platform.isIOS) {
      final iosUri = Uri.parse(
        'comgooglemaps://?daddr=$encoded&directionsmode=driving',
      );
      if (await canLaunchUrl(iosUri) && await _launchMaps(iosUri)) {
        return true;
      }
    }

    return _launchMaps(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$encoded&travelmode=driving',
      ),
    );
  }

  static Future<bool> _openWithCoordinates(
    double latitude,
    double longitude,
    String destCoords,
  ) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final opened = await _androidMapsChannel.invokeMethod<bool>(
          'openNavigation',
          {'latitude': latitude, 'longitude': longitude},
        );
        if (opened == true) return true;
      } catch (e) {
        if (kDebugMode) debugPrint('Native Maps launch failed: $e');
      }

      final intentUri = Uri.parse(
        'intent://maps.google.com/maps?daddr=$destCoords&directionsmode=driving'
        '#Intent;scheme=https;package=$_mapsPackage;end',
      );
      if (await _launchMaps(intentUri)) {
        return true;
      }
    }

    if (!kIsWeb && Platform.isIOS) {
      final iosUri = Uri.parse(
        'comgooglemaps://?daddr=$destCoords&directionsmode=driving',
      );
      if (await canLaunchUrl(iosUri) && await _launchMaps(iosUri)) {
        return true;
      }
    }

    return _launchMaps(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$destCoords&travelmode=driving',
      ),
    );
  }
}
