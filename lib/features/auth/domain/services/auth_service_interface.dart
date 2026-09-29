import 'package:quiksee/features/auth/domain/models/password_recovery_config_model.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';

abstract class AuthServiceInterface {
  Future<ResponseModel> login(String countryCode, String phone, String password);
  Future<bool> saveUserToken(String token);
  Future<dynamic> updateToken();
  Future<dynamic> setLanguageCode(String currentLanguage);
  bool isLoggedIn();
  Future<bool> clearSharedData();
  void saveUserCredentials(String countryCode, String number, String password);
  String getUserEmail();
  String getUserPassword();
  String getUserToken();
  Future<bool> clearUserCredentials();
  Future<dynamic> forgotPassword(String? identity);
  Future<dynamic> verifyOtp(String otp, String? identity);
  Future<PasswordRecoveryConfigModel?> getPasswordRecoveryConfig();
  Future<dynamic> resetPassword({
    required String identity,
    required String otp,
    required String password,
    required String confirmPassword,
  });
  String getUserCountryCode();
}
