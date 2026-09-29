import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/order_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MapHelper {
  static double? parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  static LatLng? latLngFromAddress(BillingAddressData? address) {
    if (address == null) return null;
    final lat = parseCoordinate(address.latitude);
    final lng = parseCoordinate(address.longitude);
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;
    return LatLng(lat, lng);
  }

  static String addressQuery(BillingAddressData address) {
    return [
      address.address,
      address.city,
      address.zip,
      address.country,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
  }

  static Future<bool> openExternalMap(LatLng position) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}',
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openExternalMapForAddress(BillingAddressData address) async {
    final query = addressQuery(address);
    if (query.isEmpty) return false;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
