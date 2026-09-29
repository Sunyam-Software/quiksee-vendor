import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/features/profile/domain/models/userinfo_model.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';

class ProfileInfoWidget extends StatelessWidget {
  final bool isChat;
  final UserInfoModel? profileModel;
  const ProfileInfoWidget({super.key, this.profileModel, this.isChat = false});

  String get _displayName {
    final first = profileModel?.fName?.trim() ?? '';
    final last = profileModel?.lName?.trim() ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : 'my_profile'.tr;
  }

  String get _displayPhone {
    final code = profileModel?.countryCode?.trim() ?? '';
    final phone = profileModel?.phone?.trim() ?? '';
    if (code.isEmpty && phone.isEmpty) return '--';
    return '$code $phone'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isChat? 100 : 120,
      width: MediaQuery.of(context).size.width,
      padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
      child: Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(height: isChat ? Dimensions.chatProfileSize : Dimensions.menuProfileImageSize, width: isChat ? Dimensions.chatProfileSize : Dimensions.menuProfileImageSize,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardColor, width: 3)
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: QuikseeImageWidget(image: profileModel?.imageFullUrl?.path ?? '',width: 30,height: 30,)
                ),
              ),
              SizedBox(width: Get.find<LocalizationController>().isLtr? 0: Dimensions.paddingSizeSmall),

              isChat ? Expanded(
                child: Padding(
                  padding:  EdgeInsets.only(left: Dimensions.paddingSizeDefault,),
                  child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeHeading,
                        color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white)
                      ),
                    ],
                  ),
                ),
              ) :
              Expanded(
                child: Padding(
                  padding:  EdgeInsets.only(left: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeOverLarge),
                  child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeHeading,
                              color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white)),
                       SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(_displayPhone,
                        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width:  Dimensions.logoHeight,),
            ],
          ),
          SizedBox(height:isChat? 0 : Dimensions.paddingSizeLarge),
        ],
      ),
    );
  }
}
