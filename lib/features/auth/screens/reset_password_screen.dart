import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_text_field_widget.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/auth/widgets/pass_view.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/auth/screens/login_screen.dart';

class ResetPasswordWidget extends StatefulWidget {
  final String identity;
  final String otp;

  const ResetPasswordWidget({
    super.key,
    required this.identity,
    required this.otp,
  });

  @override
  State<ResetPasswordWidget> createState() => _ResetPasswordWidgetState();
}

class _ResetPasswordWidgetState extends State<ResetPasswordWidget> {
  TextEditingController? _passwordController;
  TextEditingController? _confirmPasswordController;
  final FocusNode _newPasswordNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();
  GlobalKey<FormState>? _formKeyReset;

  @override
  void initState() {
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    Get.find<ProfileController>().validPassCheck('', isUpdate: false);
    super.initState();
  }

  Future<void> resetPassword() async {
    final password = _passwordController!.text.trim();
    final confirmPassword = _confirmPasswordController!.text.trim();

    if (password.isEmpty) {
      showQuikseeSnackBarWidget('password_is_required'.tr);
    } else if (confirmPassword.isEmpty) {
      showQuikseeSnackBarWidget('confirm_password_is_required'.tr);
    } else if (password.length < 8) {
      showQuikseeSnackBarWidget('password_at_least_8_character'.tr);
    } else if (password != confirmPassword) {
      showQuikseeSnackBarWidget('password_not_match'.tr);
    } else if (!Get.find<ProfileController>().isPasswordValid()) {
      showQuikseeSnackBarWidget('enter_valid_password'.tr);
    } else {
      final response = await Get.find<AuthController>().resetPassword(
        identity: widget.identity,
        otp: widget.otp,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (response.statusCode == 200) {
        Get.offAll(() => const LoginScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'reset_password'.tr, isBack: true),
      body: Form(
        key: _formKeyReset,
        child: GetBuilder<ProfileController>(
          builder: (profileController) {
            return GetBuilder<AuthController>(
              builder: (authController) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    0,
                    Dimensions.paddingSizeDefault,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        child: Text(
                          'new_password'.tr,
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          bottom: Dimensions.paddingSizeSmall,
                        ),
                        child: QuikseeTextFieldWidget(
                          isShowBorder: true,
                          hintText: 'new_password'.tr,
                          focusNode: _newPasswordNode,
                          nextFocus: _confirmPasswordNode,
                          isPassword: true,
                          noBg: true,
                          prefixIconUrl: Images.lock,
                          isShowSuffixIcon: true,
                          controller: _passwordController,
                          onChanged: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!profileController.showPassView) {
                                profileController.showHidePass();
                              }
                              profileController.validPassCheck(value);
                            } else if (profileController.showPassView) {
                              profileController.showHidePass();
                            }
                          },
                        ),
                      ),
                      profileController.showPassView
                          ? const PassView()
                          : const SizedBox(),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        child: Text(
                          'confirm_password'.tr,
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          bottom: Dimensions.paddingSizeLarge,
                        ),
                        child: QuikseeTextFieldWidget(
                          hintText: 'confirm_password'.tr,
                          isShowBorder: true,
                          inputAction: TextInputAction.done,
                          focusNode: _confirmPasswordNode,
                          isPassword: true,
                          prefixIconUrl: Images.lock,
                          noBg: true,
                          isShowSuffixIcon: true,
                          controller: _confirmPasswordController,
                        ),
                      ),
                      authController.isLoading
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (Get.width / 2) - 40,
                              ),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : QuikseeButtonWidget(
                              onTap: resetPassword,
                              btnTxt: 'update_password'.tr,
                            ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
