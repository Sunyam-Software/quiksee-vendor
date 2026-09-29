import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// Estimated delivery ETA card (Order Information design).
class EstimatedDeliveryCardWidget extends StatelessWidget {
  final OrderModel? orderModel;
  const EstimatedDeliveryCardWidget({super.key, this.orderModel});

  @override
  Widget build(BuildContext context) {
    final scheduledLabel =
        (orderModel?.scheduledDeliveryDisplayLabel ?? '').trim();
    final isScheduled = orderModel?.isScheduledDeliveryOrder == true &&
        scheduledLabel.isNotEmpty;
    final minutes = orderModel?.etaMinutes;
    final label = (orderModel?.etaLabel ?? '').trim();
    if (!isScheduled &&
        (minutes == null || minutes <= 0) &&
        label.isEmpty) {
      return const SizedBox.shrink();
    }
    final primary = Theme.of(context).primaryColor;
    final display = isScheduled
        ? scheduledLabel
        : (label.isNotEmpty ? label : '$minutes ${'mins'.tr}');
    final title = isScheduled
        ? 'scheduled_delivery'.tr
        : 'estimated_delivery'.tr;
    final badgeText = isScheduled ? 'scheduled'.tr : 'on_time'.tr;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
                isScheduled
                    ? Icons.schedule_rounded
                    : Icons.delivery_dining_rounded,
                color: primary,
                size: 30),
          ),
          SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Text(
                  display,
                  style: rubikBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: primary,
                  ),
                ),
                if (isScheduled && label.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 14, color: primary),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
