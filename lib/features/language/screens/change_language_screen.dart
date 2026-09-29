import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/language/widgets/language_widget.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_brand_widget.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';

class ChooseLanguageScreen extends StatelessWidget {
  const ChooseLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: getTranslated('language', context),
        useQuikseeBrandedHeader: true,
      ),

      body: Consumer<LocalizationController>(
        builder: (context,localizationController,_) {
          return SingleChildScrollView(physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: SizedBox(width: MediaQuery.of(context).size.width,
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start, children: [

                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: const Center(
                    child: QuikseeAppBrandWidget(logoSize: 72, titleFontSize: 20, alignment: MainAxisAlignment.center),
                  ),
                ),

                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: Text(getTranslated('select_language', context)!, style: robotoMedium.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeExtraLarge,
                  )),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 2.4,
                    mainAxisExtent: 100,
                  ),
                  itemCount: localizationController.languages.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) => LanguageWidget(
                    languageModel: localizationController.languages[index],
                    localizationController: localizationController,
                    index: index,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ],
            ),
          ),
          );
      },),
    );
  }
}
