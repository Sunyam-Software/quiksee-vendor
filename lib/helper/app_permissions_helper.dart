import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPermissionKind {
  notifications,
  location,
  backgroundLocation,
  battery,
  fullScreenIntent,
  oemBackground,
}

enum PermissionReminderLevel { none, recommended, required }

class AppPermissionStatus {
  final AppPermissionKind kind;
  final bool granted;

  const AppPermissionStatus({required this.kind, required this.granted});
}

class AppPermissionsHelper {
  static Future<bool> isSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.permissionsSetupCompleted) ?? false;
  }

  static Future<void> markSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.permissionsSetupCompleted, true);
  }

  static Future<List<AppPermissionStatus>> checkAll() async {
    final statuses = <AppPermissionStatus>[
      AppPermissionStatus(
        kind: AppPermissionKind.notifications,
        granted: await _hasNotificationPermission(),
      ),
      AppPermissionStatus(
        kind: AppPermissionKind.location,
        granted: await _hasLocationPermission(),
      ),
      AppPermissionStatus(
        kind: AppPermissionKind.backgroundLocation,
        granted: await _hasBackgroundLocationPermission(),
      ),
      AppPermissionStatus(
        kind: AppPermissionKind.battery,
        granted: await _hasBatteryExemption(),
      ),
      AppPermissionStatus(
        kind: AppPermissionKind.fullScreenIntent,
        granted: await _hasFullScreenIntent(),
      ),
    ];

    if (Platform.isAndroid) {
      statuses.add(
        AppPermissionStatus(
          kind: AppPermissionKind.oemBackground,
          granted: await _hasOemBackgroundSetup(),
        ),
      );
    }

    return statuses;
  }

  static Future<bool> areAllCriticalGranted() async {
    final statuses = await checkAll();
    return statuses.every((s) => s.granted);
  }

  static Future<bool> areMinimumOrderPermissionsGranted() async {
    return await _hasNotificationPermission() && await _hasLocationPermission();
  }

  static Future<PermissionReminderLevel> homeReminderLevel() async {
    if (!await areMinimumOrderPermissionsGranted()) {
      return PermissionReminderLevel.required;
    }
    if (!await areAllCriticalGranted()) {
      return PermissionReminderLevel.recommended;
    }
    return PermissionReminderLevel.none;
  }

  static Future<bool> shouldShowHomePermissionReminder() async {
    final level = await homeReminderLevel();
    if (level == PermissionReminderLevel.none) return false;
    if (level == PermissionReminderLevel.required) return true;

    final prefs = await SharedPreferences.getInstance();
    final dismissedAt = prefs.getInt(AppConstants.permissionReminderDismissedAt);
    if (dismissedAt == null) return true;
    final dismissed = DateTime.fromMillisecondsSinceEpoch(dismissedAt);
    return DateTime.now().difference(dismissed) >= const Duration(hours: 24);
  }

  static Future<void> dismissHomePermissionReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.permissionReminderDismissedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> requestNotifications() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }

    final status = await Permission.notification.request();
    if (status.isGranted) return true;

    final plugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await plugin?.requestNotificationsPermission();
    return androidGranted == true || status.isGranted;
  }

  static Future<bool> requestLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> requestBackgroundLocation() async {
    if (!Platform.isAndroid) return true;

    if (!await _hasLocationPermission()) {
      final ready = await requestLocation();
      if (!ready) return false;
    }

    if (await _nativeHasBackgroundLocation()) return true;

    // Android 10: permission_handler dialog sometimes works.
    try {
      final status = await Permission.locationAlways.request();
      if (status.isGranted) return true;
    } catch (_) {}

    final geo = await Geolocator.checkPermission();
    if (geo == LocationPermission.always) return true;

    // Native request (Android 10 dialog) or open Settings (Android 11+ / OEM).
    await AppForegroundHelper.requestBackgroundLocationNative();
    if (await _nativeHasBackgroundLocation()) return true;

    final sdk = await AppForegroundHelper.androidSdkInt();
    if (sdk != null && sdk >= 30) {
      return false;
    }

    await AppForegroundHelper.openBackgroundLocationSettings();
    return _nativeHasBackgroundLocation();
  }

  static Future<bool> requestBatteryExemption() async {
    if (!Platform.isAndroid) return true;
    await AppForegroundHelper.requestBatteryOptimizationExemption();
    return _hasBatteryExemption();
  }

  static Future<bool> requestOemBackground() async {
    if (!Platform.isAndroid) return true;
    await AppForegroundHelper.openOemAutostartSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.oemBackgroundSetupDone, true);
    return true;
  }

  static Future<bool> requestKind(AppPermissionKind kind) async {
    switch (kind) {
      case AppPermissionKind.notifications:
        return requestNotifications();
      case AppPermissionKind.location:
        return requestLocation();
      case AppPermissionKind.backgroundLocation:
        return requestBackgroundLocation();
      case AppPermissionKind.battery:
        return requestBatteryExemption();
      case AppPermissionKind.fullScreenIntent:
        return requestFullScreenIntent();
      case AppPermissionKind.oemBackground:
        return requestOemBackground();
    }
  }

  static Future<void> requestAllInOrder() async {
    await requestNotifications();
    await requestLocation();
    await requestBackgroundLocation();
    await requestBatteryExemption();
    await requestFullScreenIntent();
    if (Platform.isAndroid) {
      await requestOemBackground();
    }
  }

  static Future<bool> requestFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    if (await _hasFullScreenIntent()) return true;
    await AppForegroundHelper.requestFullScreenIntentPermission();
    return _hasFullScreenIntent();
  }

  static Future<bool> _hasNotificationPermission() async {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return (await Permission.notification.status).isGranted;
  }

  static Future<bool> _hasLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> _hasBackgroundLocationPermission() async {
    if (!Platform.isAndroid) return true;

    if (await _nativeHasBackgroundLocation()) return true;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) return true;

    try {
      return (await Permission.locationAlways.status).isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _nativeHasBackgroundLocation() async {
    if (!Platform.isAndroid) return true;
    try {
      return await AppForegroundHelper.hasBackgroundLocationPermission();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _hasBatteryExemption() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  static Future<bool> _hasFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    return AppForegroundHelper.canUseFullScreenIntent();
  }

  static Future<bool> _hasOemBackgroundSetup() async {
    if (!Platform.isAndroid) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.oemBackgroundSetupDone) ?? false;
  }
}
