import 'package:flutter/material.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/widgets/order_item_info_widget.dart';


class DeliveryInfoWidget extends StatelessWidget {
  final OrderModel? orderModel;
  final int? index;
  const DeliveryInfoWidget({super.key, this.orderModel, this.index});

  @override
  Widget build(BuildContext context) {
    if (orderModel == null) return const SizedBox.shrink();

    final hideContact =
        OrderStatusHelper.shouldHideCustomerContact(orderModel?.orderStatus);
    final address = orderModel?.resolvedCustomerShipping ?? orderModel?.shippingAddress;
    final hasName = address?.contactPersonName?.trim().isNotEmpty ?? false;
    final hasPhone = !hideContact &&
        (address?.phone?.trim().isNotEmpty ?? false);
    final hasAddress = !hideContact &&
        ((orderModel?.customerDeliveryAddressText?.trim().isNotEmpty ?? false) ||
            (address?.address?.trim().isNotEmpty ?? false));
    final hasContact = hasName || hasPhone || hasAddress;

    return Container(
      padding:  EdgeInsets.symmetric(horizontal:Dimensions.rememberMeSizeDefault, vertical: Dimensions.paddingSizeMin),
      decoration: BoxDecoration(color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeChat),
        boxShadow: [BoxShadow(color: Get.find<ThemeController>().darkTheme ? Colors.black.withValues(alpha:0.10) : Colors.grey[100]!,
          blurRadius: 5, spreadRadius: 1)]),


      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [

          SizedBox(width: 20, child: Image.asset(Images.customerIcon)),

          Padding(
              padding:  EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeDefault,
              ),
              child: Text('delivery_info'.tr,style: rubikMedium.copyWith(color: Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSizeLarge
              )),
          ),
        ]),

        hasContact ?
        Column(children: [
          if (hasName)
            OrderItemInfoWidget(title: 'name',info: address!.contactPersonName ?? '', textStyle: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color
            )),

          if (hasPhone)
            OrderItemInfoWidget(title: 'contact', info: address!.phone ?? '', textStyle: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color
            )),

          if (hasAddress)
            OrderItemInfoWidget(title: 'location', info:
            orderModel?.customerDeliveryAddressText ??
                '${address?.address ?? ''}, ${address?.city ?? ''}, ${address?.zip ?? ''}',
                textStyle: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).textTheme.bodyLarge?.color
                )
            ),
        ]) : const SizedBox.shrink(),

        SizedBox(height: Dimensions.paddingSizeDefault),
      ]),
    );
  }
}
