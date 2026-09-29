class RegistrationOtpSendResult {
  final bool isSuccess;
  final String? message;
  final String? identity;
  final int resendAfter;
  final String? debugOtp;

  RegistrationOtpSendResult({
    required this.isSuccess,
    this.message,
    this.identity,
    this.resendAfter = 60,
    this.debugOtp,
  });

  static bool _isOkStatus(dynamic status) =>
      status == 1 || status == '1' || status == true;

  factory RegistrationOtpSendResult.fromJson(Map<String, dynamic> json) {
    return RegistrationOtpSendResult(
      isSuccess: _isOkStatus(json['status']),
      message: json['message']?.toString(),
      identity: json['identity']?.toString(),
      resendAfter: json['resend_after'] is int
          ? json['resend_after']
          : int.tryParse(json['resend_after']?.toString() ?? '') ?? 60,
      debugOtp: json['debug_otp']?.toString(),
    );
  }
}

class RegistrationOtpVerifyResult {
  final bool isSuccess;
  final String? message;
  final String? identity;

  RegistrationOtpVerifyResult({
    required this.isSuccess,
    this.message,
    this.identity,
  });

  static bool _isOkStatus(dynamic status) =>
      status == 1 || status == '1' || status == true;

  static bool _isVerified(dynamic verified) =>
      verified == true || verified == 1 || verified == '1';

  factory RegistrationOtpVerifyResult.fromJson(Map<String, dynamic> json) {
    return RegistrationOtpVerifyResult(
      isSuccess: _isOkStatus(json['status']) &&
          (json['verified'] == null || _isVerified(json['verified'])),
      message: json['message']?.toString(),
      identity: json['identity']?.toString(),
    );
  }
}
