import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class ScheduledDeliveryBadgeWidget extends StatelessWidget {
  final OrderModel? order;
  final bool compact;

  const ScheduledDeliveryBadgeWidget({
    super.key,
    required this.order,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final label = order?.scheduledDeliveryDisplayLabel;
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    final color = Theme.of(context).primaryColor;

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
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded,
                size: Dimensions.iconSizeDefault, color: color),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'scheduled_delivery'.tr}: $label',
                    style: rubikMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (order?.scheduledDelivery?.displayPickupNote != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Pickup: ${order!.scheduledDelivery!.displayPickupNote}',
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        boxShadow: [
          BoxShadow(
            color: Get.isDarkMode
                ? Colors.black.withValues(alpha: 0.10)
                : Colors.grey[100]!,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded,
              color: color, size: Dimensions.iconSizeDefault),
          SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'scheduled_delivery'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: color,
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  label,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (order?.scheduledDelivery?.displayPickupNote != null) ...[
                  SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    '${'Pickup point'}: ${order!.scheduledDelivery!.displayPickupNote}',
                    style: rubikMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
