
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/guideline_model.dart';
import 'package:quiksee_vendor_app/features/shop/widgets/quiksee_expansion_tile.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class BusinessSetupGuideline extends StatefulWidget {
  const BusinessSetupGuideline({super.key});

  @override
  State<BusinessSetupGuideline> createState() => _BusinessSetupGuidelineState();
}

class _BusinessSetupGuidelineState extends State<BusinessSetupGuideline> {

  List<GuidelineModel> guidelineList = [];

  @override
  void initState() {
    super.initState();

    final ShopController shopController = Provider.of<ShopController>(context, listen: false);

    guidelineList = shopController.myShopPageIndex == 0
        ? AppConstants.inHouseShopGuidelineList
        : shopController.myShopPageIndex == 1
        ? AppConstants.paymentInfoGuidelineList
        : AppConstants.otherSetupGuidelineList;

  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).hintColor.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(Dimensions.radiusExtraLarge),
              topLeft: Radius.circular(Dimensions.radiusExtraLarge),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          child: Row(
            children: [
              Text(getTranslated('business_setup_guideline', context) ?? '',
                  style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeLarge)
              ),
              const Spacer(),

              InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const QuikseeAssetImageWidget(Images.closeIcon, width: 20, height: 20)
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            itemCount: guidelineList.length,
            itemBuilder: (context, index){
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
                ),
                child: QuikseeExpansionTile(
                  expandedAlignment: Alignment.topLeft,
                  title:  Row(children: [

                    Text(getTranslated(guidelineList[index].title, context)!,
                        style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: Dimensions.fontSizeLarge)
                    ),

                    const Expanded(child: SizedBox()),
                  ]),
                  childrenPadding: const EdgeInsets.only(
                    left: Dimensions.paddingSizeDefault,
                    right: Dimensions.paddingSizeDefault,
                    bottom: Dimensions.paddingSizeDefault,

                  ),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusSmall)),
                      ),
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Text(getTranslated(guidelineList[index].description, context)!, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall))),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeSmall),
          ),
        ),

      ],
      ),
    );
  }
}

