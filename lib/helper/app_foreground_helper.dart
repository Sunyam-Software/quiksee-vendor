import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quiksee_vendor_app/helper/app_launch_helper.dart';

class AppForegroundHelper {
  static const MethodChannel _channel =
      MethodChannel('in.quiksee.vendor/foreground');

  static Future<void> bringToForeground() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('bringToForeground');
    } catch (e) {
      debugPrint('bringToForeground failed: $e');
    }
  }

  static Future<void> wakeScreen() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('wakeScreen');
    } catch (e) {
      debugPrint('wakeScreen failed: $e');
    }
  }

  static Future<bool> requestBatteryOptimizationExemption() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('requestBatteryOptimizationExemption');
      return result ?? false;
    } catch (e) {
      debugPrint('requestBatteryOptimizationExemption failed: $e');
      return false;
    }
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> canUseFullScreenIntent() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final result = await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> openManufacturerAutoStartSettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('openManufacturerAutoStartSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('openManufacturerAutoStartSettings failed: $e');
      return false;
    }
  }

  static Future<bool> openAppNotificationSettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('openAppNotificationSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('openAppNotificationSettings failed: $e');
      return false;
    }
  }

  static Future<bool> openBatterySettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('openBatterySettings');
      return result ?? false;
    } catch (e) {
      debugPrint('openBatterySettings failed: $e');
      return false;
    }
  }

  static Future<void> scheduleOrderWatchdog() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('scheduleOrderWatchdog');
    } catch (e) {
      debugPrint('scheduleOrderWatchdog failed: $e');
    }
  }

  static Future<void> cancelOrderWatchdog() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancelOrderWatchdog');
    } catch (e) {
      debugPrint('cancelOrderWatchdog failed: $e');
    }
  }

  static Future<bool> openFullScreenIntentSettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final result =
          await _channel.invokeMethod<bool>('openFullScreenIntentSettings');
      return result ?? false;
    } catch (e) {
      debugPrint('openFullScreenIntentSettings failed: $e');
      return false;
    }
  }

  static Future<void> startNativeOrderAlert({int? orderId}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startNativeOrderAlert', <String, dynamic>{
        if (orderId != null && orderId > 0) 'order_id': orderId,
      });
    } catch (e) {

      debugPrint('startNativeOrderAlert failed: $e');
      try {
        await AppLaunchHelper.launchApp(orderId: orderId);
      } catch (_) {}
    }
  }

  static Future<void> stopNativeOrderAlert({int? orderId}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopNativeOrderAlert', <String, dynamic>{
        if (orderId != null && orderId > 0) 'order_id': orderId,
      });
    } catch (e) {
      debugPrint('stopNativeOrderAlert failed: $e');
      try {
        await AppLaunchHelper.stopOrderAlert(orderId: orderId);
      } catch (_) {}
    }
  }
}
