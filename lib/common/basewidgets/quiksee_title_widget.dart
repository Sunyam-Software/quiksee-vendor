import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class QuikseeTitleWidget extends StatelessWidget {
  final String title;
  const QuikseeTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return  Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
      child: Text(title.tr,style: rubikMedium.copyWith(color: Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.5) : Theme.of(context).primaryColor,
          fontSize: Dimensions.fontSizeLarge)),
    );
  }
}
