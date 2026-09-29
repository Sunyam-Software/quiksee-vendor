import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/chat/screens/inbox_screen.dart';
import 'package:quiksee_vendor_app/features/maintenance/maintenance_screen.dart';
import 'package:quiksee_vendor_app/features/notification/screens/notification_screen.dart';
import 'package:quiksee_vendor_app/features/order_details/screens/order_details_screen.dart';
import 'package:quiksee_vendor_app/features/product/screens/product_list_screen.dart';
import 'package:quiksee_vendor_app/features/refund/domain/models/refund_model.dart';
import 'package:quiksee_vendor_app/features/refund/screens/refund_details_screen.dart';
import 'package:quiksee_vendor_app/features/update/screen/update_screen.dart';
import 'package:quiksee_vendor_app/features/wallet/screens/wallet_screen.dart';
import 'package:quiksee_vendor_app/helper/network_info.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/helper/order_wake_permission_helper.dart';
import 'package:quiksee_vendor_app/features/notification/domain/models/notification_body.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:quiksee_vendor_app/features/auth/screens/auth_screen.dart';
import 'package:quiksee_vendor_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee_vendor_app/features/splash/widgets/quiksee_splash_widget.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBody? body;
  const SplashScreen({super.key, this.body});
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {

  static const Duration _maxSplashWait = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    Provider.of<AuthController>(Get.context!,listen: false).setUnAuthorize(false, update: false);
    initCall();
  }

  Future<void> initCall() async {
    NetworkInfo.checkConnectivity(context);
    final splashController = Provider.of<SplashController>(context, listen: false);

    try {
      await splashController.initConfig().timeout(_maxSplashWait);
    } on TimeoutException {

    }

    if (!mounted) return;

    if (splashController.configModel == null) {
      try {
        await splashController.initConfig().timeout(const Duration(seconds: 15));
      } on TimeoutException {

      }
    }

    if (!mounted) return;

    unawaited(splashController.getBusinessPagesList('default'));
    splashController.initShippingTypeList(context, '');

    await _navigateFromSplash();
  }

  Future<void> _navigateFromSplash() async {
    if (!mounted) return;

    final splashController = Provider.of<SplashController>(context, listen: false);

    await _waitForConfigIfNeeded(splashController);
    if (!mounted) return;

    final config = splashController.configModel;
    final appVersion = config?.sellerAppVersionControl;
    String minimumVersion = '0';

    if (Platform.isAndroid) {
      minimumVersion = appVersion?.forAndroid?.version ?? '0';
    } else if (Platform.isIOS) {
      minimumVersion = appVersion?.forIos?.version ?? '0';
    }

    final navigator = Navigator.of(context);

    if (compareVersions(minimumVersion, AppConstants.appVersion) == 1) {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const UpdateScreen()));
      return;
    }

    if (config?.maintenanceModeData?.maintenanceStatus == 1 &&
        config?.maintenanceModeData?.selectedMaintenanceSystem?.vendorApp == 1) {
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => const MaintenanceScreen(),
        settings: const RouteSettings(name: 'MaintenanceScreen'),
      ));
      return;
    }

    if (widget.body != null) {
      await _navigateFromNotification(navigator);
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    if (authController.isLoggedIn()) {
      await OrderWakePermissionHelper.requestAll();
      await OrderWakePermissionHelper.ensureAlertsActive();
      if (!mounted) return;
      authController.updateToken(context);
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  Future<void> _waitForConfigIfNeeded(SplashController splashController) async {
    if (splashController.configModel != null) return;

    const attempts = 30;
    for (var i = 0; i < attempts; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (splashController.configModel != null) return;
    }
  }

  Future<void> _navigateFromNotification(NavigatorState navigator) async {
    final notificationType = widget.body?.type ?? '';

    if (widget.body?.orderId != null &&
        (notificationType.toLowerCase() == 'order' ||
            notificationType.toLowerCase().contains('new_order') ||
            notificationType.toLowerCase().contains('place_order'))) {
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(
          orderId: int.parse(widget.body!.orderId.toString()),
          fromNotification: true,
        ),
      ));
      return;
    }

    switch (notificationType.toLowerCase()) {
      case 'chatting':
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => InboxScreen(
            fromNotification: true,
            initIndex: widget.body?.messageKey == 'message_from_delivery_man' ? 1 : 0,
          ),
        ));
        break;
      case 'theme':
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => const NotificationScreen()));
        break;
      case 'order':
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(
            orderId: int.parse(widget.body!.orderId.toString()),
            fromNotification: true,
          ),
        ));
        break;
      case 'wallet':
      case 'wallet_withdraw':
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => const WalletScreen(fromNotification: true)));
        break;
      case 'product_request_approved_message':
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => const ProductListMenuScreen(fromNotification: true)));
        break;
      case 'refund':
        navigator.pushReplacement(MaterialPageRoute(
          builder: (_) => RefundDetailsScreen(
            fromNotification: true,
            refundModel: RefundModel(id: widget.body!.refundId),
            orderDetailsId: widget.body!.orderDetailsId,
          ),
        ));
        break;
      default:
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => const NotificationScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const QuikseeSplashWidget();
  }

  int compareVersions(String version1, String version2) {
    List<String> v1Components = version1.split('.');
    List<String> v2Components = version2.split('.');

    int maxLength = v1Components.length > v2Components.length
        ? v1Components.length
        : v2Components.length;

    for (int i = 0; i < maxLength; i++) {
      int v1Part = i < v1Components.length ? int.tryParse(v1Components[i]) ?? 0 : 0;
      int v2Part = i < v2Components.length ? int.tryParse(v2Components[i]) ?? 0 : 0;

      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }

    return 0;
  }

}
