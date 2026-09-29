import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/auth/widgets/pass_view.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_text_field_widget.dart';

class AccountInfoWidget extends StatelessWidget {
  const AccountInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
        builder: (profileController) {
          return ListView(physics: const NeverScrollableScrollPhysics(), children: [

              Padding(padding:  EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('phone_no'.tr, style: rubikRegular),

                      Padding(
                        padding:  EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                        child: Text('(${'not_editable'.tr})', style: rubikRegular.copyWith(
                          fontSize: Dimensions.paddingSizeSmall,
                          color: Theme.of(context).hintColor.withValues(alpha:.75),
                        )),
                      ),

                    ]),
                    SizedBox(height: Dimensions.paddingSizeSmall),

                    QuikseeTextFieldWidget(
                      prefixIconUrl: Images.phone,
                      isDisable: false,
                      noBg: true,
                      isShowBorder: true,
                      fillColor: Theme.of(context).hintColor.withValues(alpha:.125),
                      hintText: '${profileController.profileModel!.countryCode ?? ""}${profileController.profileModel!.phone ?? ""}',
                    ),
                  ],
                ),
              ),

              Text('password'.tr, style: rubikRegular),
               SizedBox(height: Dimensions.paddingSizeSmall),

              QuikseeTextFieldWidget(
                controller: profileController.passwordController,
                isShowBorder: true,
                noBg: true,
                hintText: 'password'.tr,
                isShowSuffixIcon: true,
                prefixIconUrl: Images.lock,
                focusNode: profileController.passwordFocus,
                nextFocus: profileController.confirmPasswordFocus,
                inputAction: TextInputAction.next,
                isPassword: true,
                onChanged: (value) {
                  if(value != null && value.isNotEmpty){
                    if(!profileController.showPassView){
                      profileController.showHidePass();
                    }
                    profileController.validPassCheck(value);
                  }else{
                    if(profileController.showPassView){
                      profileController.showHidePass();
                    }
                  }
                },
              ),


              profileController.showPassView ? const PassView() : const SizedBox(),


              Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                child: Text('confirm_password'.tr, style: rubikRegular)),

              QuikseeTextFieldWidget(
                noBg: true,
                hintText: 'confirm_password'.tr,
                isShowSuffixIcon: true,
                prefixIconUrl: Images.lock,
                controller: profileController.confirmPasswordController,
                isShowBorder: true,
                focusNode: profileController.confirmPasswordFocus,
                inputAction: TextInputAction.done,
                isPassword: true,
              ),

               SizedBox(height: Dimensions.paddingSizeDefault,),

            ],
          );
        }
    );
  }
}
