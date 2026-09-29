import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';

class QuikseeActionButtonWidget extends StatelessWidget {
  final String? title;
  final Function? onTap;
  const QuikseeActionButtonWidget({super.key, this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Container(
        padding:  EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
            color: Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).primaryColor.withValues(alpha:.1),
            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.5),width: .5)),
        child: Text(title!.tr),
      ),
    );
  }
}
