import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/auth/domain/models/password_recovery_config_model.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:quiksee/features/auth/domain/services/auth_service_interface.dart';

class AuthService implements AuthServiceInterface {
  AuthRepositoryInterface authRepoInterface;
  AuthService({required this.authRepoInterface});

  @override
  Future<bool> clearSharedData() {
    return authRepoInterface.clearSharedData();
  }

  @override
  Future<bool> clearUserCredentials() {
    return authRepoInterface.clearUserCredentials();
  }

  @override
  String getUserEmail() {
    return authRepoInterface.getUserEmail();
  }

  @override
  String getUserPassword() {
    return authRepoInterface.getUserPassword();
  }

  @override
  String getUserToken() {
    return authRepoInterface.getUserToken();
  }

  @override
  bool isLoggedIn() {
    return authRepoInterface.isLoggedIn();
  }

  @override
  Future<ResponseModel> login(String countryCode, String phone, String password) async {
    Response response = await authRepoInterface.login(countryCode, phone, password);

    if (response.statusCode == 200) {
      await authRepoInterface.saveUserToken(response.body['token']);
      try {
        await authRepoInterface.updateToken();
      } catch (e) {
        // Token already saved; push registration can retry later.
      }
      return ResponseModel(true, 'successful');
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  void saveUserCredentials(String countryCode, String number, String password) {
    return authRepoInterface.saveUserCredentials(countryCode, number, password);
  }

  @override
  Future<bool> saveUserToken(String token) {
    return authRepoInterface.saveUserToken(token);
  }

  @override
  Future setLanguageCode(String currentLanguage) {
    return authRepoInterface.setLanguageCode(currentLanguage);
  }


  @override
  Future updateToken() {
    return authRepoInterface.updateToken();
  }

  @override
  Future<Response> forgotPassword(String? identity) async{
    Response _response = await authRepoInterface.forgotPassword(identity);
    if (_response.statusCode == 200) {
      showQuikseeSnackBarWidget(_response.body['message'], isError: false);
    } else {
      ApiChecker.checkApi(_response);
    }
    return _response;
  }

  @override
  Future<Response> verifyOtp(String otp, String? identity) async{
    Response _response = await authRepoInterface.verifyOtp(otp, identity);
    if (_response.statusCode == 200) {

      showQuikseeSnackBarWidget('otp_verified_successfully'.tr, isError: false);
    } else {
      ApiChecker.checkApi(_response);
    }
    return _response ;
  }

  @override
  Future<PasswordRecoveryConfigModel?> getPasswordRecoveryConfig() async {
    final response = await authRepoInterface.getPasswordRecoveryConfig();
    if (response.statusCode == 200 && response.body is Map) {
      return PasswordRecoveryConfigModel.fromJson(response.body);
    }
    return null;
  }

  @override
  Future<Response> resetPassword({
    required String identity,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await authRepoInterface.resetPassword(
      identity: identity,
      otp: otp,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (response.statusCode == 200) {
      showQuikseeSnackBarWidget(
        response.body['message']?.toString() ??
            'password_changed_successfully'.tr,
        isError: false,
      );
    } else {
      ApiChecker.checkApi(response);
    }
    return response;
  }

  @override
  String getUserCountryCode() {
    return authRepoInterface.getUserCountryCode();
  }


}