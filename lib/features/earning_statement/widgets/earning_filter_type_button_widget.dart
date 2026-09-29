import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class EarningFilterTypeButtonWidget extends StatelessWidget {
  final String text;
  final int index;
  const EarningFilterTypeButtonWidget({super.key, required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: (){
        Get.find<WalletController>().setEarningFilterIndex(index);
      },
      child: GetBuilder<WalletController>(builder: (order) {
        return Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall, vertical: Dimensions.paddingSizeExtraSmall),
          child: Container(
            padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeChat,),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: order.orderTypeFilterIndex == index ? Get.isDarkMode ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
            child: Text(text, style: order.orderTypeFilterIndex == index ?
            rubikMedium.copyWith(color: order.orderTypeFilterIndex == index ?
            Colors.white : Theme.of(context).textTheme.bodyLarge as Color?):
            rubikRegular.copyWith(color: order.orderTypeFilterIndex == index ?
            Theme.of(context).cardColor :Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.5) :
            Theme.of(context).primaryColor.withValues(alpha:.75), fontWeight: FontWeight.w500)),
          ),
        );
      },
      ),
    );
  }
}