import 'package:quiksee/interface/repository_interface.dart';

abstract class AuthRepositoryInterface implements RepositoryInterface {
  Future<dynamic> login(String countryCode, String phone, String password);
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
  Future<dynamic> verifyOtp(String otp ,String? identity);
  Future<dynamic> getPasswordRecoveryConfig();
  Future<dynamic> resetPassword({
    required String identity,
    required String otp,
    required String password,
    required String confirmPassword,
  });
  String getUserCountryCode();
}