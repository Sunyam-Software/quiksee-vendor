import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/features/auth/screens/login_screen.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String? message;

  const RegistrationSuccessScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 72),
              ),
              SizedBox(height: Dimensions.paddingSizeExtraLarge),
              Text(
                'registration_success_title'.tr,
                style: rubikMedium.copyWith(
                  fontSize: Dimensions.fontSizeOverLarge,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                message ?? 'registration_success_message'.tr,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'registration_wait_for_approval'.tr,
                style: rubikMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.paddingSizeExtraLarge),
              QuikseeButtonWidget(
                btnTxt: 'go_to_login'.tr,
                onTap: () => Get.offAll(() => const LoginScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
