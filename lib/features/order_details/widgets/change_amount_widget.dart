import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class ChangeAmountWidget extends StatelessWidget {
  final double changeAmount;
  final String currency;

  const ChangeAmountWidget({super.key, required this.changeAmount, required this.currency});

  @override
  Widget build(BuildContext context) {

    return changeAmount == 0 ? const SizedBox() : Padding(
        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: .4),
              border: Border.all(width: 1, color: Theme.of(context).hintColor.withValues(alpha: .125),),
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'please_bring'.tr, style: robotoRegular),

                TextSpan(text: ' $changeAmount $currency ', style: robotoBold),

                TextSpan(text: 'change_amount_for_customer_when_making_delivery'.tr, style: robotoRegular),
              ],
            ),
          ),
        ),
      );
  }
}
