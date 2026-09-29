import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// Multi-store pickup path: Store 1 → Store 2 → … → Customer.
class PickupSequenceWidget extends StatelessWidget {
  final OrderModel orderModel;

  const PickupSequenceWidget({super.key, required this.orderModel});

  @override
  Widget build(BuildContext context) {
    if (!orderModel.isCombinedCheckout) {
      final eta = orderModel.etaLabel;
      if (eta == null || eta.isEmpty) {
        return const SizedBox.shrink();
      }
      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Text(
          eta,
          style: rubikMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: theme.primaryColor,
          ),
        ),
      );
    }

    final stops = List<OrderModel>.from(orderModel.combinedOrders ?? const []);
    if (stops.length < 2) {
      return const SizedBox.shrink();
    }
    stops.sort((a, b) {
      final as = a.pickupSequence ?? a.id ?? 0;
      final bs = b.pickupSequence ?? b.id ?? 0;
      return as.compareTo(bs);
    });

    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup sequence',
            style: rubikMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Get.isDarkMode ? theme.hintColor : Colors.black,
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            'Pick up from each store in order, then deliver to customer.',
            style: rubikRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: theme.hintColor,
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                if (!Get.isRegistered<RiderController>()) return;
                final ok = await Get.find<RiderController>()
                    .openExternalNavigation(
                  orderId: orderModel.id,
                  order: orderModel,
                );
                if (!ok) {
                  Get.snackbar(
                    'navigation'.tr,
                    'could_not_open_maps'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: Text(
                'navigate_all_stops'.tr.isNotEmpty &&
                        'navigate_all_stops'.tr != 'navigate_all_stops'
                    ? 'navigate_all_stops'.tr
                    : 'Navigate all stops',
                style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeSmall),
          ...List.generate(stops.length, (index) {
            final stop = stops[index];
            final seq = stop.pickupSequence ?? (index + 1);
            final storeName = stop.sellerInfo?.shop?.name ??
                stop.storeName ??
                stop.displayStoreName ??
                'Store';
            final status = (stop.orderStatus ?? '').toLowerCase();
            final done = _isPickupDone(status);
            final current =
                _isCurrentPickup(status) && !_anyEarlierPending(stops, index);
            final eta = (stop.etaLabel != null && stop.etaLabel!.isNotEmpty)
                ? stop.etaLabel!
                : null;
            final subtitle = eta != null
                ? '#${stop.id} · ${_statusLabel(status)} · $eta'
                : '#${stop.id} · ${_statusLabel(status)}';

            return _SequenceRow(
              index: seq,
              title: storeName,
              subtitle: subtitle,
              isDone: done,
              isCurrent: current,
              isLast: false,
            );
          }),
          _SequenceRow(
            index: stops.length + 1,
            title: 'Deliver to customer',
            subtitle: orderModel.shippingAddress?.address ??
                orderModel.customer?.fName ??
                'Customer',
            isDone: (orderModel.orderStatus ?? '').toLowerCase() == 'delivered',
            isCurrent:
                (orderModel.orderStatus ?? '').toLowerCase() == 'out_for_delivery',
            isLast: true,
          ),
        ],
      ),
    );
  }

  bool _isPickupDone(String status) {
    return status == 'out_for_delivery' ||
        status == 'delivered' ||
        status == 'processing' ||
        status == 'reached_restaurant';
  }

  bool _isCurrentPickup(String status) {
    return status == 'confirmed' || status == 'pending' || status == 'assigned';
  }

  bool _anyEarlierPending(List<OrderModel> stops, int index) {
    for (var i = 0; i < index; i++) {
      final s = (stops[i].orderStatus ?? '').toLowerCase();
      if (_isCurrentPickup(s)) return true;
    }
    return false;
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Pending';
    return status.replaceAll('_', ' ');
  }
}

class _SequenceRow extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _SequenceRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDone
        ? Colors.green
        : (isCurrent ? theme.primaryColor : theme.hintColor);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: isDone
                    ? Icon(Icons.check, size: 16, color: color)
                    : Text(
                        '$index',
                        style: rubikMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: color,
                        ),
                      ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 22,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: theme.dividerColor,
                ),
            ],
          ),
          SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Get.isDarkMode ? theme.hintColor : Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: theme.hintColor,
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
