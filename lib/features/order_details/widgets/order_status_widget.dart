import 'package:flutter/material.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:get/get.dart';

class OrderStatusWidget extends StatelessWidget {
  final OrderModel? orderModel;
  const OrderStatusWidget({super.key, this.orderModel});

  @override
  Widget build(BuildContext context) {
    final status = orderModel?.orderStatus;
    final key = OrderStatusHelper.labelKey(status);
    final text = key.isNotEmpty ? key.tr : OrderStatusHelper.label(status);
    final isDelivered = OrderStatusHelper.isDelivered(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeChat,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: isDelivered
            ? Theme.of(context)
                .colorScheme
                .onTertiaryContainer
                .withValues(alpha: 0.07)
            : Theme.of(context).primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeMin),
      ),
      child: Text(
        text,
        style: rubikMedium.copyWith(
          color: isDelivered
              ? Theme.of(context).colorScheme.onTertiaryContainer
              : Theme.of(context).primaryColor,
          fontSize: Dimensions.fontSizeSmall,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
