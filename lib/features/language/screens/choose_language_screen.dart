import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/features/language/controllers/language_controller.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/features/language/domain/models/language_model.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';

class ChooseLanguageScreen extends StatefulWidget {
  const ChooseLanguageScreen({super.key});

  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {

  @override
  void initState() {
    super.initState();
    Get.find<LanguageController>().initializeAllLanguages(context);


  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'choose_the_language'.tr, isBack: true),
      body: SafeArea(
        child: GetBuilder<LanguageController>(
          builder: (languageController){
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 SizedBox(height: Dimensions.paddingSizeLarge),


                Expanded(child: ListView.builder(
                    itemCount: languageController.languages.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => _languageWidget(
                        context: context, languageModel: languageController.languages[index],
                        languageController: languageController, index: index))),


                Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeLarge,
                    right: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeLarge),


                  child: QuikseeButtonWidget(btnTxt: 'save'.tr,
                    onTap: () {
                      if(languageController.languages.isNotEmpty && languageController.selectIndex != -1) {
                        Get.find<LocalizationController>().setLanguage(Locale(
                          AppConstants.languages[languageController.selectIndex!].languageCode!,
                          AppConstants.languages[languageController.selectIndex!].countryCode,
                        ));
                        Navigator.pop(context);

                      }else {
                        showQuikseeSnackBarWidget('select_a_language'.tr);
                      }
                    },
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _languageWidget({required BuildContext context, required LanguageModel languageModel,
    required LanguageController languageController, int? index}) {
    return InkWell(onTap: ()  => languageController.setSelectIndex(index),
      child: Container(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: languageController.selectIndex == index ?
          Theme.of(context).primaryColor.withValues(alpha:.15) : null,
          border: Border(top: BorderSide(width: languageController.selectIndex == index ? 1.0 : 0.0,
              color: languageController.selectIndex == index ?
              Theme.of(context).primaryColor : Colors.transparent),

              bottom: BorderSide(width: languageController.selectIndex == index ? 1.0 : 0.0,
                  color: languageController.selectIndex == index ?
                  Theme.of(context).primaryColor : Colors.transparent)),),


        child: Container(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 1.0,
              color: languageController.selectIndex == index ?
              Colors.transparent :
              (languageController.selectIndex! - 1) == (index! - 1) ?
              Colors.transparent :
              Theme.of(context).dividerColor.withValues(alpha:.2))),),


          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                  Image.asset(languageModel.imageUrl!, width: Dimensions.flagSize,
                      height: Dimensions.flagSize),
                   SizedBox(width: Dimensions.topSpace),


                  Text(languageModel.languageName!,
                    style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color))]),


              languageController.selectIndex == index ?
              Image.asset(Images.done, width: Dimensions.iconSizeDefault, height: Dimensions.iconSizeDefault,
                color: Theme.of(context).primaryColorLight,) :
              const SizedBox.shrink()])),
      ),
    );
  }
}
