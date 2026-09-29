import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/common/basewidgets/theme_botton_widget.dart';
import 'package:quiksee/features/language/controllers/language_controller.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/features/language/screens/choose_language_screen.dart';
import 'package:quiksee/utill/styles.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late final bool isLtr;

  @override
  void initState() {
    isLtr = Get.find<LocalizationController>().isLtr;

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'setting'.tr, isBack: true),
      body: Column(children: [

        GestureDetector(onTap: ()=> Get.to(()=> const ChooseLanguageScreen()),
          child: Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault,Dimensions.paddingSizeDefault),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeLarge),
              color: Theme.of(context).hintColor.withValues(alpha: .075),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
                Row(children: [
                  const SizedBox(width: Dimensions.iconSizeDefault, child: QuikseeAssetImageWidget(Images.languageIcon)),

                  SizedBox(width: isLtr? 0: Dimensions.paddingSizeSmall),

                  Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Text('language'.tr))]),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppConstants.languages[Get.find<LanguageController>().selectIndex!].languageName!, style: rubikRegular.copyWith(fontSize: Dimensions.paddingSizeDefault),),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                      child: const Icon(Icons.keyboard_arrow_down_outlined, size: 15,),
                    )
                  ],
                ),
              ]),
            ))),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
            color: Theme.of(context).hintColor.withValues(alpha: .075),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(
                children: [
                  const SizedBox(width: Dimensions.iconSizeDefault, child: QuikseeAssetImageWidget(Images.themeIcon)),

                  SizedBox(width: isLtr ? 0 : Dimensions.paddingSizeSmall),

                  Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Text('theme'.tr),
                  ),
                ],
              ),

              const ThemeButtonWidget()

            ]),
          ),
        ),


      ]),
    );
  }
}


enum Theming {light, dark }

