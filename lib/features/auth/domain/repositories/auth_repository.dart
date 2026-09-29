import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';


class AuthRepository implements AuthRepositoryInterface{
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  AuthRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response> login(String countryCode, String phone, String password) async {
    return await apiClient.postData(AppConstants.loginUri,
        {"country_code": '+$countryCode' ,"phone": phone, "password": password});
  }

  @override
  Future<Response> setLanguageCode(String languageCode) async {
    return await apiClient.postData(AppConstants.setCurrentLanguageUri,
        {"current_language": languageCode, '_method' : 'put' });
  }


  @override
  Future<bool> saveUserToken(String token) async {
    apiClient.token = token;
    apiClient.updateHeader(token, sharedPreferences.getString(AppConstants.languageCode));
    return await sharedPreferences.setString(AppConstants.token, token);
  }

  @override
  Future<Response> updateToken() async {
    String? deviceToken;
    try {
      if (GetPlatform.isIOS) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          deviceToken = await _saveDeviceToken();
        }
      } else {
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e) {
          debugPrint('FCM permission request failed: $e');
        }
        deviceToken = await _saveDeviceToken();
      }
      debugPrint('=========>Device Token ======$deviceToken');

      if (!GetPlatform.isWeb &&
          deviceToken != null &&
          deviceToken.isNotEmpty) {
        try {
          await FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic);
        } catch (e) {
          debugPrint('FCM subscribeToTopic failed: $e');
        }
      }

      if (deviceToken == null || deviceToken.isEmpty) {
        return const Response(statusCode: 200, statusText: 'FCM token skipped');
      }

      return await apiClient.postData(
        AppConstants.tokenUri,
        {'_method': 'put', 'fcm_token': deviceToken},
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'Bearer ${sharedPreferences.get(AppConstants.token)}',
        },
      );
    } catch (e) {
      debugPrint('updateToken failed (non-fatal): $e');
      return Response(statusCode: 200, statusText: 'FCM update skipped: $e');
    }
  }

  Future<String?> _saveDeviceToken() async {
    if (GetPlatform.isWeb) return '';
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken failed (non-fatal): $e');
      return '';
    }
  }

  @override
  String getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  @override
  bool isLoggedIn() {
    return sharedPreferences.containsKey(AppConstants.token);
  }

  @override
  Future<bool> clearSharedData() async {
    if(!GetPlatform.isWeb) {
      apiClient.postData(AppConstants.tokenUri, {"_method": "put", "fcm_token": 'no'});
    }
    await sharedPreferences.remove(AppConstants.token);
    return true;
  }

  @override
  Future<void> saveUserCredentials(String countryCode, String number, String password) async {
    try {
      await sharedPreferences.setString(AppConstants.userPassword, password);
      await sharedPreferences.setString(AppConstants.userEmail, number);
      await sharedPreferences.setString(AppConstants.userCountryCode, countryCode);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getUserEmail() {
    return sharedPreferences.getString(AppConstants.userEmail) ?? "";
  }

  @override
  String getUserPassword() {
    return sharedPreferences.getString(AppConstants.userPassword) ?? "";
  }


  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList() {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }

  Future<bool> clearUserEmailAndPassword() async {
    await sharedPreferences.remove(AppConstants.userPassword);
    return await sharedPreferences.remove(AppConstants.userEmail);
  }


  @override
  Future<bool> clearUserCredentials() async{
    await sharedPreferences.remove(AppConstants.userPassword);
    await sharedPreferences.remove(AppConstants.userCountryCode);
    return await sharedPreferences.remove(AppConstants.userEmail);
  }

  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        AppConstants.localizationKey:
            sharedPreferences.getString(AppConstants.languageCode) ?? 'en',
      };

  @override
  Future<Response> getPasswordRecoveryConfig() async {
    return apiClient.getData(
      AppConstants.dmPasswordRecoveryConfigUri,
      headers: _publicHeaders,
    );
  }

  @override
  Future<Response> forgotPassword(String? identity) async {
    final trimmed = identity?.trim() ?? '';
    return apiClient.postData(
      AppConstants.forgotPassword,
      {'identity': trimmed},
      headers: _publicHeaders,
    );
  }

  @override
  Future<Response> verifyOtp(String otp, String? identity) async {
    return apiClient.postData(
      AppConstants.verifyOtp,
      {
        'otp': otp.trim(),
        'identity': identity?.trim() ?? '',
      },
      headers: _publicHeaders,
    );
  }

  @override
  Future<Response> resetPassword({
    required String identity,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    return apiClient.postData(
      AppConstants.resetPassword,
      {
        'identity': identity.trim(),
        'otp': otp.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      },
      headers: _publicHeaders,
    );
  }

  @override
  String getUserCountryCode() {
    return sharedPreferences.getString(AppConstants.userCountryCode) ?? "";
  }

}
