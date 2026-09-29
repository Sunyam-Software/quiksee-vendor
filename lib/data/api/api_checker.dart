
import 'package:get/get.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/helper/new_order_alert_helper.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/auth/screens/login_screen.dart';

class ApiChecker {
  static DateTime? _lastUnauthorizedRedirectAt;
  static DateTime? _lastNetworkSnackAt;
  static String? _lastNetworkSnackMessage;

  static bool _isTransientNetworkMessage(String message) {
    return message == ApiClient.noInternetMessage ||
        message == ApiClient.timeoutMessage ||
        message == ApiClient.requestFailedMessage ||
        message.toLowerCase().contains('internet connection') ||
        message.toLowerCase().contains('taking too long') ||
        message.toLowerCase().contains('could not reach server');
  }

  static void checkApi(Response response) {
    if (response.statusCode == 401) {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.isLoading || auth.loginInProgress) return;
      }

      final now = DateTime.now();
      if (_lastUnauthorizedRedirectAt != null &&
          now.difference(_lastUnauthorizedRedirectAt!) <
              const Duration(seconds: 3)) {
        return;
      }
      _lastUnauthorizedRedirectAt = now;

      if (Get.currentRoute == '/LoginScreen' ||
          Get.routing.current.contains('LoginScreen')) {
        return;
      }

      Get.find<SplashController>().removeSharedData();
      if (Get.currentRoute != '/LoginScreen') {
        Get.offAll(() => const LoginScreen());
      }
    } else {
      String? message;
      if (response.body is Map) {
        if (response.body['message'] != null) {
          message = response.body['message'].toString();
        } else if (response.body['errors'] is List &&
            (response.body['errors'] as List).isNotEmpty) {
          final first = (response.body['errors'] as List).first;
          if (first is Map && first['message'] != null) {
            message = first['message'].toString();
          }
        }
      }
      message ??= response.statusText;
      if (message != null && message.isNotEmpty) {
        if (_isTransientNetworkMessage(message)) {
          try {
            if (Get.isRegistered<AssignmentController>()) {
              final assignment = Get.find<AssignmentController>();
              if (assignment.isBackgroundSyncPaused ||
                  assignment.isOfferSheetOpen ||
                  assignment.isBusyWithOffer ||
                  NewOrderAlertHelper.isActive) {
                return;
              }
            }
          } catch (_) {}
          final now = DateTime.now();
          if (_lastNetworkSnackMessage == message &&
              _lastNetworkSnackAt != null &&
              now.difference(_lastNetworkSnackAt!) <
                  const Duration(seconds: 8)) {
            return;
          }
          _lastNetworkSnackMessage = message;
          _lastNetworkSnackAt = now;
        }
        showQuikseeSnackBarWidget(message);
      }
    }
  }
}
