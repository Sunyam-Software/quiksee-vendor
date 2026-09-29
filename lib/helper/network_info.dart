
import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/utill/app_constants.dart';

class NetworkInfo {
  final Connectivity connectivity;
  NetworkInfo(this.connectivity);

  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static Timer? _reconnectDebounce;
  static bool _lastConnected = true;
  static bool _isRecovering = false;
  static DateTime? _lastRecoveryAt;


  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    if (!(result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile))) {
      return false;
    }
    return _hasInternetReachability();
  }


  static void checkConnectivity(BuildContext context) {
    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((result) async {
      if (Get.find<SplashController>().firstTimeConnectionCheck) {
        Get.find<SplashController>().setFirstTimeConnectionCheck(false);
        _lastConnected = await _resolveConnected(result);
        return;
      }

      final isConnected = await _resolveConnected(result);
      final messengerContext = Get.context ?? context;
      final messenger = ScaffoldMessenger.maybeOf(messengerContext);
      if (messenger != null) {
        if (isConnected) {
          messenger.hideCurrentSnackBar();
        }
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: !isConnected ? Colors.red : Colors.green,
            duration: Duration(seconds: !isConnected ? 6 : 3),
            content: Text(
              !isConnected ? 'no_connection'.tr : 'connected'.tr,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      if (!_lastConnected && isConnected) {
        _scheduleRecovery();
      }
      _lastConnected = isConnected;
    });
  }

  static Future<bool> _resolveConnected(List<ConnectivityResult> result) async {
    final hasTransport = result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile);
    if (!hasTransport) return false;
    return _hasInternetReachability();
  }

  static Future<bool> _hasInternetReachability() async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.configUri}');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 5));
      request.followRedirects = true;
      final response = await request.close().timeout(const Duration(seconds: 5));
      final ok = response.statusCode >= 200 && response.statusCode < 500;
      await response.drain<void>();
      client.close(force: true);
      return ok;
    } catch (_) {
      return false;
    }
  }

  static void _scheduleRecovery() {
    _reconnectDebounce?.cancel();
    _reconnectDebounce = Timer(
      const Duration(seconds: 2),
      () => unawaited(_recoverAfterReconnect()),
    );
  }

  static Future<void> _recoverAfterReconnect() async {
    if (_isRecovering) return;
    final last = _lastRecoveryAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 15)) {
      return;
    }

    _isRecovering = true;
    _lastRecoveryAt = DateTime.now();
    try {
      if (Get.isRegistered<AuthController>() &&
          !Get.find<AuthController>().isLoggedIn()) {
        return;
      }

      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().getProfile(
          silent: true,
          isUpdate: true,
        );
      }
      if (Get.isRegistered<OrderController>()) {
        await Get.find<OrderController>().getCurrentOrders(
          promptAccept: false,
        );
      }
      if (Get.isRegistered<AssignmentController>()) {
        await Get.find<AssignmentController>().refreshAllOffers(
          showSheet: true,
        );
        await Get.find<AssignmentController>().sendIdleLocation();
      }
      if (Get.isRegistered<RiderController>()) {
        await Get.find<RiderController>().checkArrivalOnResume();
        await Get.find<RiderController>().pollExternalNavigationArrival();
      }
    } catch (_) {
    } finally {
      _isRecovering = false;
    }
  }
}
