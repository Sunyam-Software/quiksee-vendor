import 'package:flutter/material.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';


class CustomerInfoWidget extends StatelessWidget {
  final bool showCustomerImage;
  final OrderModel? orderModel;
  final bool isShowShippingBilling;
  const CustomerInfoWidget({super.key, this.orderModel, this.showCustomerImage = false, this.isShowShippingBilling = false});

  @override
  Widget build(BuildContext context) {
    final hideContact =
        OrderStatusHelper.shouldHideCustomerContact(orderModel?.orderStatus);

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 14,child: Image.asset(Images.customerIcon)),
          const SizedBox(width: 8),
          showCustomerImage ?
          Text('customer_info'.tr,style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault,
              color: Get.isDarkMode? Theme.of(context).hintColor : Theme.of(context).primaryColor)) :

          Text('customer'.tr,style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).colorScheme.tertiary))],),


        Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeExtraLarge,
              top: Dimensions.paddingSizeExtraSmall, bottom: Dimensions.paddingSizeExtraSmall),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                  orderModel?.customer != null ?
                  Text('${orderModel?.customer?.fName??''} ${orderModel?.customer?.lName??''}',
                      style: robotoBold.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeSmall)) :
                      orderModel?.isGuest??false ?
                      Text(orderModel?.shippingAddress?.contactPersonName ?? '', style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).hintColor :
                      Theme.of(context).textTheme.bodyLarge?.color)):

                  Text('customer_deleted'.tr),
                   SizedBox(width: Dimensions.paddingSizeSmall),

                  (showCustomerImage && orderModel?.isGuest != true) ?
                  Container(decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha:.25),
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(30)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(30),
                      child: orderModel?.customer != null? QuikseeImageWidget(
                        image: '${orderModel?.customer?.imageFullUrl?.path}',
                        height: 20, width: 20, fit: BoxFit.cover):const SizedBox())): const SizedBox()]),


               SizedBox(height: Dimensions.paddingSizeExtraSmall),
              if (!hideContact &&
                  (orderModel?.customerDeliveryAddressText?.isNotEmpty == true ||
                      orderModel?.isGuest == true))
                  Text(
                      orderModel?.customerDeliveryAddressText ?? '',
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).hintColor)),
               SizedBox(height: Dimensions.paddingSizeSmall),


              (!hideContact && isShowShippingBilling)?
              Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${'shipping_address'.tr} : ', style: rubikMedium,),
                    Expanded(child: Text(orderModel?.customerDeliveryAddressText ?? '', style: rubikRegular))]),

                 SizedBox(height: Dimensions.paddingSizeSmall),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${'billing_address'.tr} : ', style: rubikMedium),
                    Expanded(child: Text(orderModel!.billingAddress?.address ?? '', style: rubikRegular))]),
              ]) : const SizedBox(),
            ],
          ),
        ),
      ],),
    );
  }
}
