import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/auth/screens/login_screen.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/helper/app_permissions_helper.dart';
import 'package:quiksee/utill/dimensions.dart';

enum AppPermissionsNextRoute { login, dashboard }

class AppPermissionsScreen extends StatefulWidget {
  final AppPermissionsNextRoute nextRoute;

  const AppPermissionsScreen({
    super.key,
    this.nextRoute = AppPermissionsNextRoute.login,
  });

  @override
  State<AppPermissionsScreen> createState() => _AppPermissionsScreenState();
}

class _AppPermissionsScreenState extends State<AppPermissionsScreen>
    with WidgetsBindingObserver {
  bool _isRequestingAll = false;
  bool _isFinishing = false;
  List<AppPermissionStatus> _statuses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    final statuses = await AppPermissionsHelper.checkAll();
    if (!mounted) return;
    setState(() => _statuses = statuses);
  }

  Future<void> _requestOne(AppPermissionKind kind) async {
    if (kind == AppPermissionKind.backgroundLocation) {
      await _requestBackgroundLocationWithGuide();
      await _refreshStatuses();
      return;
    }
    await AppPermissionsHelper.requestKind(kind);
    await _refreshStatuses();
  }

  Future<void> _requestBackgroundLocationWithGuide() async {
    if (!await AppPermissionsHelper.requestLocation()) {
      return;
    }
    if (await _isBackgroundGranted()) return;

    final needsStep = await AppForegroundHelper.needsBackgroundLocationStep();
    if (needsStep && mounted) {
      final open = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('permission_background_location_steps_title'.tr),
          content: Text('permission_background_location_steps_body'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('open_settings'.tr),
            ),
          ],
        ),
      );
      if (open != true) return;
    }

    await AppPermissionsHelper.requestBackgroundLocation();
  }

  Future<bool> _isBackgroundGranted() async {
    final list = await AppPermissionsHelper.checkAll();
    return list.any(
      (s) => s.kind == AppPermissionKind.backgroundLocation && s.granted,
    );
  }

  Future<void> _requestAll() async {
    setState(() => _isRequestingAll = true);
    await AppPermissionsHelper.requestNotifications();
    await AppPermissionsHelper.requestLocation();
    await _requestBackgroundLocationWithGuide();
    await AppPermissionsHelper.requestBatteryExemption();
    await AppPermissionsHelper.requestFullScreenIntent();
    await AppPermissionsHelper.requestOemBackground();
    await _refreshStatuses();
    if (!mounted) return;
    setState(() => _isRequestingAll = false);
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    _isFinishing = true;
    await AppPermissionsHelper.markSetupCompleted();
    if (!mounted) return;

    switch (widget.nextRoute) {
      case AppPermissionsNextRoute.dashboard:
        Get.offAll(() => const DashboardScreen(pageIndex: 0));
        _warmUpLoggedInSession();
        break;
      case AppPermissionsNextRoute.login:
        Get.offAll(() => const LoginScreen());
        break;
    }
  }

  void _warmUpLoggedInSession() {
    unawaited(Get.find<AuthController>().updateToken());
    unawaited(Get.find<DistancePaymentController>().loadConfig(silent: true));
    Future.microtask(() {
      Get.find<ProfileController>().getProfile(silent: true);
    });
  }

  bool get _allGranted =>
      _statuses.isNotEmpty && _statuses.every((s) => s.granted);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: Dimensions.paddingSizeLarge),
              Text(
                'permissions_setup_title'.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'permissions_setup_subtitle'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              SizedBox(height: Dimensions.paddingSizeLarge),
              Expanded(
                child: ListView(
                  children: [
                    _PermissionTile(
                      title: 'permission_notifications_title'.tr,
                      subtitle: 'permission_notifications_desc'.tr,
                      granted: _isGranted(AppPermissionKind.notifications),
                      onAllow: () => _requestOne(AppPermissionKind.notifications),
                    ),
                    _PermissionTile(
                      title: 'permission_location_title'.tr,
                      subtitle: 'permission_location_desc'.tr,
                      granted: _isGranted(AppPermissionKind.location),
                      onAllow: () => _requestOne(AppPermissionKind.location),
                    ),
                    _PermissionTile(
                      title: 'permission_background_location_title'.tr,
                      subtitle: 'permission_background_location_desc'.tr,
                      granted: _isGranted(AppPermissionKind.backgroundLocation),
                      onAllow: () =>
                          _requestOne(AppPermissionKind.backgroundLocation),
                    ),
                    _PermissionTile(
                      title: 'permission_battery_title'.tr,
                      subtitle: 'permission_battery_desc'.tr,
                      granted: _isGranted(AppPermissionKind.battery),
                      onAllow: () => _requestOne(AppPermissionKind.battery),
                    ),
                    _PermissionTile(
                      title: 'permission_fullscreen_title'.tr,
                      subtitle: 'permission_fullscreen_desc'.tr,
                      granted: _isGranted(AppPermissionKind.fullScreenIntent),
                      onAllow: () =>
                          _requestOne(AppPermissionKind.fullScreenIntent),
                    ),
                    if (_statuses.any(
                      (s) => s.kind == AppPermissionKind.oemBackground,
                    ))
                      _PermissionTile(
                        title: 'permission_oem_title'.tr,
                        subtitle: 'permission_oem_desc'.tr,
                        granted: _isGranted(AppPermissionKind.oemBackground),
                        onAllow: () =>
                            _requestOne(AppPermissionKind.oemBackground),
                      ),
                  ],
                ),
              ),
              if (!_allGranted) ...[
                OutlinedButton(
                  onPressed: _isRequestingAll ? null : _requestAll,
                  child: _isRequestingAll
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('allow_all_permissions'.tr),
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),
              ],
              ElevatedButton(
                onPressed: _isFinishing ? null : _finish,
                child: Text(
                  _allGranted ? 'continue'.tr : 'continue_anyway'.tr,
                ),
              ),
              SizedBox(height: Dimensions.paddingSizeDefault),
            ],
          ),
        ),
      ),
    );
  }

  bool _isGranted(AppPermissionKind kind) {
    return _statuses.any((s) => s.kind == kind && s.granted);
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onAllow;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onAllow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = granted ? Colors.green : theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              granted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: color,
            ),
            SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  if (!granted) ...[
                    SizedBox(height: Dimensions.paddingSizeSmall),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onAllow,
                        child: Text('allow'.tr),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
