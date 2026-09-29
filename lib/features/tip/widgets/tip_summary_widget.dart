import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/tip/controllers/tip_controller.dart';
import 'package:quiksee/features/tip/screens/tip_list_screen.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class TipSummaryWidget extends StatelessWidget {
  const TipSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TipController>(
      builder: (tipController) {
        if (tipController.isLoading && tipController.summary == null) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.fontSizeHeading,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final summary = tipController.summary;
        if (summary == null || !summary.isEnabled) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.fontSizeHeading,
            Dimensions.paddingSizeSmall,
            Dimensions.fontSizeHeading,
            0,
          ),
          child: InkWell(
            onTap: () => Get.to(() => const TipListScreen()),
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
            child: Container(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeDefault),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: .4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: .08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        color: Colors.amber.shade700,
                        size: Dimensions.iconSizeDefault,
                      ),
                      SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Text(
                          'customer_tips'.tr,
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ],
                  ),
                  SizedBox(height: Dimensions.paddingSizeDefault),
                  Row(
                    children: [
                      Expanded(
                        child: _tipStat(
                          context,
                          'tip_earned'.tr,
                          summary.totalTipEarnedFormatted ??
                              PriceConverter.convertPrice(
                                  summary.totalTipEarned),
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: _tipStat(
                          context,
                          'tip_pending'.tr,
                          summary.totalTipPendingFormatted ??
                              PriceConverter.convertPrice(
                                  summary.totalTipPending),
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if ((summary.todayTipEarned ?? 0) > 0)
                    Padding(
                      padding:
                          EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      child: Text(
                        '${'today'.tr}: ${PriceConverter.convertPrice(summary.todayTipEarned)}',
                        style: rubikRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tipStat(
      BuildContext context, String label, String? value, Color color) {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: rubikRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            value ?? '—',
            style: rubikMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
