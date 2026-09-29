import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/features/auth/controllers/registration_controller.dart';
import 'package:quiksee/features/auth/domain/registration_validators.dart';
import 'package:quiksee/features/auth/screens/login_screen.dart';
import 'package:quiksee/features/auth/screens/registration_otp_screen.dart';
import 'package:quiksee/features/auth/screens/registration_success_screen.dart';
import 'package:quiksee/features/auth/widgets/code_picker_widget.dart';
import 'package:quiksee/features/auth/widgets/registration_form_field.dart';
import 'package:quiksee/features/auth/widgets/registration_pass_view.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const Color _brandGold = Color(0xFFA36A00);
  static const Color _brandGreen = Color(0xFF1B5E20);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _initialDialCode;

  @override
  void initState() {
    super.initState();
    final splash = Get.find<SplashController>();
    _initialDialCode = CountryCode.fromCountryCode(
      splash.configModel?.countryCode ?? 'IN',
    ).dialCode;
    final controller = Get.find<RegistrationController>();
    controller.updateCountryDialCode(_initialDialCode!);
    controller.loadConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Get.back(),
        ),
        title: Text('driver_registration'.tr,
            style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
        centerTitle: true,
      ),
      body: GetBuilder<RegistrationController>(
        builder: (controller) {
          if (controller.isLoadingConfig) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            );
          }

          if (controller.registrationDisabled) {
            return _buildClosedState(context, controller);
          }

          if (controller.config == null) {
            return _buildErrorState(context, controller);
          }

          return Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
              children: [
                _buildHeroHeader(context),
                SizedBox(height: Dimensions.paddingSizeLarge),
                _buildSection(
                  context,
                  icon: Icons.person_outline,
                  title: 'personal_information'.tr,
                  child: Column(children: [
                    RegistrationFormField(
                      hint: 'first_name'.tr,
                      controller: controller.fNameController,
                      inputType: TextInputType.name,
                      maxLength: RegistrationValidators.nameMaxLength,
                      validator: RegistrationValidators.firstName,
                    ),
                    SizedBox(height: Dimensions.paddingSizeDefault),
                    RegistrationFormField(
                      hint: 'last_name'.tr,
                      controller: controller.lNameController,
                      inputType: TextInputType.name,
                      maxLength: RegistrationValidators.nameMaxLength,
                      validator: RegistrationValidators.lastName,
                    ),
                    SizedBox(height: Dimensions.paddingSizeDefault),
                    RegistrationFormField(
                      hint: 'email_address'.tr,
                      controller: controller.emailController,
                      inputType: TextInputType.emailAddress,
                      validator: RegistrationValidators.email,
                      onChanged: (_) => controller.invalidateOtpVerification(),
                    ),
                    SizedBox(height: Dimensions.paddingSizeDefault),
                    _buildPhoneField(context, controller),
                  ]),
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
                _buildSection(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'delivery_area'.tr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDropdown<String>(
                        value: controller.selectedCity,
                        hint: 'select_city'.tr,
                        items: controller.config!.cities
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: rubikRegular),
                                ))
                            .toList(),
                        onChanged: controller.setCity,
                      ),
                      if (controller.zonesForSelectedCity.isNotEmpty) ...[
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('select_pincodes_optional'.tr,
                            style: rubikRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor)),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.zonesForSelectedCity.map((zone) {
                            final selected =
                                controller.selectedZoneIds.contains(zone.id);
                            return FilterChip(
                              label: Text(zone.label,
                                  style: rubikRegular.copyWith(fontSize: 12)),
                              selected: selected,
                              selectedColor:
                                  Theme.of(context).primaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                              checkmarkColor: Theme.of(context).primaryColor,
                              onSelected: (_) =>
                                  controller.toggleZone(zone.id),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
                _buildSection(
                  context,
                  icon: Icons.badge_outlined,
                  title: 'identity_documents'.tr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.config!.identityTypes.isNotEmpty)
                        _buildDropdown<String>(
                          value: controller.selectedIdentityType,
                          hint: 'select_identity_type'.tr,
                          items: controller.config!.identityTypes
                              .map((t) => DropdownMenuItem(
                                    value: t.value,
                                    child: Text(t.label, style: rubikRegular),
                                  ))
                              .toList(),
                          onChanged: controller.setIdentityType,
                        ),
                      SizedBox(height: Dimensions.paddingSizeDefault),
                      RegistrationFormField(
                        hint: 'identity_number'.tr,
                        controller: controller.identityNumberController,
                        maxLength: RegistrationValidators.identityNumberMaxLength,
                        validator: RegistrationValidators.identityNumber,
                      ),
                      SizedBox(height: Dimensions.paddingSizeDefault),
                      RegistrationFormField(
                        hint: 'your_address'.tr,
                        controller: controller.addressController,
                        maxLines: 2,
                        maxLength: RegistrationValidators.addressMaxLength,
                        validator: RegistrationValidators.address,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
                _buildSection(
                  context,
                  icon: Icons.photo_camera_outlined,
                  title: 'upload_documents'.tr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('profile_photo'.tr,
                          style: rubikMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall)),
                      SizedBox(height: Dimensions.paddingSizeSmall),
                      Center(
                        child: GestureDetector(
                          onTap: controller.pickProfileImage,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: controller.profilePhotoError != null
                                    ? Colors.red
                                    : Theme.of(context).primaryColor,
                                width: 2,
                              ),
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.05),
                            ),
                            child: controller.profileImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(controller.profileImage!.path),
                                      fit: BoxFit.cover,
                                      width: 110,
                                      height: 110,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo,
                                          color: Theme.of(context)
                                              .primaryColor,
                                          size: 32),
                                      SizedBox(
                                          height: Dimensions.paddingSizeSmall),
                                      Text('add_photo'.tr,
                                          style: rubikRegular.copyWith(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .hintColor)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      if (controller.profilePhotoError != null) ...[
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          controller.profilePhotoError!,
                          style: rubikRegular.copyWith(
                            color: Colors.red,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ],
                      SizedBox(height: Dimensions.paddingSizeLarge),
                      Text('identity_proof_photos'.tr,
                          style: rubikMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall)),
                      SizedBox(height: Dimensions.paddingSizeSmall),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...controller.identityImages
                              .asMap()
                              .entries
                              .map((entry) => _identityThumb(
                                    context,
                                    entry.value.path,
                                    () => controller
                                        .removeIdentityImage(entry.key),
                                  )),
                          if (controller.identityImages.length <
                              AppConstants.limitOfPickedIdentityImageNumber)
                            _addIdentityButton(context, controller),
                        ],
                      ),
                      if (controller.identityPhotoError != null) ...[
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          controller.identityPhotoError!,
                          style: rubikRegular.copyWith(
                            color: Colors.red,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ],
                      SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        '${'allowed_formats'.tr}: ${controller.config!.allowedImageFormats} • ${'max'.tr} ${controller.config!.maxImageSizeMb} ${'mb'.tr}',
                        style: rubikRegular.copyWith(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
                _buildSection(
                  context,
                  icon: Icons.lock_outline,
                  title: 'password'.tr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegistrationFormField(
                        hint: 'password_hint'.tr,
                        controller: controller.passwordController,
                        isPassword: true,
                        onChanged: (value) {
                          if (value.isNotEmpty && !controller.showPassView) {
                            controller.showHidePass();
                          } else if (value.isEmpty && controller.showPassView) {
                            controller.showHidePass();
                          }
                          controller.validPassCheck(value);
                        },
                        validator: (value) =>
                            RegistrationValidators.password(value, controller),
                      ),
                      if (controller.showPassView)
                        const RegistrationPassView(),
                      SizedBox(height: Dimensions.paddingSizeDefault),
                      RegistrationFormField(
                        hint: 'confirm_password'.tr,
                        controller: controller.confirmPasswordController,
                        isPassword: true,
                        validator: (value) => RegistrationValidators
                            .confirmPassword(
                                value, controller.passwordController.text),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: controller.showHidePass,
                          child: Text(
                            controller.showPassView
                                ? 'hide_password_guide'.tr
                                : 'show_password_guide'.tr,
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: _brandGold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.config!.notes != null &&
                    controller.config!.notes!.isNotEmpty) ...[
                  SizedBox(height: Dimensions.paddingSizeDefault),
                  Container(
                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSizeSmall),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.amber.shade800, size: 20),
                        SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Text(
                            controller.config!.notes!,
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: Dimensions.paddingSizeExtraLarge),
                !controller.isSubmitting && !controller.isSendingOtp
                    ? QuikseeButtonWidget(
                        btnTxt: _submitButtonText(controller),
                        onTap: () => _onSubmit(controller),
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                SizedBox(height: Dimensions.paddingSizeDefault),
                Center(
                  child: TextButton(
                    onPressed: () => Get.off(() => const LoginScreen()),
                    child: Text(
                      'already_have_account_login'.tr,
                      style: rubikRegular.copyWith(
                        color: _brandGold,
                        decoration: TextDecoration.underline,
                        decorationColor: _brandGold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandGreen, _brandGreen.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(Images.quikseeLogo, height: 56, fit: BoxFit.contain),
          SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'register_as_delivery_partner'.tr,
            textAlign: TextAlign.center,
            style: rubikMedium.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeLarge,
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            'registration_subtitle'.tr,
            textAlign: TextAlign.center,
            style: rubikRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'registration_help_toll_free'.tr,
            textAlign: TextAlign.center,
            style: rubikMedium.copyWith(
              color: _brandGold,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: Theme.of(context).primaryColor, size: 20),
            ),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Text(title,
                style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault)),
          ]),
          SizedBox(height: Dimensions.paddingSizeDefault),
          child,
        ],
      ),
    );
  }

  Widget _buildPhoneField(
      BuildContext context, RegistrationController controller) {
    final bool isLtr = Get.find<LocalizationController>().isLtr;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(Dimensions.topSpace),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.02),
      ),
      child: Stack(children: [
        Container(
          width: Dimensions.loginColor,
          height: 53,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.125),
            borderRadius: isLtr
                ? BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.topSpace),
                    bottomLeft: Radius.circular(Dimensions.topSpace),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(Dimensions.topSpace),
                    bottomRight: Radius.circular(Dimensions.topSpace),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: Dimensions.loginColor,
                child: CodePickerWidget(
                  dialogBackgroundColor: Theme.of(context).cardColor,
                  onChanged: (countryCode) {
                    controller.updateCountryDialCode(countryCode.dialCode!);
                    controller.invalidateOtpVerification();
                    _formKey.currentState?.validate();
                  },
                  initialSelection: controller.countryDialCode,
                  favorite: [controller.countryDialCode],
                  showDropDownButton: true,
                  padding: EdgeInsets.only(
                    right: Dimensions.paddingSizeDefault,
                  ),
                  showFlagMain: true,
                  flagWidth: 30,
                  textStyle: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isLtr ? 0 : Dimensions.paddingSizeSmall,
                    right: isLtr ? Dimensions.paddingSizeSmall : 0,
                  ),
                  child: TextFormField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: controller.phoneMaxLength,
                    onChanged: (_) => controller.invalidateOtpVerification(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        controller.phoneMaxLength,
                      ),
                    ],
                    validator: (value) => RegistrationValidators.phone(
                      value,
                      controller.countryDialCode,
                    ),
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'phone_without_country_code'.tr,
                      hintStyle: rubikRegular.copyWith(
                        color: Theme.of(context).hintColor,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                      border: InputBorder.none,
                      errorStyle: rubikRegular.copyWith(
                        color: Colors.red,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              Theme.of(Get.context!).primaryColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: rubikRegular),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _identityThumb(
      BuildContext context, String path, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addIdentityButton(
      BuildContext context, RegistrationController controller) {
    return GestureDetector(
      onTap: controller.pickIdentityImages,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        ),
        child: Icon(Icons.add, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildClosedState(
      BuildContext context, RegistrationController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey.shade400),
            SizedBox(height: Dimensions.paddingSizeLarge),
            Text('registration_closed'.tr,
                style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge)),
            SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              controller.configError ?? 'registration_closed_message'.tr,
              textAlign: TextAlign.center,
              style: rubikRegular.copyWith(color: Theme.of(context).hintColor),
            ),
            SizedBox(height: Dimensions.paddingSizeExtraLarge),
            QuikseeButtonWidget(
              btnTxt: 'go_to_login'.tr,
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, RegistrationController controller) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            SizedBox(height: Dimensions.paddingSizeLarge),
            Text(controller.configError ?? 'connection_to_api_server_failed'.tr,
                textAlign: TextAlign.center,
                style: rubikRegular),
            SizedBox(height: Dimensions.paddingSizeExtraLarge),
            QuikseeButtonWidget(
              btnTxt: 'retry'.tr,
              onTap: controller.loadConfig,
            ),
          ],
        ),
      ),
    );
  }

  String _submitButtonText(RegistrationController controller) {
    if (controller.config?.otpRequired == true) {
      return controller.config!.isEmailVerification
          ? 'verify_email_and_submit'.tr
          : 'verify_phone_and_submit'.tr;
    }
    return 'submit_application'.tr;
  }

  Future<void> _onSubmit(RegistrationController controller) async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final photoError = controller.validatePhotos();
    if (!isFormValid || photoError != null) {
      showQuikseeSnackBarWidget('please_fix_form_errors'.tr);
      return;
    }

    if (controller.config!.otpRequired) {
      controller.resetOtpState();
      final sendResult = await controller.sendRegistrationOtp();
      if (sendResult == null) return;
      if (!sendResult.isSuccess) {
        showQuikseeSnackBarWidget(
          sendResult.message ?? 'registration_failed'.tr,
        );
        return;
      }
      if (sendResult.debugOtp != null) {
        showQuikseeSnackBarWidget(
          'Debug OTP: ${sendResult.debugOtp}',
          isError: false,
        );
      }
      await Get.to(() => RegistrationOtpScreen(
            identity: sendResult.identity ?? _otpIdentityFallback(controller),
            isEmail: controller.config!.isEmailVerification,
          ));
      return;
    }

    await _completeRegistration(controller);
  }

  Future<void> _completeRegistration(RegistrationController controller) async {
    final result = await controller.submit();
    if (result == null) return;

    if (result.isSuccess) {
      Get.offAll(() => RegistrationSuccessScreen(message: result.message));
    } else {
      showQuikseeSnackBarWidget(result.message ?? 'registration_failed'.tr);
    }
  }

  String _otpIdentityFallback(RegistrationController controller) {
    if (controller.config!.isEmailVerification) {
      return controller.emailController.text.trim().toLowerCase();
    }
    final dial = controller.countryDialCode.replaceAll('+', '');
    return '+$dial${RegistrationValidators.normalizeNationalPhone(
      controller.phoneController.text.trim(),
      dial,
    )}';
  }
}
