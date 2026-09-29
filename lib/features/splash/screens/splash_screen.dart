import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/maintenance/maintenance_screen.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/update/screen/update_screen.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/helper/network_info.dart';
import 'package:quiksee/helper/new_order_alert_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/common/basewidgets/app_splash_body.dart';
import 'package:quiksee/features/auth/screens/login_screen.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee/features/onboard/screens/onboarding_screen.dart';
import 'package:quiksee/features/permissions/screens/app_permissions_screen.dart';
import 'package:quiksee/helper/app_permissions_helper.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_binding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic));
    unawaited(
      FirebaseMessaging.instance.subscribeToTopic(AppConstants.maintenanceModeTopic),
    );
    // Starting Flutter ring here made audio play long before the offer UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NetworkInfo.checkConnectivity(context);
      unawaited(_softKeepNativeRing());
    });
    _route();
  }

  Future<void> _softKeepNativeRing() async {
    try {
      if (await NewOrderAlertHelper.isMuted()) return;
      final live = await NewOrderAlertHelper.isAlertLive();
      if (live || NewOrderAlertHelper.isActive) {
        await AppForegroundHelper.startNativeAlert(force: false);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final orderId = prefs.getInt(AppConstants.pendingWakeOrderId) ?? 0;
      final activeAt = prefs.getInt(AppConstants.newOrderAlertActiveAt);
      final recent = activeAt != null &&
          DateTime.now().millisecondsSinceEpoch - activeAt < 125 * 1000;
      if (orderId > 0 || recent) {
        await AppForegroundHelper.startNativeAlert(force: false);
      }
    } catch (_) {}
  }

  Future<void> _route() async {
    final splashController = Get.find<SplashController>();
    final authController = Get.find<AuthController>();
    final showIntro = splashController.showIntro() ?? false;

    await splashController.initSharedData();
    if (!mounted) return;

    // Fast path: use last config → leave splash immediately, refresh in background.
    final hasCache = splashController.loadCachedConfig();
    if (hasCache && mounted) {
      unawaited(splashController.getBusinessPagesList('default'));
      unawaited(splashController.getConfigData());
      await _navigateWithConfig(showIntro);
      return;
    }

    final isSuccess = await splashController.getConfigData();
    if (!mounted) return;

    if (isSuccess) {
      unawaited(splashController.getBusinessPagesList('default'));
      await _navigateWithConfig(showIntro);
    } else {
      await _navigateFallback(showIntro, authController.isLoggedIn());
    }
  }

  Future<void> _navigateWithConfig(bool showIntro) async {
    final config = Get.find<SplashController>().configModel;
    final appVersion = config?.deliveryManAppVersionControl;

    String minimumVersion = '0';
    if (Platform.isAndroid) {
      minimumVersion = appVersion?.forAndroid.version ?? '0';
    } else if (Platform.isIOS) {
      minimumVersion = appVersion?.forIos.version ?? '0';
    }

    if (compareVersions(minimumVersion, AppConstants.appVersion) == 1) {
      _replace(const UpdateScreen());
      return;
    }

    if (config?.maintenanceModeData?.maintenanceStatus == 1 &&
        config?.maintenanceModeData?.selectedMaintenanceSystem?.deliverymanApp == 1) {
      _replace(
        const MaintenanceScreen(),
        settings: const RouteSettings(name: 'MaintenanceScreen'),
      );
      return;
    }

    final permissionsDone = await AppPermissionsHelper.isSetupCompleted();

    if (Get.find<AuthController>().isLoggedIn()) {
      if (!permissionsDone) {
        Get.offAll(
          () => const AppPermissionsScreen(
            nextRoute: AppPermissionsNextRoute.dashboard,
          ),
        );
        return;
      }
      _replace(const DashboardScreen(pageIndex: 0));
      _warmUpLoggedInSession();
      return;
    }

    if (showIntro) {
      Get.offAll(const OnBoardingScreen());
    } else if (!permissionsDone) {
      Get.offAll(() => const AppPermissionsScreen());
    } else {
      Get.offAll(const LoginScreen());
    }
  }

  Future<void> _navigateFallback(bool showIntro, bool isLoggedIn) async {
    final permissionsDone = await AppPermissionsHelper.isSetupCompleted();

    if (isLoggedIn) {
      if (!permissionsDone) {
        Get.offAll(
          () => const AppPermissionsScreen(
            nextRoute: AppPermissionsNextRoute.dashboard,
          ),
        );
        return;
      }
      Get.offAll(const DashboardScreen(pageIndex: 0));
      _warmUpLoggedInSession();
      return;
    }

    if (showIntro) {
      Get.offAll(const OnBoardingScreen());
    } else if (!permissionsDone) {
      Get.offAll(() => const AppPermissionsScreen());
    } else {
      Get.offAll(const LoginScreen());
    }
  }

  void _warmUpLoggedInSession() {
    OrderTransferBinding.ensure();
    unawaited(Get.find<AuthController>().updateToken());
    unawaited(Get.find<DistancePaymentController>().loadConfig(silent: true));
    Future.microtask(() {
      Get.find<ProfileController>().getProfile(silent: true);
    });
  }

  void _replace(Widget screen, {RouteSettings? settings}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen, settings: settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.expand(child: AppSplashBody()),
    );
  }

  int compareVersions(String version1, String version2) {
    final v1Components = version1.split('.');
    final v2Components = version2.split('.');

    final maxLength = v1Components.length > v2Components.length
        ? v1Components.length
        : v2Components.length;

    for (int i = 0; i < maxLength; i++) {
      final v1Part = i < v1Components.length ? int.tryParse(v1Components[i]) ?? 0 : 0;
      final v2Part = i < v2Components.length ? int.tryParse(v2Components[i]) ?? 0 : 0;

      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }

    return 0;
  }
}
