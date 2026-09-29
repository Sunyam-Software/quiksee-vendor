import 'package:flutter/material.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_details/widgets/order_status_widget.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/features/order/widgets/order_item_info_widget.dart';
import 'package:get/get.dart';

class OrderInfoWidget extends StatelessWidget {
  final OrderModel? orderModel;
  final OrderDetailsController? orderController;
  final bool fromDetails;
  const OrderInfoWidget({super.key, this.orderModel, this.orderController, this.fromDetails = false});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding:  EdgeInsets.symmetric(horizontal: Dimensions.rememberMeSizeDefault, vertical: Dimensions.paddingSizeMin),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [BoxShadow(
              color: Get.find<ThemeController>().darkTheme ? Colors.black.withValues(alpha:0.10) : Colors.grey[100]!,
              blurRadius: 5, spreadRadius: 1,
            )],
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeChat)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              SizedBox(width: 20, child: Image.asset(Images.orderInfo)),
              Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
                child: Text('order_info'.tr,style: rubikBold.copyWith(
                  color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha: 0.5) : Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSizeLarge,
                )),
              ),
            ]),

            OrderStatusWidget(orderModel: orderModel),
          ]),

          Column(children: [
            OrderItemInfoWidget(title: 'order_id', info: '#${orderModel?.id ?? '--'}', textStyle: rubikMedium.copyWith(
              color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.60),
              fontSize: Dimensions.fontSizeSmall,
            )),

            OrderItemInfoWidget(
              title: 'order_placed',
              info: orderModel?.updatedAt ?? orderModel?.createdAt ?? '',
              isDate: (orderModel?.updatedAt ?? orderModel?.createdAt)?.isNotEmpty == true,
              textStyle: rubikMedium.copyWith(
                color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.60),
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),

            OrderItemInfoWidget(
              title: 'payment',
              info: orderModel?.paymentMethod ?? '-',
              textStyle: rubikMedium.copyWith(
              color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.60),
              fontSize: Dimensions.fontSizeSmall,
            )),

            OrderItemInfoWidget(
              title: 'products',
              info: (orderController?.orderDetails?.length ?? 0).toString(),
              isProduct: true,
            ),
          ])
        ]),
    );
  }
}
