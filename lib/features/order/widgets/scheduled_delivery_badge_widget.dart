import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/scheduled_delivery_model.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class ScheduledDeliveryBadgeWidget extends StatelessWidget {
  final ScheduledDeliveryInfo? schedule;
  final bool compact;

  const ScheduledDeliveryBadgeWidget({
    super.key,
    required this.schedule,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (schedule == null || !schedule!.isScheduled) {
      return const SizedBox.shrink();
    }

    final Color bg = Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45);
    final Color fg = Theme.of(context).colorScheme.primary;

    return Container(
      width: compact ? null : double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, size: 16, color: fg),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  schedule!.displayBadgeText,
                  style: robotoMedium.copyWith(
                    color: fg,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
                if (!compact && schedule!.riderTimingNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    schedule!.riderTimingNote!,
                    style: robotoMedium.copyWith(
                      color: fg.withValues(alpha: 0.85),
                      fontSize: Dimensions.fontSizeExtraSmall,
                      fontWeight: FontWeight.w400,
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
