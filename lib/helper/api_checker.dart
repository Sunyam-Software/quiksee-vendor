import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/data/model/response/base/error_response.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/auth/screens/auth_screen.dart';

class ApiChecker {
  static bool _handlingUnauthorized = false;

  static void checkApi(ApiResponse apiResponse,  {bool firebaseResponse = false}) {
    if (_isUnauthorized(apiResponse)) {

      if (_handlingUnauthorized) {
        return;
      }
      _handlingUnauthorized = true;
      try {
        final auth = Provider.of<AuthController>(Get.context!, listen: false);

        auth.clearSharedData(fromUnAuthorizationError: true, clearServerSession: false);

        if (auth.isUnAuthorize == false) {
          debugPrint("==401==>>Inside");
          try {
            Navigator.of(Get.context!).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
              (route) => false,
            );
          } catch (ex) {
            debugPrint("===RouteException==>>$ex");
          }
        }
        auth.setUnAuthorize(true, update: true);
      } finally {
        _handlingUnauthorized = false;
      }
    } else {
      String? errorMessage;
      if (apiResponse.error is String) {
        errorMessage = apiResponse.error.toString();
      } else if (apiResponse.error is ErrorResponse) {
        final errors = (apiResponse.error as ErrorResponse).errors;
        if (errors != null && errors.isNotEmpty) {
          errorMessage = errors.first.message;
        }
      } else {
        errorMessage = apiResponse.error?.toString();
      }
      if (kDebugMode) {
        print(errorMessage);
      }

      final lower = (errorMessage ?? '').toLowerCase();
      if (lower.contains('was cancelled') ||
          lower.contains('cancel') ||
          lower.contains('connection timeout') ||
          lower.contains('receive timeout') ||
          lower.contains('timed out')) {
        return;
      }
      if(errorMessage != ''){
        showQuikseeSnackBarWidget(firebaseResponse ? errorMessage?.replaceAll('_', ' ') : errorMessage, Get.context!, sanckBarType: SnackBarType.error);
      }
    }
  }

  static bool _isUnauthorized(ApiResponse apiResponse) {
    final err = apiResponse.error;
    if (err == null) {
      return false;
    }
    final text = err.toString().toLowerCase();
    if (text == 'unauthorized') {
      return true;
    }

    if (text.contains('auth-001') || text.contains('does not authorize you any more')) {
      return true;
    }
    return false;
  }
}
