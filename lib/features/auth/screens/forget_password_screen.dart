import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_text_field_widget.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/auth/domain/registration_validators.dart';
import 'package:quiksee/features/auth/screens/otp_verification_screen.dart';
import 'package:quiksee/features/auth/widgets/code_picker_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _identityController = TextEditingController();
  final FocusNode _identityFocus = FocusNode();
  String? _countryDialCode = '+91';

  @override
  void initState() {
    super.initState();
    _countryDialCode = CountryCode.fromCountryCode(
      Get.find<SplashController>().configModel?.countryCode ?? 'IN',
    ).dialCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AuthController>().loadPasswordRecoveryConfig();
    });
  }

  @override
  void dispose() {
    _identityController.dispose();
    _identityFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: 'forget_password'.tr,
        isBack: true,
      ),
      body: GetBuilder<AuthController>(
        builder: (authController) {
          final bool isEmailMode = authController.isEmailRecovery;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            children: [
              if (authController.isLoadingRecoveryConfig)
                Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: LinearProgressIndicator(
                    color: Theme.of(context).primaryColor,
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  ),
                ),
              const QuikseeAssetImageWidget(
                Images.forgetPasswordScreenIcon,
                width: 120,
                height: 120,
              ),
              SizedBox(height: Dimensions.paddingSizeLarge),
              Text(
                isEmailMode
                    ? 'enter_email_for_password_reset'.tr
                    : 'enter_phone_number_for_password_reset'.tr,
                style: rubikRegular.copyWith(
                  color: Theme.of(context).hintColor,
                  fontSize: Dimensions.fontSizeDefault,
                ),
                textAlign: TextAlign.center,
              ),
              if (isEmailMode) ...[
                SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'check_your_email_for_otp'.tr,
                  style: rubikRegular.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: Dimensions.paddingSizeExtraLarge),
              isEmailMode
                  ? _buildEmailField(context)
                  : _buildPhoneField(context),
              SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'otp_will_expired_after_2_minute'.tr,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeExtraLarge),
              !authController.isLoading
                  ? QuikseeButtonWidget(
                      btnTxt: 'send_otp'.tr,
                      onTap: () => _sendOtp(authController, isEmailMode),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: QuikseeTextFieldWidget(
        hintText: 'enter_email_address'.tr,
        controller: _identityController,
        focusNode: _identityFocus,
        inputType: TextInputType.emailAddress,
        inputAction: TextInputAction.done,
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    final bool isLtr = Get.find<LocalizationController>().isLtr;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
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
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            SizedBox(
              width: Dimensions.loginColor,
              child: CodePickerWidget(
                dialogBackgroundColor: Theme.of(context).cardColor,
                onChanged: (countryCode) {
                  setState(() => _countryDialCode = countryCode.dialCode);
                },
                initialSelection: _countryDialCode,
                favorite: [_countryDialCode!],
                showDropDownButton: true,
                padding: EdgeInsets.zero,
                showFlagMain: true,
                textStyle: TextStyle(
                  color: Theme.of(context).textTheme.displayLarge?.color,
                ),
              ),
            ),
            Expanded(
              child: QuikseeTextFieldWidget(
                hintText: 'phone_without_country_code'.tr,
                controller: _identityController,
                focusNode: _identityFocus,
                noPadding: true,
                inputType: TextInputType.phone,
                inputAction: TextInputAction.done,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _sendOtp(
    AuthController authController,
    bool isEmailMode,
  ) async {
    final input = _identityController.text.trim();

    if (input.isEmpty) {
      showQuikseeSnackBarWidget(
        isEmailMode
            ? 'email_address_is_required'.tr
            : 'phone_number_is_required'.tr,
      );
      return;
    }

    String identity = input;
    if (isEmailMode) {
      if (!GetUtils.isEmail(input)) {
        showQuikseeSnackBarWidget('please_enter_a_valid_email_address'.tr);
        return;
      }
    } else {
      final dialCode = _countryDialCode!.replaceAll('+', '');
      identity = RegistrationValidators.normalizeNationalPhone(input, dialCode);
      if (identity.isEmpty) {
        showQuikseeSnackBarWidget('enter_phone_number'.tr);
        return;
      }
    }

    final value = await authController.forgotPassword(identity);
    if (value.statusCode == 200) {
      final savedIdentity = value.body is Map
          ? value.body['identity']?.toString() ?? identity
          : identity;
      authController.setRecoveryIdentity(savedIdentity);
      Get.to(() => VerificationScreen(
            identity: savedIdentity,
            isEmail: isEmailMode,
          ));
    }
  }
}
