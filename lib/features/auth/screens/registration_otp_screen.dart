import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/auth/controllers/registration_controller.dart';
import 'package:quiksee/features/auth/screens/registration_success_screen.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class RegistrationOtpScreen extends StatefulWidget {
  final String identity;
  final bool isEmail;

  const RegistrationOtpScreen({
    super.key,
    required this.identity,
    required this.isEmail,
  });

  @override
  State<RegistrationOtpScreen> createState() => _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState extends State<RegistrationOtpScreen> {
  Timer? _resendTimer;
  int _secondsLeft = 0;
  String _enteredOtp = '';

  @override
  void initState() {
    super.initState();
    final controller = Get.find<RegistrationController>();
    if (controller.config?.isEmailVerification == true) {
      controller.otpIdentity = widget.identity.trim().toLowerCase();
    } else if (widget.identity.isNotEmpty) {
      controller.otpIdentity = widget.identity.trim();
    }
    controller.otpCode = '';
    _startCountdown(controller.resendAfterSeconds);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = seconds);
    if (seconds <= 0) return;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _onResend(RegistrationController controller) async {
    if (_secondsLeft > 0 || controller.isSendingOtp) return;

    final result = await controller.sendRegistrationOtp();
    if (result == null) return;

    if (result.isSuccess) {
      showQuikseeSnackBarWidget(
        result.message ?? 'otp_send_successfully'.tr,
        isError: false,
      );
      if (result.debugOtp != null) {
        showQuikseeSnackBarWidget(
          'Debug OTP: ${result.debugOtp}',
          isError: false,
        );
      }
      _startCountdown(result.resendAfter);
    } else {
      showQuikseeSnackBarWidget(result.message ?? 'registration_failed'.tr);
      if (result.resendAfter > 0) {
        _startCountdown(result.resendAfter);
      }
    }
  }

  Future<void> _onVerify(RegistrationController controller) async {
    final otpLength = controller.config?.otpLength ?? 4;
    final otp = _enteredOtp.trim();

    if (otp.length < otpLength) {
      showQuikseeSnackBarWidget('input_valid_otp'.tr);
      return;
    }

    final result = await controller.verifyRegistrationOtp(
      otp,
      identityOverride: widget.identity,
    );
    if (result == null || !result.isSuccess) {
      showQuikseeSnackBarWidget(result?.message ?? 'input_valid_otp'.tr);
      return;
    }

    controller.isSubmittingAfterOtp = true;
    controller.update();

    final submitResult = await controller.submitAfterOtpVerified();

    controller.isSubmittingAfterOtp = false;
    controller.update();

    if (submitResult?.isSuccess == true) {
      Get.offAll(
        () => RegistrationSuccessScreen(message: submitResult!.message),
      );
      return;
    }

    if (submitResult?.verificationRequired == true) {
      showQuikseeSnackBarWidget(
        submitResult?.message ?? 'otp_verification_required'.tr,
      );
      return;
    }

    showQuikseeSnackBarWidget(
      submitResult?.message ?? 'registration_failed'.tr,
    );
  }

  bool _isBusy(RegistrationController controller) =>
      controller.isVerifyingOtp ||
      controller.isSubmittingAfterOtp ||
      controller.isSubmitting;

  @override
  Widget build(BuildContext context) {
    final otpLength =
        Get.find<RegistrationController>().config?.otpLength ?? 4;
    final otpHint =
        Get.find<RegistrationController>().config?.otpHint;

    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: 'registration_otp_title'.tr,
        isBack: true,
        onTap: () => Navigator.pop(context),
      ),
      body: GetBuilder<RegistrationController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: Dimensions.paddingSizeLarge),
                Icon(
                  widget.isEmail ? Icons.email_outlined : Icons.phone_android,
                  size: 56,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  widget.isEmail
                      ? 'please_enter_otp_sent_to_email'.tr
                      : 'please_enter_4_digit_code'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  widget.identity,
                  style: rubikRegular.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (otpHint != null && otpHint.isNotEmpty) ...[
                  SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    otpHint,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: Dimensions.paddingSizeExtraLarge),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Get.width / 7,
                  ),
                  child: PinCodeTextField(
                    length: otpLength,
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
                      borderRadius: BorderRadius.circular(
                        Dimensions.paddingSizeExtraLarge,
                      ),
                      selectedColor: ColorHelper.darken(
                        Theme.of(context).primaryColor,
                        0.2,
                      ),
                      selectedFillColor: Colors.white,
                      inactiveFillColor: Get.isDarkMode
                          ? Theme.of(context)
                              .hintColor
                              .withValues(alpha: 0.125)
                          : Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                      inactiveColor: ColorHelper.darken(
                        Theme.of(context).primaryColor,
                        0.2,
                      ),
                      activeColor: ColorHelper.darken(
                        Theme.of(context).primaryColor,
                        0.1,
                      ),
                      activeFillColor: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.025),
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    backgroundColor: Colors.transparent,
                    enableActiveFill: true,
                    onChanged: (value) {
                      _enteredOtp = value;
                      controller.updateOtpCode(value);
                    },
                    onCompleted: (value) {
                      _enteredOtp = value;
                      controller.updateOtpCode(value);
                    },
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
                SizedBox(height: Dimensions.paddingSizeDefault),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${'if_you_did_not_receive_a_code'.tr},'),
                    InkWell(
                      onTap: _secondsLeft > 0 || controller.isSendingOtp
                          ? null
                          : () => _onResend(controller),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: Dimensions.paddingSizeSmall,
                        ),
                        child: Text(
                          _secondsLeft > 0
                              ? 'resend_in_seconds'.trParams({
                                  'seconds': _secondsLeft.toString(),
                                })
                              : 'resend'.tr,
                          style: rubikMedium.copyWith(
                            color: _secondsLeft > 0 || controller.isSendingOtp
                                ? Theme.of(context).hintColor
                                : Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.paddingSizeExtraLarge),
                if (_isBusy(controller))
                  Column(
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        controller.isSubmittingAfterOtp ||
                                controller.isSubmitting
                            ? 'submitting_application'.tr
                            : 'verify'.tr,
                        style: rubikRegular.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  )
                else
                  QuikseeButtonWidget(
                    btnTxt: 'verify_and_submit'.tr,
                    onTap: () => _onVerify(controller),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
