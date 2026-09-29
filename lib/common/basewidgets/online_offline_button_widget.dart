import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/common/basewidgets/confirmation_dialog_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee/common/basewidgets/flutter_quiksee_switch_widget.dart';

class OnlineOfflineButtonWidget extends StatelessWidget {
  static const Color _onlineGold = Color(0xFF8C5A00);

  final bool showProfileImage;
  const OnlineOfflineButtonWidget({super.key, this.showProfileImage = true});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(builder: (profileController) {
      return GetBuilder<OrderController>(builder: (orderController) {
        return (profileController.profileModel != null) ?
        FlutterQuikseeSwitchWidget(
          width: showProfileImage ?  90: 40, height: showProfileImage ? 30 : 20,
          valueFontSize: Dimensions.fontSizeDefault, showOnOff: true,
          activeText: showProfileImage ? 'online'.tr : '' ,
          inactiveText: showProfileImage ? 'offline'.tr : '',
          activeColor:  showProfileImage ? Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha:.08) : Get.isDarkMode ?
          (
            Get.find<ThemeController>().darkTheme ?
            ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.9) :
            ColorHelper.darken(Theme.of(context).primaryColor, 0.1)
          ) : Theme.of(context).primaryColor,
          activeTextColor: showProfileImage ? _onlineGold : Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha:.75),
          activeToggleBorder: Border.all(color: showProfileImage ? Theme.of(context).colorScheme.onTertiaryContainer:
          Get.isDarkMode ? ColorHelper.darken(Theme.of(context).primaryColor, 0.1) : Theme.of(context).colorScheme.primary, width: 2),
          toggleSize:  showProfileImage ? 30: 20,
          inactiveToggleBorder: Border.all(color: showProfileImage ?
          Theme.of(context).hintColor: Theme.of(context).primaryColor, width: 2),
          activeIcon: showProfileImage ? ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: QuikseeImageWidget(
              image: '${Get.find<ProfileController>().profileModel!.imageFullUrl?.path}',
              height: 30, width: 30, fit: BoxFit.cover)): const SizedBox(),
          inactiveIcon: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: QuikseeImageWidget(
              image: '${Get.find<ProfileController>().profileModel!.imageFullUrl?.path}',
              height: 30, width: 30, fit: BoxFit.cover)),
          value: profileController.profileModel!.isOnline == 1,
          onToggle: (bool goingOnline) async {
              if (goingOnline &&
                  profileController.profileModel?.isAccountActive != true) {
                showQuikseeSnackBarWidget('account_not_activated'.tr);
                return;
              }
              Get.dialog(ConfirmationDialogWidget(
                icon: Images.logo,
                description: profileController.profileModel!.isOnline == 1
                    ? 'are_you_sure_go_to_offline'.tr
                    : 'are_you_sure_go_to_online'.tr,
                onYesPressed: () async {
                  Get.back();
                  if (goingOnline) {
                    final onlineContext = Get.context ?? context;
                    await profileController.requestGoOnline(onlineContext);
                  } else {
                    profileController.profileStatusChange(context, 0);
                  }
                },
              ));


          },
        ) : const SizedBox();
      });
    });
  }
}
