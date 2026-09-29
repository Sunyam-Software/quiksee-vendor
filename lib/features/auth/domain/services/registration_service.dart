import 'package:quiksee/data/models/response/error_response.dart';
import 'package:quiksee/features/auth/domain/models/registration_config_model.dart';
import 'package:quiksee/features/auth/domain/models/registration_otp_result.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/auth/domain/repositories/registration_repository.dart';

class RegistrationService {
  final RegistrationRepository registrationRepository;

  RegistrationService({required this.registrationRepository});

  Future<({RegistrationConfigModel? config, bool disabled, String? message})>
      getRegistrationConfig() async {
    final response =
        await registrationRepository.getRegistrationConfig();

    if (response.statusCode == 403 &&
        response.body is Map &&
        response.body['registration_enabled'] == false) {
      return (
        config: null,
        disabled: true,
        message: response.body['message']?.toString() ?? 'Access denied',
      );
    }

    if (response.statusCode == 200 && response.body is Map) {
      return (
        config: RegistrationConfigModel.fromJson(response.body),
        disabled: false,
        message: null,
      );
    }

    return (
      config: null,
      disabled: false,
      message: response.statusText ?? 'Failed to load registration form',
    );
  }

  Future<RegistrationOtpSendResult> sendRegistrationOtp({
    required bool isEmailVerification,
    required String firstName,
    String? email,
    String? phone,
    String? dialCode,
  }) async {
    final response = await registrationRepository.sendRegistrationOtp(
      email: isEmailVerification ? email : null,
      phone: isEmailVerification ? null : phone,
      countryCode: isEmailVerification ? null : dialCode,
      firstName: firstName.isNotEmpty ? firstName : null,
    );

    if (response.body is Map) {
      final body = Map<String, dynamic>.from(response.body as Map);
      if (response.statusCode == 200 && _isOkStatus(body['status'])) {
        return RegistrationOtpSendResult.fromJson(body);
      }
      return RegistrationOtpSendResult(
        isSuccess: false,
        message: _messageFromBody(body) ?? response.statusText,
        resendAfter: body['resend_after'] is int
            ? body['resend_after']
            : int.tryParse(body['resend_after']?.toString() ?? '') ?? 60,
      );
    }

    return RegistrationOtpSendResult(
      isSuccess: false,
      message: response.statusText ?? 'OTP send failed',
    );
  }

  Future<RegistrationOtpVerifyResult> verifyRegistrationOtp({
    required String identity,
    required String otp,
    String? email,
    String? phone,
    String? dialCode,
  }) async {
    final response = await registrationRepository.verifyRegistrationOtp(
      identity: identity,
      otp: otp,
      email: email,
      phone: phone,
      countryCode: dialCode,
    );

    if (response.body is Map) {
      final body = Map<String, dynamic>.from(response.body as Map);
      if (response.statusCode == 200 && _isOkStatus(body['status'])) {
        return RegistrationOtpVerifyResult.fromJson(body);
      }
      return RegistrationOtpVerifyResult(
        isSuccess: false,
        message: _messageFromBody(body) ?? response.statusText,
        identity: body['identity']?.toString(),
      );
    }

    return RegistrationOtpVerifyResult(
      isSuccess: false,
      message: response.statusText ?? 'Invalid OTP',
    );
  }

  Future<ResponseModel> submitRegistration({
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
    final response = await registrationRepository.submitRegistration(
      fName: fName,
      lName: lName,
      email: email,
      dialCode: dialCode,
      nationalPhone: nationalPhone,
      password: password,
      city: city,
      profileImagePath: profileImagePath,
      identityImagePaths: identityImagePaths,
      zoneIds: zoneIds,
      identityType: identityType,
      identityNumber: identityNumber,
      address: address,
    );

    if (response.statusCode == 201 &&
        response.body is Map &&
        _isOkStatus(response.body['status'])) {
      return ResponseModel(
        true,
        response.body['message']?.toString(),
      );
    }

    if (response.body is Map) {
      final body = Map<String, dynamic>.from(response.body as Map);

      if (body['error_code'] == 'verification_required') {
        return ResponseModel(
          false,
          body['message']?.toString(),
          verificationRequired: true,
        );
      }

      if (body['errors'] != null) {
        final errorResponse = ErrorResponse.fromJson(body);
        final messages = errorResponse.errors
                ?.map((e) => e.message)
                .whereType<String>()
                .join('\n') ??
            response.statusText;
        return ResponseModel(false, messages);
      }

      if (body['status'] == 0 && body['message'] != null) {
        return ResponseModel(false, body['message']?.toString());
      }
    }

    return ResponseModel(false, response.statusText ?? 'Registration failed');
  }

  String? _messageFromBody(Map<String, dynamic> body) {
    if (body['validation_errors'] is List) {
      final errors = body['validation_errors'] as List;
      if (errors.isNotEmpty && errors.first is Map) {
        return (errors.first as Map)['message']?.toString();
      }
    }
    return body['message']?.toString();
  }

  static bool _isOkStatus(dynamic status) =>
      status == 1 || status == '1' || status == true;
}
