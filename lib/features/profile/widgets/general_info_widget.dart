import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_text_field_widget.dart';

class GeneralInfoWidget extends StatelessWidget {
  const GeneralInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
        builder: (profileController) {

          return ListView(physics: const NeverScrollableScrollPhysics(), children: [

            Padding(padding:  EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Text('first_name'.tr, style: rubikRegular),
                SizedBox(height: Dimensions.paddingSizeSmall),

                QuikseeTextFieldWidget(
                  prefixIconUrl: Images.profileIcon,
                  isShowBorder: true,
                  noBg: true,
                  inputType: TextInputType.name,
                  focusNode: profileController.fNameFocus,
                  nextFocus: profileController.lNameFocus,
                  hintText: profileController.profileModel!.fName ?? '',
                  controller: profileController.firstNameController,
                  textStyle: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Get.isDarkMode ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.90) : Theme.of(context).primaryColorDark,
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeDefault),

                Text('last_name'.tr, style: rubikRegular),
                SizedBox(height: Dimensions.paddingSizeSmall),

                QuikseeTextFieldWidget(
                  prefixIconUrl: Images.profileIcon,
                  noBg: true,
                  isShowBorder: true,
                  inputType: TextInputType.name,
                  focusNode: profileController.lNameFocus,
                  nextFocus: profileController.addressFocus,
                  hintText: profileController.profileModel!.lName,
                  controller: profileController.lastNameController,
                  textStyle: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Get.isDarkMode ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.90) : Theme.of(context).primaryColorDark,
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),

                Row(
                  children: [
                    Text('email'.tr, style: rubikRegular),
                    Padding(
                      padding:  EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                      child: Text('(${'not_editable'.tr})', style: rubikRegular.copyWith(fontSize: Dimensions.paddingSizeSmall,
                          color: Theme.of(context).hintColor.withValues(alpha:.75)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),

                QuikseeTextFieldWidget(
                  prefixIconUrl: Images.emailIcon,
                  noBg: true,
                  fillColor: Theme.of(context).hintColor.withValues(alpha:.125),
                  isShowBorder: true,
                  isDisable: false,
                  inputType: TextInputType.name,
                  focusNode: profileController.addressFocus,
                  hintText: profileController.profileModel!.email,
                  controller: profileController.emailController ,
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),

                Row(
                  children: [
                    Text('phone_no'.tr, style: rubikRegular),
                    Padding(
                      padding:  EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                      child: Text('(${'not_editable'.tr})', style: rubikRegular.copyWith(fontSize: Dimensions.paddingSizeSmall,
                          color: Theme.of(context).hintColor.withValues(alpha:.75))),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),

                QuikseeTextFieldWidget(
                  fillColor: Theme.of(context).hintColor.withValues(alpha:.125),
                  prefixIconUrl: Images.phoneIcon,
                  noBg: true,
                  isDisable: false,
                  isShowBorder: true,
                  inputType: TextInputType.number,
                  hintText: '${profileController.profileModel!.countryCode ?? ""} ${profileController.profileModel!.phone ?? ""}',
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),

                Text('address_s'.tr, style: rubikRegular),
                SizedBox(height: Dimensions.paddingSizeSmall),

                QuikseeTextFieldWidget(
                  prefixIconUrl: Images.addressIcon,
                  noBg: true,
                  isShowBorder: true,
                  inputType: TextInputType.name,
                  focusNode: profileController.addressFocus,
                  hintText: profileController.profileModel!.address,
                  controller: profileController.addressController,
                  textStyle: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Get.isDarkMode ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.90) : Theme.of(context).primaryColorDark,
                  ),
                ),
              ],
              ),
            ),


            Padding(
              padding:  EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Text('identity_number_and_card'.tr, style: rubikRegular),

                    Padding(
                      padding:  EdgeInsets.only(left: Dimensions.paddingSizeExtraSmall),
                      child: Text('(${'not_editable'.tr})', style: rubikRegular.copyWith(fontSize: Dimensions.paddingSizeSmall,
                          color: Theme.of(context).hintColor.withValues(alpha:.75))),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.paddingSizeSmall),
                QuikseeTextFieldWidget(
                  fillColor: Theme.of(context).hintColor.withValues(alpha:.125),
                  isDisable: false,
                  prefixIconUrl: Images.identityImage,
                  noBg: true,
                  isShowBorder: true,
                  inputType: TextInputType.number,
                  hintText: '${profileController.profileModel!.identityNumber} (${profileController.profileModel!.identityType})',
                ),

                profileController.profileModel!.identityImageFullUrl != null && ( profileController.profileModel!.identityImageFullUrl != null && profileController.profileModel!.identityImageFullUrl!.isNotEmpty) ?
                Padding(
                  padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  child: Row(children: [
                    Expanded(child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          child: QuikseeImageWidget(image: '${profileController.profileModel!.identityImageFullUrl![0].path}' , height: 120)),)),
                    SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    profileController.profileModel!.identityImageFullUrl!.length>1?
                    Expanded(child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          child: QuikseeImageWidget(image: '${profileController.profileModel!.identityImageFullUrl![1].path}' , height: 120)),)) : const SizedBox(),
                  ]),
                ) : const SizedBox(),

                profileController.profileModel!.identityImageFullUrl!.length >2 ?
                Padding(
                  padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  child: Row(children: [
                    Expanded(child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          child: QuikseeImageWidget(image: '${profileController.profileModel!.identityImageFullUrl![2].path}' , height: 120)),)),
                    SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    profileController.profileModel!.identityImageFullUrl!.length>3 ?
                    Expanded(child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          child: QuikseeImageWidget(image: '${profileController.profileModel!.identityImageFullUrl![3].path}' , height: 120)),)) : const SizedBox(),
                  ]),
                ) : const SizedBox(),

                profileController.profileModel!.identityImageFullUrl!.length > 4 ?
                Padding(
                  padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                  child: Row(children: [
                    Expanded(child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                          child: QuikseeImageWidget(image: '${profileController.profileModel!.identityImageFullUrl![4].path}' , height: 120)),)),
                    SizedBox(width: Dimensions.paddingSizeExtraSmall),

                    const Expanded(child: SizedBox()),
                  ]),
                ) : const SizedBox(),
              ]),
            ),

          ]);
        }
    );
  }
}
