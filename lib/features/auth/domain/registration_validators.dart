import 'package:get/get.dart';
import 'package:quiksee/features/auth/controllers/registration_controller.dart';

class RegistrationValidators {
  static const int nameMaxLength = 50;
  static const int identityNumberMaxLength = 30;
  static const int addressMaxLength = 500;

  /// Example (India): input `9876543210` or mistaken `919876543210` → `9876543210`
  /// Wrong: sending `+919876543210` in the API `phone` field.
  static String normalizeNationalPhone(String input, String dialCode) {
    String digits = input.replaceAll(RegExp(r'\D'), '');
    final code = dialCode.replaceAll('+', '');
    while (code.isNotEmpty &&
        digits.startsWith(code) &&
        digits.length > code.length) {
      digits = digits.substring(code.length);
    }
    if (digits.startsWith('0') && digits.length > 1) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }
    return digits;
  }

  static String? firstName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'first_name_is_required'.tr;
    }
    if (text.length > nameMaxLength) {
      return 'name_max_50_characters'.tr;
    }
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(text)) {
      return 'name_only_letters'.tr;
    }
    return null;
  }

  static String? lastName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'last_name_is_required'.tr;
    }
    if (text.length > nameMaxLength) {
      return 'name_max_50_characters'.tr;
    }
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(text)) {
      return 'name_only_letters'.tr;
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'email_address_is_required'.tr;
    }
    if (!GetUtils.isEmail(text)) {
      return 'please_enter_a_valid_email_address'.tr;
    }
    return null;
  }

  static String? phone(String? value, String dialCode) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'phone_number_is_required'.tr;
    }
    final national = normalizeNationalPhone(text, dialCode);
    final code = dialCode.replaceAll('+', '');

    if (code == '91') {
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(national)) {
        return 'enter_valid_10_digit_mobile'.tr;
      }
      return null;
    }

    if (national.length < 4 || national.length > 15) {
      return 'input_valid_phone_number'.tr;
    }
    return null;
  }

  static String? identityNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > identityNumberMaxLength) {
      return 'identity_number_max_30'.tr;
    }
    return null;
  }

  static String? address(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > addressMaxLength) {
      return 'address_max_500_characters'.tr;
    }
    return null;
  }

  static String? password(String? value, RegistrationController controller) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'password_is_required'.tr;
    }
    controller.validPassCheck(text, isUpdate: false);
    if (!controller.isPasswordValid()) {
      return 'enter_valid_password'.tr;
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'confirm_password_is_required'.tr;
    }
    if (text != password) {
      return 'passwords_do_not_match'.tr;
    }
    return null;
  }
}
