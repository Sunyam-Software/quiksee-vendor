import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class OrderItemInfoWidget extends StatelessWidget {
  final String? title;
  final String? info;
  final bool isProduct;
  final bool isDate;
  final bool isDeliveryCost;
  final bool isPrice;
  final bool isCount;
  final Color? textColor;
  const OrderItemInfoWidget({super.key, this.title, this.info, this.isProduct = false,
    this.isDate = false, this.isDeliveryCost = false, this.isPrice = false,
    this.isCount = false, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,children: [
          isCount? Text(title!.tr + ' (*${Get.find<OrderDetailsController>().orderDetails!.length})',
              style: rubikMedium.copyWith(color: Theme.of(context).hintColor)):
          isDeliveryCost?
        Text(title!.tr, style: rubikMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color)):
          Text(title!.tr, style: rubikMedium.copyWith(color: textColor?? Theme.of(context).hintColor)),
         SizedBox(width: Dimensions.paddingSizeDefault),

        isProduct?
        Container(decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
          color: Theme.of(context).primaryColor.withValues(alpha:.075)),
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions (
              color:Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.5) : Theme.of(context).primaryColor,
              radius: const Radius.circular(45),
            ),
            child: Container(color: Theme.of(context).primaryColor.withValues(alpha:.05),
              padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
              child: Row( children: [
                Text('${'item'.tr} x $info',style: rubikMedium.copyWith(color:Get.isDarkMode?
                Theme.of(context).hintColor.withValues(alpha:.5) : Theme.of(context).primaryColor),),
                 SizedBox(width: Dimensions.paddingSizeSmall,),
                Icon(Icons.info_outline, size: 20, color:Get.isDarkMode?
                Theme.of(context).hintColor.withValues(alpha:.5) : Theme.of(context).primaryColor.withValues(alpha:.5))])))):

        isDeliveryCost?
        DottedBorder(
          options: RoundedRectDottedBorderOptions (
            color: Theme.of(context).primaryColor,
            radius: const Radius.circular(45),
          ),
          child: Container(color: Theme.of(context).primaryColor.withValues(alpha:.05),
            padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
            child: Row( children: [
              Text(PriceConverter.convertPrice(double.parse(info!)),style: rubikMedium)]))):


        isDate?
        Directionality(textDirection: TextDirection.ltr,
            child: Text(DateConverter.isoStringToDateTimeString(info!),style: rubikRegular.copyWith())):

        isPrice?
        Text(PriceConverter.convertPrice(double.parse(info!)),style: rubikMedium.copyWith()):
        Flexible(child: Text(info!.tr,textAlign: TextAlign.right,maxLines: 2,overflow: TextOverflow.clip,style: rubikRegular.copyWith())),

      ],),
    );
  }
}