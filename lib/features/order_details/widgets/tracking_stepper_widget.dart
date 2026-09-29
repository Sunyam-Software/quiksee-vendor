import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/common/basewidgets/quiksee_stepper_widget.dart';

class TrackingStepperWidget extends StatelessWidget {
  final String? status;
  final int? orderId;
  const TrackingStepperWidget({
    super.key,
    required this.status,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyReached = Get.isRegistered<OrderDetailsController>() &&
        Get.find<OrderDetailsController>().hasReachedRestaurant(orderId);
    final s = OrderStatusHelper.normalize(status);

    int step = -1;
    if (s == OrderStatusHelper.confirmed) {
      step = alreadyReached ? 1 : 0;
    } else if (s == OrderStatusHelper.reachedRestaurant) {
      step = 1;
    } else if (s == OrderStatusHelper.processing ||
        s == OrderStatusHelper.outForDelivery) {
      step = 2;
    } else if (s == OrderStatusHelper.delivered) {
      step = 3;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        QuikseeStepperWidget(
          title: 'order_confirmed'.tr,
          isActive: step > -1,
          hasLeftBar: false,
          hasRightBar: true,
          rightActive: step > 0,
          icon: Images.orderConfirmationIcon,
        ),
        QuikseeStepperWidget(
          title: 'reached_restaurant'.tr,
          isActive: step > 0,
          hasLeftBar: true,
          hasRightBar: true,
          rightActive: step > 1,
          icon: Images.reachedIcon,
        ),
        QuikseeStepperWidget(
          title: 'order_processing'.tr,
          isActive: step > 1,
          hasLeftBar: true,
          hasRightBar: true,
          rightActive: step > 2,
          icon: Images.orderProcessingIcon,
        ),
        QuikseeStepperWidget(
          title: 'delivered'.tr,
          isActive: step > 2,
          hasLeftBar: true,
          hasRightBar: false,
          rightActive: step > 3,
          icon: Images.orderDeliveredIcon,
        ),
      ]),
    );
  }
}
