import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';

class ThemeButtonWidget extends StatelessWidget {
  const ThemeButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isLtr = Get.find<LocalizationController>().isLtr;

    return GetBuilder<ThemeController>(
        builder: (themeController) {
          return SizedBox(height: 50,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[

              InkWell(
                onTap: (){
                  if(themeController.darkTheme){
                    themeController.toggleTheme();
                  }
                },
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                      color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isLtr ? Dimensions.paddingSizeOverLarge :0),
                        bottomLeft: Radius.circular(isLtr ? Dimensions.paddingSizeOverLarge  : 0),
                        topRight: Radius.circular(isLtr ? 0:  Dimensions.paddingSizeOverLarge),
                        bottomRight: Radius.circular(isLtr ? 0 : Dimensions.paddingSizeOverLarge),
                      )
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    Icon(Icons.sunny, color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).cardColor,),
                    SizedBox(width: Dimensions.paddingSizeMin,),

                    Text('light'.tr, style: rubikRegular.copyWith(color: Get.isDarkMode ? null : Theme.of(context).cardColor),)

                  ],),
                ),
              ),


              InkWell(
                onTap: (){
                  if(!themeController.darkTheme){
                    themeController.toggleTheme();
                  }
                },
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                      color: Get.isDarkMode ? ColorHelper.darken(Theme.of(context).primaryColor, 0.1) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isLtr ? 0 : Dimensions.paddingSizeOverLarge),
                        bottomLeft: Radius.circular(isLtr ? 0 : Dimensions.paddingSizeOverLarge),
                        topRight: Radius.circular(isLtr ? Dimensions.paddingSizeOverLarge : 0),
                        bottomRight: Radius.circular(isLtr ? Dimensions.paddingSizeOverLarge : 0),
                      )
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    const QuikseeAssetImageWidget(Images.darkModeIcon, width: 25, height: 25),
                    SizedBox(width: Dimensions.paddingSizeMin,),

                    Text('dark'.tr, style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : null),)

                  ],),
                ),
              ),
            ]),
          );
        });
  }
}
