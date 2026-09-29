import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class ProfileButtonWidget extends StatelessWidget {
  final String icon;
  final String title;
  final Function onTap;
  const ProfileButtonWidget({super.key, required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap as void Function()?,
      child: Container(width: MediaQuery.of(context).size.width,
        color: Get.isDarkMode ? null : Theme.of(context).cardColor,
        child: Column(
          children: [
            Divider(color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.25) : Theme.of(context).hintColor.withValues(alpha:.25)),
            Padding(
              padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault,),
              child: Row(
                children: [
                  SizedBox(width: Dimensions.paddingSizeSmall),
                  SizedBox(width: 20,child: QuikseeAssetImageWidget(icon, color:Get.isDarkMode ? ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.9)  : Theme.of(context).primaryColor)),
                   SizedBox(width: Dimensions.paddingSizeDefault),
                  Text(title, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Colors.black ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}