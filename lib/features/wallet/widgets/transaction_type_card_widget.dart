import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiksee/features/wallet/domain/models/transaction_type_model.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class TransactionCardWidget extends StatelessWidget {
  final TransactionTypeModel? transactionTypeModel;
  final int? selectedIndex;

  const TransactionCardWidget({super.key, this.selectedIndex, this.transactionTypeModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150, width:150, padding:  EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: transactionTypeModel?.index == selectedIndex ? Get.isDarkMode ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor :
          Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).cardColor,
          border: Border.all(color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.25) : Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
      ),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, children: [

          SizedBox(width: 30,child: Image.asset(transactionTypeModel!.icon,
              color: Get.isDarkMode ? Theme.of(context).primaryColorLight : transactionTypeModel!.index == selectedIndex ?
              Theme.of(context).cardColor : Theme.of(context).primaryColor)),

          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            NumberFormat.compact().format(double.parse(PriceConverter.convertPriceWithoutSymbol(context, transactionTypeModel!.amount))),
            style: rubikMedium.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight : transactionTypeModel!.index == selectedIndex ?
            Theme.of(context).cardColor : Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
          ),

          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
              transactionTypeModel!.title.tr,textAlign: TextAlign.center, maxLines: 2,
              style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight : transactionTypeModel!.index == selectedIndex ?
              Theme.of(context).cardColor : Theme.of(context).primaryColor),
          ),
        ]
      )),
    );
  }
}
