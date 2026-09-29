import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';

class AppLaunchHelper {
  static const String packageName = 'com.quiksee.vendor';
  static const String wakeAction = 'in.quiksee.vendor.WAKE_FOR_ORDER';
  static const String stopAlertAction = 'in.quiksee.vendor.STOP_ORDER_ALERT';

  static Future<void> launchApp({int? orderId}) async {
    if (kIsWeb || !Platform.isAndroid) return;

    await _wakeAndLaunch(orderId: orderId);
    await _launchMainActivity(orderId: orderId);
  }

  static Future<void> stopOrderAlert({int? orderId}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final intent = AndroidIntent(
        action: stopAlertAction,
        package: packageName,
        componentName: '$packageName.OrderWakeReceiver',
        arguments: <String, dynamic>{
          if (orderId != null && orderId > 0) 'order_id': orderId,
        },
      );
      await intent.sendBroadcast();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppLaunchHelper.stopOrderAlert failed: $e');
      }
    }
  }

  static Future<void> _wakeAndLaunch({int? orderId}) async {
    try {
      final intent = AndroidIntent(
        action: wakeAction,
        package: packageName,
        componentName: '$packageName.OrderWakeReceiver',
        arguments: <String, dynamic>{
          if (orderId != null && orderId > 0) 'order_id': orderId,
        },
      );
      await intent.sendBroadcast();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppLaunchHelper wake broadcast failed: $e');
      }
    }
  }

  static Future<void> _launchMainActivity({int? orderId}) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: packageName,
        componentName: '$packageName.MainActivity',
        arguments: <String, dynamic>{
          'new_order_wake': true,
          if (orderId != null && orderId > 0) 'order_id': orderId,
        },
        flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_ACTIVITY_SINGLE_TOP,
          Flag.FLAG_ACTIVITY_REORDER_TO_FRONT,
          Flag.FLAG_ACTIVITY_CLEAR_TOP,
        ],
      );
      await intent.launch();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppLaunchHelper.launchApp failed: $e');
      }
    }
  }
}
