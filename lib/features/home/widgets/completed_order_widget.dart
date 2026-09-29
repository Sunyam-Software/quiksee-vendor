import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quiksee_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:quiksee_vendor_app/features/home/widgets/quiksee_completed_order_chip_widget.dart';
import 'package:quiksee_vendor_app/features/home/widgets/quiksee_section_title_widget.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/theme/controllers/theme_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';

class CompletedOrderWidget extends StatelessWidget {
  final Function? callback;
  const CompletedOrderWidget({super.key, this.callback});

  static const double _cardHeight = 128;

  @override
  Widget build(BuildContext context) {
    return Consumer<BankInfoController>(
      builder: (context, bankInfoController, child) {
        return bankInfoController.businessAnalyticsFilterData == null
            ? CompletedOrdersShimmer(isDarkMode: Provider.of<ThemeController>(context).darkTheme)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeMedium),
                      child: QuikseeSectionTitleWidget(
                        getTranslated('completed_orders', context) ?? 'Completed Orders',
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    SizedBox(
                      height: _cardHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        children: [
                            QuikseeCompletedOrderChipWidget(
                              primaryColor: QuikseeBrandColors.seeTextGreen,
                              icon: Images.delivered,
                              label: getTranslated('delivered', context) ?? 'Delivered',
                              index: 3,
                              count: bankInfoController.businessAnalyticsFilterData?.delivered,
                              waveOnLeft: true,
                              onTap: () => callback?.call(),
                            ),
                            const SizedBox(width: 10),
                            QuikseeCompletedOrderChipWidget(
                              primaryColor: const Color(0xFFE53935),
                              icon: Images.cancelled,
                              label: getTranslated('cancelled', context) ?? 'Cancelled',
                              index: 6,
                              count: bankInfoController.businessAnalyticsFilterData?.canceled,
                              waveOnLeft: false,
                              onTap: () => callback?.call(),
                            ),
                            const SizedBox(width: 10),
                            QuikseeCompletedOrderChipWidget(
                              primaryColor: const Color(0xFFB8860B),
                              icon: Images.returned,
                              label: getTranslated('returned', context) ?? 'Returned',
                              index: 4,
                              count: bankInfoController.businessAnalyticsFilterData?.returned,
                              waveOnLeft: true,
                              onTap: () => callback?.call(),
                            ),
                            const SizedBox(width: 10),
                            QuikseeCompletedOrderChipWidget(
                              primaryColor: const Color(0xFFFF6F00),
                              icon: Images.failed,
                              label: getTranslated('failed_title', context) ?? 'Failed',
                              index: 5,
                              count: bankInfoController.businessAnalyticsFilterData?.failed,
                              waveOnLeft: false,
                              onTap: () => callback?.call(),
                            ),
                          ],
                        ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                  ],
                ),
              );
      },
    );
  }
}

class CompletedOrdersShimmer extends StatelessWidget {
  final bool isDarkMode;
  const CompletedOrdersShimmer({super.key, required this.isDarkMode});

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(height: 16, width: 160, color: shimmerColor),
            ),
            Container(
              decoration: BoxDecoration(
                color: shimmerColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: CompletedOrderWidget._cardHeight,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: List.generate(
                    4,
                    (_) => Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
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
