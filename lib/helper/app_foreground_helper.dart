import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppForegroundHelper {
  static const MethodChannel _channel =
      MethodChannel('in.quiksee.dman/foreground');

  static bool get _canUseNativeChannel =>
      !kIsWeb &&
      Platform.isAndroid &&
      PlatformDispatcher.instance.implicitView != null;

  static Future<void> bringToForeground({
    int? orderId,
    int? offerId,
    String? type,
  }) async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('bringToForeground', {
        if (orderId != null && orderId > 0) 'orderId': '$orderId',
        if (offerId != null && offerId > 0) 'offerId': '$offerId',
        if (type != null && type.isNotEmpty) 'type': type,
      });
    } catch (e) {
      debugPrint('bringToForeground failed: $e');
    }
  }

  static Future<void> wakeScreen() async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('wakeScreen');
    } catch (e) {
      debugPrint('wakeScreen failed: $e');
    }
  }

  static Future<void> startNativeAlert({bool force = false}) async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('startNativeAlert', {'force': force});
    } catch (e) {
      debugPrint('startNativeAlert failed: $e');
    }
  }

  static Future<void> stopNativeAlert() async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('stopNativeAlert');
    } catch (e) {
      debugPrint('stopNativeAlert failed: $e');
    }
  }

  static Future<void> dismissOrderWakeHeadsUp() async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('dismissOrderWakeHeadsUp');
    } catch (e) {
      debugPrint('dismissOrderWakeHeadsUp failed: $e');
    }
  }

  static Future<void> setDriverOnline(bool online) async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod(
        online ? 'startOnlineService' : 'stopOnlineService',
      );
    } catch (e) {
      debugPrint('setDriverOnline failed: $e');
    }
  }

  static Future<void> startNavigationService({
    required int orderId,
    String? address,
  }) async {
    if (!_canUseNativeChannel || orderId <= 0) return;
    try {
      await _channel.invokeMethod('startNavigationService', {
        'orderId': orderId,
        'address': address ?? '',
      });
    } catch (e) {
      debugPrint('startNavigationService failed: $e');
    }
  }

  static Future<void> stopNavigationService() async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('stopNavigationService');
    } catch (e) {
      debugPrint('stopNavigationService failed: $e');
    }
  }

  static Future<void> requestBatteryOptimizationExemption() async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('requestBatteryOptimizationExemption');
    } catch (e) {
      debugPrint('requestBatteryOptimizationExemption failed: $e');
    }
  }

  static Future<bool> needsOemAutostart() async {
    if (!_canUseNativeChannel) return false;
    try {
      final result = await _channel.invokeMethod<bool>('needsOemAutostart');
      return result ?? false;
    } catch (e) {
      debugPrint('needsOemAutostart failed: $e');
      return false;
    }
  }

  static Future<String> oemManufacturerLabel() async {
    if (!_canUseNativeChannel) return 'Android';
    try {
      final result = await _channel.invokeMethod<String>('oemManufacturerLabel');
      return result ?? 'Android';
    } catch (e) {
      debugPrint('oemManufacturerLabel failed: $e');
      return 'Android';
    }
  }

  static Future<bool> openOemAutostartSettings() async {
    if (!_canUseNativeChannel) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openOemAutostartSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('openOemAutostartSettings failed: $e');
      return false;
    }
  }

  static Future<bool> canUseFullScreenIntent() async {
    if (!_canUseNativeChannel) return true;
    try {
      final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } catch (e) {
      debugPrint('canUseFullScreenIntent failed: $e');
      return true;
    }
  }

  static Future<void> requestFullScreenIntentPermission() async {
    if (!_canUseNativeChannel) return;
    try {
      await _channel.invokeMethod('requestFullScreenIntentPermission');
    } catch (e) {
      debugPrint('requestFullScreenIntentPermission failed: $e');
    }
  }

  static Future<void> showNavigationDeliverAlert({
    required int orderId,
    required String title,
    required String address,
  }) async {
    if (!_canUseNativeChannel || orderId <= 0) return;
    try {
      await _channel.invokeMethod('showNavigationDeliverAlert', {
        'orderId': orderId,
        'title': title,
        'address': address,
      });
    } catch (e) {
      debugPrint('showNavigationDeliverAlert failed: $e');
    }
  }

  static Future<void> dismissNavigationDeliverAlert(int orderId) async {
    if (!_canUseNativeChannel || orderId <= 0) return;
    try {
      await _channel.invokeMethod('dismissNavigationDeliverAlert', {
        'orderId': orderId,
      });
    } catch (e) {
      debugPrint('dismissNavigationDeliverAlert failed: $e');
    }
  }

  static Future<bool> hasBackgroundLocationPermission() async {
    if (!_canUseNativeChannel) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('hasBackgroundLocationPermission');
      return result ?? false;
    } catch (e) {
      debugPrint('hasBackgroundLocationPermission failed: $e');
      return false;
    }
  }

  static Future<bool> needsBackgroundLocationStep() async {
    if (!_canUseNativeChannel) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('needsBackgroundLocationStep');
      return result ?? false;
    } catch (e) {
      debugPrint('needsBackgroundLocationStep failed: $e');
      return false;
    }
  }

  static Future<int?> androidSdkInt() async {
    if (!_canUseNativeChannel) return null;
    try {
      final result = await _channel.invokeMethod<int>('androidSdkInt');
      return result;
    } catch (e) {
      debugPrint('androidSdkInt failed: $e');
      return null;
    }
  }

  static Future<bool> openBackgroundLocationSettings() async {
    if (!_canUseNativeChannel) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('openBackgroundLocationSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('openBackgroundLocationSettings failed: $e');
      return false;
    }
  }

  static Future<bool> requestBackgroundLocationNative() async {
    if (!_canUseNativeChannel) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestBackgroundLocationNative');
      return result ?? false;
    } catch (e) {
      debugPrint('requestBackgroundLocationNative failed: $e');
      return false;
    }
  }
}
