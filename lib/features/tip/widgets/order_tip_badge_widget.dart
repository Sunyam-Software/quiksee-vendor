import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/tip/domain/models/tip_item_model.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class OrderTipBadgeWidget extends StatelessWidget {
  final OrderModel? order;
  final TipItemModel? tipItem;
  final bool compact;

  const OrderTipBadgeWidget({
    super.key,
    this.order,
    this.tipItem,
    this.compact = true,
  });

  double? get _tipAmount =>
      tipItem?.deliveryManTip ?? order?.deliveryManTip;

  String? get _tipFormatted =>
      tipItem?.deliveryManTipFormatted ?? order?.deliveryManTipFormatted;

  String? get _tipStatus => tipItem?.tipStatus ?? order?.tipStatus;

  @override
  Widget build(BuildContext context) {
    final tip = _tipAmount ?? 0;
    if (tip <= 0) return const SizedBox.shrink();

    final isPending = _tipStatus == 'pending';
    final color = isPending ? Colors.orange : Colors.green;

    if (compact) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Row(
          children: [
            Icon(Icons.volunteer_activism,
                size: Dimensions.iconSizeDefault, color: color),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text(
                'customer_tip'.tr,
                style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall),
              ),
            ),
            Text(
              _tipFormatted ?? PriceConverter.convertPrice(tip),
              style: rubikMedium.copyWith(color: color),
            ),
            if (isPending) ...[
              SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Icon(Icons.schedule,
                  size: Dimensions.fontSizeSmall, color: color),
            ],
          ],
        ),
      );
    }

    return _tipDetailCard(context, tip, color, isPending);
  }

  Widget _tipDetailCard(
      BuildContext context, double tip, Color color, bool isPending) {
    final deliveryCharge = tipItem?.deliverymanCharge ??
        order?.deliveryManCharge ??
        order?.deliveryDistanceInfo?.deliverymanCharge;
    final totalEarning = tipItem?.deliveryManTotalEarning ??
        order?.deliveryManTotalEarning;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        color: Theme.of(context).cardColor,
      ),
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism,
                  color: color, size: Dimensions.iconSizeDefault),
              SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'customer_tip'.tr,
                style: rubikMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.paddingSizeSmall),
          if (deliveryCharge != null && deliveryCharge > 0)
            _line(context, 'delivery_fee'.tr,
                PriceConverter.convertPrice(deliveryCharge)),
          _line(
            context,
            'customer_tip'.tr,
            _tipFormatted ?? PriceConverter.convertPrice(tip),
          ),
          if (totalEarning != null && totalEarning > 0) ...[
            Divider(height: Dimensions.paddingSizeLarge),
            _line(
              context,
              'total_earning'.tr,
              PriceConverter.convertPrice(totalEarning),
              isBold: true,
            ),
          ],
          Padding(
            padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                Icon(
                  isPending ? Icons.schedule : Icons.check_circle,
                  size: Dimensions.iconSizeSmall,
                  color: color,
                ),
                SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Expanded(
                  child: Text(
                    isPending ? 'tip_pending_note'.tr : 'tip_earned_note'.tr,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value,
      {bool isBold = false}) {
    final style = isBold ? rubikMedium : rubikRegular;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
