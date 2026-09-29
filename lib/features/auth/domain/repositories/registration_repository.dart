import 'dart:io';

import 'package:get/get_connect/http/src/response/response.dart';
import 'package:http/http.dart' as http;
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/auth/domain/registration_validators.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationRepository {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  RegistrationRepository({
    required this.apiClient,
    required this.sharedPreferences,
  });

  Map<String, String> get _publicHeaders => {
        'Accept': 'application/json',
        AppConstants.localizationKey:
            sharedPreferences.getString(AppConstants.languageCode) ?? 'en',
      };

  Map<String, String> get _jsonHeaders => {
        ..._publicHeaders,
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Future<Response> sendRegistrationOtp({
    String? email,
    String? phone,
    String? countryCode,
    String? firstName,
  }) async {
    final Map<String, dynamic> body = {};
    if (email != null && email.isNotEmpty) {
      body['email'] = email.trim().toLowerCase();
    }
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    if (countryCode != null && countryCode.isNotEmpty) {
      body['country_code'] = countryCode.replaceAll('+', '');
    }
    if (firstName != null && firstName.isNotEmpty) {
      body['f_name'] = firstName;
    }
    return apiClient.postData(
      AppConstants.dmRegistrationSendOtpUri,
      body,
      headers: _jsonHeaders,
    );
  }

  Future<Response> verifyRegistrationOtp({
    required String identity,
    required String otp,
    String? email,
    String? phone,
    String? countryCode,
  }) async {
    final Map<String, dynamic> body = {
      'identity': identity.trim(),
      'otp': otp.trim(),
    };
    if (email != null && email.isNotEmpty) {
      body['email'] = email.trim().toLowerCase();
      body['identity'] = email.trim().toLowerCase();
    }
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
      body['country_code'] = countryCode?.replaceAll('+', '') ?? '91';
    }
    return apiClient.postData(
      AppConstants.dmRegistrationVerifyOtpUri,
      body,
      headers: _jsonHeaders,
    );
  }

  Future<Response> getRegistrationConfig() async {
    return apiClient.getData(
      AppConstants.dmRegistrationConfigUri,
      headers: _publicHeaders,
    );
  }

  /// Registration multipart submit.
  /// **Phone format (required):**
  /// - `phone` → national number only, e.g. `9876543210`
  /// - `country_code` → dial code without `+`, e.g. `91`
  /// - Do NOT send `+91`, `919876543210`, or `+919876543210` in `phone`
  ///   (backend builds full number from both fields).
  Future<Response> submitRegistration({
    required String fName,
    required String lName,
    required String email,
    required String dialCode,
    required String nationalPhone,
    required String password,
    required String city,
    required String profileImagePath,
    required List<String> identityImagePaths,
    List<int>? zoneIds,
    String? identityType,
    String? identityNumber,
    String? address,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.dmRegistrationUri}',
    );
    final cleanDialCode = dialCode.replaceAll('+', '');
    final cleanNationalPhone = RegistrationValidators.normalizeNationalPhone(
      nationalPhone,
      cleanDialCode,
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_publicHeaders);

    request.fields.addAll({
      'f_name': fName,
      'l_name': lName,
      'email': email.trim().toLowerCase(),
      'phone': cleanNationalPhone,
      'country_code': cleanDialCode,
      'password': password,
      'delivery_cities': city,
      if (identityType != null && identityType.isNotEmpty)
        'identity_type': identityType,
      if (identityNumber != null && identityNumber.isNotEmpty)
        'identity_number': identityNumber,
      if (address != null && address.isNotEmpty) 'address': address,
    });

    if (zoneIds != null) {
      for (int i = 0; i < zoneIds.length; i++) {
        request.fields['delivery_zone_ids[$i]'] = zoneIds[i].toString();
      }
    }

    final profileFile = File(profileImagePath);
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      profileImagePath,
      filename: profileFile.path.split('/').last,
    ));

    for (final path in identityImagePaths) {
      final file = File(path);
      request.files.add(await http.MultipartFile.fromPath(
        'identity_image[]',
        path,
        filename: file.path.split('/').last,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return apiClient.handleResponse(response, uri.toString());
  }
}
