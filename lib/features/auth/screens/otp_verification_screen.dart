import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/auth/screens/reset_password_screen.dart';

class VerificationScreen extends StatelessWidget {
  final String identity;
  final bool isEmail;

  const VerificationScreen({
    super.key,
    required this.identity,
    this.isEmail = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: 'verification'.tr,
        isBack: true,
        onTap: () => Navigator.pop(context),
      ),
      body: GetBuilder<AuthController>(
        builder: (authController) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                child: Text(
                  isEmail
                      ? 'please_enter_otp_sent_to_email'.tr
                      : 'please_enter_4_digit_code'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isEmail)
                Padding(
                  padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: Text(
                    identity,
                    style: rubikRegular.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Get.width / 7,
                  vertical: Dimensions.paddingSizeDefault,
                ),
                child: PinCodeTextField(
                  length: 4,
                  appContext: context,
                  obscureText: false,
                  showCursor: true,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.circle,
                    fieldHeight: 50,
                    fieldWidth: 50,
                    borderWidth: 1,
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
                    selectedColor: ColorHelper.darken(
                      Theme.of(context).primaryColor,
                      0.2,
                    ),
                    selectedFillColor: Colors.white,
                    inactiveFillColor: Get.isDarkMode
                        ? Theme.of(context).hintColor.withValues(alpha: 0.125)
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    inactiveColor: ColorHelper.darken(
                      Theme.of(context).primaryColor,
                      0.2,
                    ),
                    activeColor: ColorHelper.darken(
                      Theme.of(context).primaryColor,
                      0.1,
                    ),
                    activeFillColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.025),
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  onChanged: authController.updateVerificationCode,
                  beforeTextPaste: (text) => true,
                ),
              ),
              Text(
                'otp_will_expired_after_2_minute'.tr,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${'if_you_did_not_receive_a_code'.tr},'),
                InkWell(
                  onTap: () {
                    authController.forgotPassword(identity).then((value) {
                      if (value.statusCode == 200) {
                        showQuikseeSnackBarWidget(
                          'otp_send_successfully'.tr,
                          isError: false,
                        );
                      }
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: Dimensions.paddingSizeSmall,
                    ),
                    child: Text(
                      'resend'.tr,
                      style: rubikMedium.copyWith(
                        color: Get.isDarkMode
                            ? Theme.of(context).hintColor
                            : Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 50),
              !authController.willPhoneNumberVerificationButtonLoading
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                      ),
                      child: QuikseeButtonWidget(
                        btnTxt: 'verify'.tr,
                        onTap: () {
                          if (authController.verificationCode.length < 4) {
                            showQuikseeSnackBarWidget('input_valid_otp'.tr);
                            return;
                          }
                          authController
                              .verifyOtp(
                                authController.verificationCode,
                                identity,
                              )
                              .then((value) {
                            if (value.statusCode == 200) {
                              Get.to(() => ResetPasswordWidget(
                                    identity: identity,
                                    otp: authController.verificationCode,
                                  ));
                            }
                          });
                        },
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (Get.width / 2) - 40,
                      ),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
