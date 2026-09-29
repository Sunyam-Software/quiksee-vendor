import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/auth/domain/models/registration_config_model.dart';
import 'package:quiksee/features/auth/domain/models/registration_otp_result.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/auth/domain/registration_validators.dart';
import 'package:quiksee/features/auth/domain/services/registration_service.dart';
import 'package:quiksee/helper/image_size_checker.dart';
import 'package:quiksee/utill/app_constants.dart';

class RegistrationController extends GetxController implements GetxService {
  final RegistrationService registrationService;

  RegistrationController({required this.registrationService});

  RegistrationConfigModel? config;
  bool isLoadingConfig = true;
  bool registrationDisabled = false;
  String? configError;

  bool isSubmitting = false;
  String countryDialCode = '+91';

  String? selectedCity;
  String? selectedIdentityType;
  final Set<int> selectedZoneIds = {};

  XFile? profileImage;
  final List<XFile> identityImages = [];
  String? profilePhotoError;
  String? identityPhotoError;

  bool showPassView = false;
  bool _lengthCheck = false;
  bool _numberCheck = false;
  bool _uppercaseCheck = false;
  bool _lowercaseCheck = false;
  bool _spatialCheck = false;
  bool _noSpaceCheck = true;

  String? otpIdentity;
  bool otpVerified = false;
  int resendAfterSeconds = 60;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  bool isSubmittingAfterOtp = false;
  String otpCode = '';

  bool get lengthCheck => _lengthCheck;
  bool get numberCheck => _numberCheck;
  bool get uppercaseCheck => _uppercaseCheck;
  bool get lowercaseCheck => _lowercaseCheck;
  bool get spatialCheck => _spatialCheck;
  bool get noSpaceCheck => _noSpaceCheck;

  final TextEditingController fNameController = TextEditingController();
  final TextEditingController lNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController identityNumberController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  List<DeliveryZoneOption> get zonesForSelectedCity {
    if (selectedCity == null || config == null) return [];
    return config!.deliveryZones
        .where((z) => z.city == selectedCity)
        .toList();
  }

  Future<void> loadConfig() async {
    isLoadingConfig = true;
    registrationDisabled = false;
    configError = null;
    update();

    final result = await registrationService.getRegistrationConfig();

    isLoadingConfig = false;
    if (result.disabled) {
      registrationDisabled = true;
      configError = result.message;
    } else if (result.config != null) {
      config = result.config;
      resetOtpState();
      if (config!.cities.isNotEmpty) {
        selectedCity = config!.cities.first;
      }
      if (config!.identityTypes.isNotEmpty) {
        selectedIdentityType = config!.identityTypes.first.value;
      }
    } else {
      configError = result.message;
    }
    update();
  }

  void updateCountryDialCode(String value) {
    countryDialCode = value;
    update();
  }

  void setCity(String? city) {
    selectedCity = city;
    selectedZoneIds.clear();
    update();
  }

  void setIdentityType(String? type) {
    selectedIdentityType = type;
    update();
  }

  void toggleZone(int zoneId) {
    if (selectedZoneIds.contains(zoneId)) {
      selectedZoneIds.remove(zoneId);
    } else {
      selectedZoneIds.add(zoneId);
    }
    update();
  }

  void showHidePass() {
    showPassView = !showPassView;
    update();
  }

  void validPassCheck(String pass, {bool isUpdate = true}) {
    _lengthCheck = pass.length >= (config?.passwordRules.minLength ?? 8);
    _lowercaseCheck = pass.contains(RegExp(r'[a-z]'));
    _uppercaseCheck = pass.contains(RegExp(r'[A-Z]'));
    _spatialCheck = pass.contains(RegExp(r'[.!@#$&*~^%]'));
    _numberCheck = pass.contains(RegExp(r'\d'));
    _noSpaceCheck = !pass.contains(' ');
    if (isUpdate) {
      update();
    }
  }

  int get phoneMaxLength {
    final code = countryDialCode.replaceAll('+', '');
    return code == '91' ? 10 : 15;
  }

  bool isPasswordValid() {
    return _lengthCheck &&
        _lowercaseCheck &&
        _uppercaseCheck &&
        _spatialCheck &&
        _numberCheck &&
        _noSpaceCheck;
  }

  Future<bool> _isImageWithinLimit(XFile file) async {
    final maxMb = config?.maxImageSizeMb ?? 20;
    final sizeMb = await ImageValidationHelper.getImageSizeFromXFile(file);
    return sizeMb <= maxMb;
  }

  Future<void> pickProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: AppConstants.imageQuality,
    );
    if (picked == null) return;

    if (!await _isImageWithinLimit(picked)) {
      final maxMb = config?.maxImageSizeMb ?? 20;
      showQuikseeSnackBarWidget(
        '${'file_size'.tr} ${'exceeds_maximum_allowed_size'.tr} ($maxMb ${'mb'.tr})',
      );
      return;
    }

    profileImage = picked;
    profilePhotoError = null;
    update();
  }

  Future<void> pickIdentityImages() async {
    final remaining =
        AppConstants.limitOfPickedIdentityImageNumber - identityImages.length;
    if (remaining <= 0) return;

    final picked = await ImagePicker().pickMultiImage(
      imageQuality: AppConstants.imageQuality,
    );
    if (picked.isEmpty) return;

    final maxMb = config?.maxImageSizeMb ?? 20;
    final validImages = <XFile>[];
    for (final file in picked.take(remaining)) {
      if (await _isImageWithinLimit(file)) {
        validImages.add(file);
      } else {
        showQuikseeSnackBarWidget(
          '${'file_size'.tr} ${'exceeds_maximum_allowed_size'.tr} ($maxMb ${'mb'.tr})',
        );
      }
    }

    if (validImages.isNotEmpty) {
      identityImages.addAll(validImages);
      identityPhotoError = null;
      update();
    }
  }

  void removeIdentityImage(int index) {
    if (index >= 0 && index < identityImages.length) {
      identityImages.removeAt(index);
      if (identityImages.isNotEmpty) {
        identityPhotoError = null;
      }
      update();
    }
  }

  String? validatePhotos() {
    profilePhotoError = null;
    identityPhotoError = null;

    if (profileImage == null) {
      profilePhotoError = 'please_add_profile_photo'.tr;
    }
    if (identityImages.isEmpty) {
      identityPhotoError = 'please_add_identity_photos'.tr;
    }

    if (profilePhotoError != null || identityPhotoError != null) {
      update();
      return profilePhotoError ?? identityPhotoError;
    }
    return null;
  }

  void resetOtpState() {
    otpIdentity = null;
    otpVerified = false;
    otpCode = '';
    resendAfterSeconds = config?.otpResendSeconds ?? 60;
  }

  void invalidateOtpVerification() {
    if (otpVerified || otpIdentity != null) {
      resetOtpState();
      update();
    }
  }

  void updateOtpCode(String code) {
    otpCode = code;
  }

  Future<ResponseModel?> submitAfterOtpVerified() async {
    if (config?.otpRequired == true && !otpVerified) {
      return ResponseModel(
        false,
        'otp_verification_required'.tr,
        verificationRequired: true,
      );
    }
    return submit();
  }

  Future<RegistrationOtpSendResult?> sendRegistrationOtp() async {
    if (config == null) return null;

    final fName = fNameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final dialCode = countryDialCode.replaceAll('+', '');
    final nationalPhone = RegistrationValidators.normalizeNationalPhone(
      phoneController.text.trim(),
      dialCode,
    );

    isSendingOtp = true;
    update();

    final result = await registrationService.sendRegistrationOtp(
      isEmailVerification: config!.isEmailVerification,
      firstName: fName,
      email: email,
      phone: nationalPhone,
      dialCode: dialCode,
    );

    isSendingOtp = false;
    if (result.isSuccess) {
      otpIdentity = config!.isEmailVerification
          ? (result.identity ?? email).trim().toLowerCase()
          : (result.identity ?? otpIdentity)?.trim();
      resendAfterSeconds = result.resendAfter;
      otpVerified = false;
    }
    update();
    return result;
  }

  Future<RegistrationOtpVerifyResult?> verifyRegistrationOtp(
    String otp, {
    String? identityOverride,
  }) async {
    final identity = _resolveVerifyIdentity(identityOverride);
    if (identity.isEmpty) {
      return RegistrationOtpVerifyResult(
        isSuccess: false,
        message: 'otp_verification_required'.tr,
      );
    }

    otpIdentity = identity;

    isVerifyingOtp = true;
    update();

    final dialCode = countryDialCode.replaceAll('+', '');
    final nationalPhone = RegistrationValidators.normalizeNationalPhone(
      phoneController.text.trim(),
      dialCode,
    );

    final result = await registrationService.verifyRegistrationOtp(
      identity: identity,
      otp: otp.trim(),
      email: config!.isEmailVerification
          ? emailController.text.trim().toLowerCase()
          : null,
      phone: config!.isEmailVerification ? null : nationalPhone,
      dialCode: config!.isEmailVerification ? null : dialCode,
    );

    isVerifyingOtp = false;
    if (result.isSuccess) {
      otpVerified = true;
      if (result.identity != null && result.identity!.isNotEmpty) {
        otpIdentity = result.identity!.trim().toLowerCase();
      }
    }
    update();
    return result;
  }

  String _resolveVerifyIdentity(String? identityOverride) {
    if (config == null) return '';

    if (config!.isEmailVerification) {
      final raw = identityOverride ??
          otpIdentity ??
          emailController.text.trim();
      return raw.trim().toLowerCase();
    }

    return (identityOverride ?? otpIdentity ?? '').trim();
  }

  Future<ResponseModel?> submit() async {
    if (config?.otpRequired == true && !otpVerified) {
      return ResponseModel(
        false,
        'otp_verification_required'.tr,
        verificationRequired: true,
      );
    }

    final fName = fNameController.text.trim();
    final lName = lNameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();
    final dialCode = countryDialCode.replaceAll('+', '');
    final nationalPhone = RegistrationValidators.normalizeNationalPhone(
      phoneController.text.trim(),
      dialCode,
    );

    if (selectedCity == null || selectedCity!.isEmpty) {
      return ResponseModel(false, 'please_select_city'.tr);
    }

    final photoError = validatePhotos();
    if (photoError != null) {
      return ResponseModel(false, photoError);
    }

    isSubmitting = true;
    update();

    final result = await registrationService.submitRegistration(
      fName: fName,
      lName: lName,
      email: email,
      dialCode: dialCode,
      nationalPhone: nationalPhone,
      password: password,
      city: selectedCity!,
      profileImagePath: profileImage!.path,
      identityImagePaths: identityImages.map((e) => e.path).toList(),
      zoneIds:
          selectedZoneIds.isNotEmpty ? selectedZoneIds.toList() : null,
      identityType: selectedIdentityType,
      identityNumber: identityNumberController.text.trim().isNotEmpty
          ? identityNumberController.text.trim()
          : null,
      address: addressController.text.trim().isNotEmpty
          ? addressController.text.trim()
          : null,
    );

    isSubmitting = false;
    update();
    return result;
  }

  @override
  void onClose() {
    fNameController.dispose();
    lNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    identityNumberController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
