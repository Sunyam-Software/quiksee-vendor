import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class TitleWidget extends StatelessWidget {
  final String title;
  final Function? onTap;

  const TitleWidget({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
      onTap != null ? GestureDetector(
        onTap: onTap as void Function()?,
        child: Padding(padding: const EdgeInsets.fromLTRB(10, 5, 0, 5),
          child: Container(decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
            border: Border.all(color: Get.isDarkMode? Theme.of(context).primaryColorLight :Theme.of(context).primaryColor.withValues(alpha:.25))),
            padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall,vertical: Dimensions.paddingSizeExtraSmall),
            child: Text('view_all'.tr,
              style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : ColorHelper.darken(Theme.of(context).primaryColor, 0.1))))),
      ) : const SizedBox(),
    ]);
  }
}
