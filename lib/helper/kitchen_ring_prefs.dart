import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KitchenRingPrefs {
  static bool? _cached;

  static bool get enabledNow => _cached ?? true;

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool enabled = true;
      try {
        enabled = prefs.getBool(AppConstants.kitchenRingEnabled) ?? true;
      } catch (_) {
        enabled = true;
      }
      _cached = enabled;
      return enabled;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    _cached = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kitchenRingEnabled, enabled);
  }
}
