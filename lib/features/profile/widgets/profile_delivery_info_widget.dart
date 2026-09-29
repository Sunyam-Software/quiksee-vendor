import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';


class ProfileDeliveryInfoItemWidget extends StatelessWidget {
  final String? icon;
  final double? countNumber;
  final String? title;
  final bool isAmount;
  const ProfileDeliveryInfoItemWidget({super.key, this.icon, this.countNumber, this.title, this.isAmount = false});

  @override
  Widget build(BuildContext context) {
    double widthSize = MediaQuery.of(context).size.width;
    return Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      child: Container(
        height: widthSize / 3,
        width: widthSize / 3.8,
        padding:  EdgeInsets.all(Dimensions.paddingSizeDefault),decoration: BoxDecoration(
        color: Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.125) : Theme.of(context).primaryColor.withValues(alpha:.10),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeMin),),child: Column(children: [
          Container(decoration: BoxDecoration(color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge)),
              child: Container(padding:  EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Get.isDarkMode? Theme.of(context).cardColor : Theme.of(context).primaryColor.withValues(alpha:.75),
                  ),
                  width: 35,
                  child: QuikseeAssetImageWidget(icon!),
              ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeMin),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              isAmount? Text(Get.find<SplashController>().myCurrency!.symbol!,
                style: rubikMedium.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeHeading),) : const SizedBox(),
              Text(isAmount ? '${NumberFormat.compact().format(countNumber ?? 0)}+' : NumberFormat.compact().format(countNumber ?? 0),
                  style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge,color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor), overflow: TextOverflow.ellipsis,),
            ]),
          ),

          Expanded(child: Padding(
            padding: EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
            child: Text(title!.tr,textAlign: TextAlign.center,
              style: rubikRegular.copyWith(height: 1.1, fontSize:Dimensions.fontSizeExtraSmall, color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).disabledColor), overflow: TextOverflow.clip,),
          )),
      ],),),
    );
  }
}