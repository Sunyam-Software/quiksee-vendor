
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/profile/domain/models/userinfo_model.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/splash/domain/models/business_pages_model.dart';
import 'package:quiksee/features/wallet/screens/wallet_screen.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/animated_custom_dialog_widget.dart';
import 'package:quiksee/common/basewidgets/confirmation_dialog_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/online_offline_button_widget.dart';
import 'package:quiksee/features/auth/screens/login_screen.dart';
import 'package:quiksee/features/earning_statement/screens/earning_statement_screen.dart';
import 'package:quiksee/features/profile/screens/bank_info_screen.dart';
import 'package:quiksee/features/emergency_contact/screens/emergency_contact_screen.dart';
import 'package:quiksee/features/help_and_support/screens/help_and_support_screen.dart';
import 'package:quiksee/features/profile/screens/html_view_screen.dart';
import 'package:quiksee/features/profile/widgets/profile_button_widget.dart';
import 'package:quiksee/features/profile/widgets/profile_delivery_info_widget.dart';
import 'package:quiksee/features/profile/widgets/profile_activation_status_widget.dart';
import 'package:quiksee/features/profile/widgets/profile_header_widget.dart';
import 'package:quiksee/features/review/screens/review_screen.dart';
import 'package:quiksee/features/setting/screens/setting_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final profileController = Get.find<ProfileController>();
    if (profileController.profileModel == null) {
      profileController.getProfile(silent: true);
    } else if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().loadDeliveryAreas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'my_profile'.tr),

        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: GetBuilder<ProfileController>(builder: (profileController){
            final UserInfoModel? profile = profileController.profileModel;

            if (profileController.isLoading && profile == null) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            }

            return Padding(
              padding:  const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(children: [

                  ProfileHeaderWidget(profileModel: profileController.profileModel),

                  ProfileActivationStatusWidget(
                    profile: profileController.profileModel,
                  ),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:  [

                    Expanded(child: ProfileDeliveryInfoItemWidget(icon: Images.totalDelivery, title: 'total_delivery',
                        countNumber: double.parse(profile?.totalDelivery.toString() ?? '0'))),

                    Expanded(child: ProfileDeliveryInfoItemWidget(icon: Images.completedDelivery, title: 'completed_delivery',
                        countNumber: double.parse(profile?.completedDelivery.toString() ?? '0'))),

                    Expanded(child: ProfileDeliveryInfoItemWidget(icon: Images.totalEarned, title: 'total_earned',
                      countNumber: profile?.totalEarn, isAmount: true))]),
                    SizedBox(height: Dimensions.paddingSizeExtraSmall,),

                    GetBuilder<SplashController>
                      (builder: (splashController) {
                      return Padding(
                        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                        child: Column(children: [

                          Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault,),
                            child: Row(children: [
                              SizedBox(width: Dimensions.paddingSizeSmall),
                              SizedBox(width: 20, child: QuikseeAssetImageWidget(Images.statusIcon, color:Get.isDarkMode ? ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.9) : Theme.of(context).primaryColor,)),
                               SizedBox(width: Dimensions.paddingSizeDefault),
                              Expanded(child: Text('status'.tr,style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault))),
                              const OnlineOfflineButtonWidget(showProfileImage: false)])),

                          ProfileButtonWidget(icon: Images.earnStatement, title: 'earning_statement'.tr,
                              onTap: () => Get.to(const EarningStatementScreen())),

                          ProfileButtonWidget(icon: Images.walletIcon, title: 'my_wallet'.tr,
                              onTap: () => Get.to(const WalletScreen(fromNotification: false, fromProfile: true,))),

                          ProfileButtonWidget(icon: Images.bankIcon, title: 'bank_details'.tr,
                              onTap: () async {
                                await Get.find<ProfileController>()
                                    .getProfile(skipSideEffects: true);
                                Get.to(const BankInfoScreen());
                              }),

                          ProfileButtonWidget(icon: Images.myReview, title: 'my_reviews'.tr,
                              onTap: () => Get.to(const ReviewScreen())),

                          ProfileButtonWidget(icon: Images.emergencyContact, title: 'emergency_contact'.tr,
                              onTap: () => Get.to(const EmergencyContactScreen())),

                          ProfileButtonWidget(icon: Images.helpSupport, title: 'help_and_support'.tr,
                              onTap: () => Get.to(const HelpAndSupportScreen())),

                          ProfileButtonWidget(icon: Images.settingIcon, title: 'setting'.tr,
                              onTap: () => Get.to(const SettingScreen())),


                          ProfileButtonWidget(icon: Images.myReview, title: 'privacy_policy'.tr,
                            onTap: () => Get.to( HtmlViewScreen(
                              page: _getPageBySlug('privacy-policy', splashController.defaultBusinessPages),
                            ))),


                          ProfileButtonWidget(icon: Images.myReview, title: 'terms_and_condition'.tr,
                              onTap: () => Get.to(HtmlViewScreen(
                                page: _getPageBySlug('terms-and-conditions', splashController.defaultBusinessPages),
                              ))),

                          ProfileButtonWidget(icon: Images.logOut, title: 'log_out'.tr,
                              onTap: () => showAnimatedDialogWidget(context,  ConfirmationDialogWidget(icon: Images.logOut,
                                title: 'log_out'.tr,
                                description: 'do_you_want_to_log_out_this_account'.tr, onYesPressed: (){
                                  Get.find<AuthController>().clearSharedData().then((condition) {
                                    Get.back();
                                    Get.offAll(const LoginScreen());
                                  });
                                },),isFlip: true)),
                          ],
                        ),
                      );
                    }
                  )
                ],
              ),
            );
          },)
        ));
  }


   BusinessPageModel? _getPageBySlug(String slug, List<BusinessPageModel>? pagesList) {
     BusinessPageModel? pageModel;
     if(pagesList != null && pagesList.isNotEmpty){
       for (var page in pagesList) {
         if(page.slug == slug) {
           pageModel = page;
         }
       }
     }

     return pageModel;
   }

}

