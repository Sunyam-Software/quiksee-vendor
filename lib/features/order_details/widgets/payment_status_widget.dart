import 'package:flutter/material.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:get/get.dart';

class PaymentStatusWidget extends StatelessWidget {
  final String isPaid;
  const PaymentStatusWidget({super.key, this.isPaid = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeChat, vertical: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: isPaid == "paid"
          ? Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha: 0.07)
          : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeMin),
      ),
      child: Text(isPaid == "paid" ? 'paid'.tr : isPaid == "partially_paid"  ? 'partially_paid'.tr : 'unpaid_payment_status'.tr, style: rubikMedium.copyWith(
        color: isPaid == "paid"
          ? Theme.of(context).colorScheme.onTertiaryContainer
          : Theme.of(context).colorScheme.secondary,
        fontSize: Dimensions.fontSizeSmall
      )),
    );
  }


}
