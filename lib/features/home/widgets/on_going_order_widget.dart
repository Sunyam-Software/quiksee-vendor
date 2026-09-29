import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/theme/controllers/theme_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/features/home/widgets/order_type_button_head_widget.dart';
import 'package:quiksee_vendor_app/features/home/widgets/quiksee_section_title_widget.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';

class OngoingOrderWidget extends StatelessWidget {
  final Function? callback;
  const OngoingOrderWidget({super.key, this.callback});

  @override
  Widget build(BuildContext context) {
    return Consumer<BankInfoController>(
      builder: (context,bankInfoController,child){
        return bankInfoController.businessAnalyticsFilterData  == null ? BusinessAnalyticsShimmer(isDarkMode: Provider.of<ThemeController>(context).darkTheme) : Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeMedium),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  QuikseeSectionTitleWidget(getTranslated('business_analytics', context) ?? 'Business Analytics'),

                  const Expanded(child: SizedBox(width: Dimensions.paddingSizeExtraLarge,)),
                  Container(
                    height: 40, width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(width: .7,color: Theme.of(context).hintColor.withValues(alpha:.3)),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    ),
                    child: DropdownButton<String>(
                      iconEnabledColor: Theme.of(context).primaryColor,
                      value: bankInfoController.analyticsIndex == 0 ? 'overall' :
                      bankInfoController.analyticsIndex == 1 ?  'today' :
                      bankInfoController.analyticsIndex == 2 ?  'this_week' :
                      bankInfoController.analyticsIndex == 3 ?  'this_month' :
                      'this_year',
                      items: <String>['overall', 'today', 'this_week', 'this_month', 'this_year'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            getTranslated(value, context) ?? value,
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        bankInfoController.setAnalyticsFilterName(context,value, true);
                        bankInfoController.setAnalyticsFilterType(
                         value == 'overall' ? 0 :
                         value == 'today'? 1 :
                         value == 'this_week'? 2 :
                         value == 'this_month'? 3 : 4,
                         true
                        );
                      },
                      isExpanded: true,
                      underline: const SizedBox(),
                    ),
                  ),
                ],),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Consumer<BankInfoController>(
              builder: (context, bankInfoController, child) => SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                  children: [
                    SizedBox(
                      width: 148,
                      child: OrderTypeButtonHeadWidget(
                        circleColor: const Color(0xFFE85D04),
                        image: Images.pendingOrderCardIcon,
                        text: getTranslated('pending', context),
                        index: 1,
                        subText: getTranslated('orders', context),
                        numberOfOrder: bankInfoController.businessAnalyticsFilterData?.pending ?? 0,
                        callback: callback,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 148,
                      child: OrderTypeButtonHeadWidget(
                        circleColor: QuikseeBrandColors.gold,
                        image: Images.packagingOrdersCardIcon,
                        text: getTranslated('processing', context),
                        index: 2,
                        numberOfOrder: bankInfoController.businessAnalyticsFilterData?.processing ?? 0,
                        callback: callback,
                        subText: getTranslated('orders', context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 148,
                      child: OrderTypeButtonHeadWidget(
                        circleColor: QuikseeBrandColors.seeTextGreen,
                        image: Images.confirmOrderCardIcon,
                        text: getTranslated('confirmed', context),
                        index: 7,
                        subText: getTranslated('orders', context),
                        numberOfOrder: bankInfoController.businessAnalyticsFilterData?.confirmed ?? 0,
                        callback: callback,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 148,
                      child: OrderTypeButtonHeadWidget(
                        circleColor: const Color(0xFF1565C0),
                        image: Images.outForDeliveryCardIcon,
                        text: getTranslated('out_for_delivery', context),
                        index: 8,
                        subText: getTranslated('orders', context),
                        numberOfOrder: bankInfoController.businessAnalyticsFilterData?.outForDelivery ?? 0,
                        callback: callback,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],),
        );
      },
    );
  }
}

class BusinessAnalyticsShimmer extends StatelessWidget {
  final bool isDarkMode;
  const BusinessAnalyticsShimmer({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final shimmerColor = Theme.of(context).colorScheme.secondaryContainer;

    final baseColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[500]! : Colors.grey[100]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 36, height: 36, color: shimmerColor),
                  const SizedBox(width: 12),
                  Container(height: 14, width: 140, color: shimmerColor),
                  const Spacer(),
                  Container(height: 50, width: 120, color: shimmerColor),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 7),
              child: Container(height: 14, width: 120, color: shimmerColor),
            ),

            SizedBox(
              height: 128,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: List.generate(
                  4,
                  (_) => Container(
                    width: 148,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

