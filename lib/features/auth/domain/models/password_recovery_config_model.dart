class PasswordRecoveryConfigModel {
  final String forgotPasswordMethod;
  final String identityField;
  final int otpExpiryMinutes;

  PasswordRecoveryConfigModel({
    required this.forgotPasswordMethod,
    required this.identityField,
    required this.otpExpiryMinutes,
  });

  bool get isEmail => forgotPasswordMethod == 'email' || identityField == 'email';

  factory PasswordRecoveryConfigModel.fromJson(Map<String, dynamic> json) {
    return PasswordRecoveryConfigModel(
      forgotPasswordMethod: json['forgot_password_method']?.toString() ?? 'email',
      identityField: json['identity_field']?.toString() ?? 'email',
      otpExpiryMinutes: json['otp_expiry_minutes'] ?? 2,
    );
  }
}
