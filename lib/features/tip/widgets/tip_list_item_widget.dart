import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/tip/domain/models/tip_item_model.dart';
import 'package:quiksee/features/tip/screens/tip_order_detail_screen.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class TipListItemWidget extends StatelessWidget {
  final TipItemModel tip;

  const TipListItemWidget({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final isPending = tip.isPending;
    final statusColor = isPending ? Colors.orange : Colors.green;

    return InkWell(
      onTap: () => Get.to(() => TipOrderDetailScreen(orderId: tip.orderId!)),
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: .1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${'order'.tr} #${tip.orderId}',
                    style: rubikMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .12),
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeSmall),
                  ),
                  child: Text(
                    isPending ? 'tip_pending'.tr : 'tip_earned'.tr,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (tip.customerName != null)
              Padding(
                padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                child: Text(
                  tip.customerName!,
                  style: rubikRegular.copyWith(
                    color: Theme.of(context).hintColor,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),
            SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              children: [
                Icon(Icons.volunteer_activism,
                    size: Dimensions.iconSizeDefault, color: statusColor),
                SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  'customer_tip'.tr,
                  style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall),
                ),
                const Spacer(),
                Text(
                  tip.deliveryManTipFormatted ??
                      PriceConverter.convertPrice(tip.deliveryManTip),
                  style: rubikMedium.copyWith(color: statusColor),
                ),
              ],
            ),
            if ((tip.deliveryManTotalEarning ?? 0) > 0)
              Padding(
                padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                child: Row(
                  children: [
                    Text(
                      '${'total_earning'.tr}: ',
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    Text(
                      tip.deliveryManTotalEarningFormatted ??
                          PriceConverter.convertPrice(
                              tip.deliveryManTotalEarning),
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (tip.orderCreatedAt != null)
              Padding(
                padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                child: Text(
                  DateConverter.isoStringToLocalDateOnly(tip.orderCreatedAt!),
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
