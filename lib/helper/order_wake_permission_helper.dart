import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quiksee_vendor_app/helper/app_foreground_helper.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderWakePermissionHelper {
  static const Duration _settingsGap = Duration(milliseconds: 900);

  static Future<void> ensureAlertsActive() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await AppForegroundHelper.scheduleOrderWatchdog();
  }

  static Future<void> requestAll({bool force = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    final setupVersion = prefs.getInt(AppConstants.orderWakeSetupVersion) ?? 0;
    final needsSetup =
        force || setupVersion < AppConstants.currentOrderWakeSetupVersion;

    await Permission.notification.request();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    if (needsSetup) {
      if (!await AppForegroundHelper.isBatteryOptimizationIgnored()) {
        await Permission.ignoreBatteryOptimizations.request();
        await AppForegroundHelper.requestBatteryOptimizationExemption();
        await Future<void>.delayed(_settingsGap);
      }

      await AppForegroundHelper.openBatterySettings();
      await Future<void>.delayed(_settingsGap);

      await AppForegroundHelper.openManufacturerAutoStartSettings();
      await Future<void>.delayed(_settingsGap);

      await AppForegroundHelper.openAppNotificationSettings();

      await prefs.setInt(
        AppConstants.orderWakeSetupVersion,
        AppConstants.currentOrderWakeSetupVersion,
      );
    }

    await ensureAlertsActive();
  }
}
