import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class OrderTypeButtonWidget extends StatelessWidget {
  final String text;
  final int index;
  const OrderTypeButtonWidget({super.key, required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: (){
      Get.find<OrderController>().setOrderTypeIndex(index);
      Get.find<WalletController>().selectDate();
    },
      child: GetBuilder<OrderController>(builder: (order) {
        return Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall,
            vertical: Dimensions.paddingSizeDefault),
          child: Container(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,),
            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: order.orderTypeIndex == index ? Get.isDarkMode ?
                Theme.of(context).hintColor.withValues(alpha:.5) : Theme.of(context).primaryColor :
                Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge)
            ),

            child: Text(text,
              style: order.orderTypeIndex == index ?
              rubikMedium.copyWith(color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha: 1) : Theme.of(context).cardColor) :
              rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor),
            ),

          ),
        );
      },),
    );
  }
}