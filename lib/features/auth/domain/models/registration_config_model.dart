class RegistrationConfigModel {
  final bool registrationEnabled;
  final String registrationVerificationMethod;
  final String identityField;
  final bool otpRequired;
  final int otpLength;
  final int otpExpiryMinutes;
  final int otpResendSeconds;
  final String? otpHint;
  final List<IdentityTypeOption> identityTypes;
  final List<String> cities;
  final List<DeliveryZoneOption> deliveryZones;
  final int maxImageSizeMb;
  final String allowedImageFormats;
  final PasswordRules passwordRules;
  final String? notes;

  RegistrationConfigModel({
    required this.registrationEnabled,
    required this.registrationVerificationMethod,
    required this.identityField,
    required this.otpRequired,
    required this.otpLength,
    required this.otpExpiryMinutes,
    required this.otpResendSeconds,
    this.otpHint,
    required this.identityTypes,
    required this.cities,
    required this.deliveryZones,
    required this.maxImageSizeMb,
    required this.allowedImageFormats,
    required this.passwordRules,
    this.notes,
  });

  bool get isEmailVerification =>
      registrationVerificationMethod == 'email' || identityField == 'email';

  factory RegistrationConfigModel.fromJson(Map<String, dynamic> json) {
    final method =
        json['registration_verification_method']?.toString() ?? 'email';
    return RegistrationConfigModel(
      registrationEnabled: json['registration_enabled'] == true,
      registrationVerificationMethod: method,
      identityField: json['identity_field']?.toString() ??
          (method == 'email' ? 'email' : 'phone'),
      otpRequired: json['otp_required'] != false,
      otpLength: json['otp_length'] ?? 4,
      otpExpiryMinutes: json['otp_expiry_minutes'] ?? 2,
      otpResendSeconds: json['otp_resend_seconds'] ?? 60,
      otpHint: json['otp_hint']?.toString(),
      identityTypes: (json['identity_types'] as List? ?? [])
          .map((e) => IdentityTypeOption.fromJson(e))
          .toList(),
      cities: List<String>.from(json['cities'] ?? []),
      deliveryZones: (json['delivery_zones'] as List? ?? [])
          .map((e) => DeliveryZoneOption.fromJson(e))
          .toList(),
      maxImageSizeMb: json['max_image_size_mb'] ?? 20,
      allowedImageFormats: json['allowed_image_formats'] ?? '',
      passwordRules: PasswordRules.fromJson(json['password_rules'] ?? {}),
      notes: json['notes'],
    );
  }
}

class IdentityTypeOption {
  final String value;
  final String label;

  IdentityTypeOption({required this.value, required this.label});

  factory IdentityTypeOption.fromJson(Map<String, dynamic> json) {
    return IdentityTypeOption(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class DeliveryZoneOption {
  final int id;
  final String city;
  final String? area;
  final String? zipcode;
  final String label;

  DeliveryZoneOption({
    required this.id,
    required this.city,
    this.area,
    this.zipcode,
    required this.label,
  });

  factory DeliveryZoneOption.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneOption(
      id: json['id'],
      city: json['city'] ?? '',
      area: json['area'],
      zipcode: json['zipcode'],
      label: json['label'] ?? '',
    );
  }
}

class PasswordRules {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireDigit;
  final bool requireSpecialChar;
  final bool noSpaces;

  PasswordRules({
    required this.minLength,
    required this.requireUppercase,
    required this.requireLowercase,
    required this.requireDigit,
    required this.requireSpecialChar,
    required this.noSpaces,
  });

  factory PasswordRules.fromJson(Map<String, dynamic> json) {
    return PasswordRules(
      minLength: json['min_length'] ?? 8,
      requireUppercase: json['require_uppercase'] == true,
      requireLowercase: json['require_lowercase'] == true,
      requireDigit: json['require_digit'] == true,
      requireSpecialChar: json['require_special_char'] == true,
      noSpaces: json['no_spaces'] == true,
    );
  }
}
