import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class QuikseeAppBarEditProfileWidget extends StatelessWidget {
  const QuikseeAppBarEditProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.topLeft, child: InkWell(
      onTap: () => Get.back(),
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Row(children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeMin),
            child: Icon(Icons.arrow_back_ios, color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).cardColor,),
          ),

          Text('my_profile'.tr, style: rubikMedium.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color :
              Theme.of(context).cardColor
          )),
        ]),
      ),
    ));
  }
}
