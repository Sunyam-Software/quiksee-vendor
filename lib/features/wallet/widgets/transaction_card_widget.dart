import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_divider_widget.dart';
import 'package:quiksee/features/wallet/domain/models/delivery_wise_earned_model.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';

class TransactionCardWidget extends StatelessWidget {
  final Orders orders;
  final int? index;
  final int? length;
  const TransactionCardWidget({super.key, required this.orders, this.index, this.length});

  @override
  Widget build(BuildContext context) {
    return Container(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeMin,
      Dimensions.paddingSizeSmall,Dimensions.paddingSizeDefault,Dimensions.paddingSizeSmall,),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Row(children: [
        SizedBox(width:Dimensions.iconSizeDefault,child: Image.asset(Images.assigned)),

        Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
          child: Text('${'order'.tr} # ${orders.id}',
            style: rubikMedium.copyWith(color: Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.5) :
                Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeLarge)))]),

      Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeOverLarge,0,0,0,),
        child: Row(children: [
          Expanded(child: Text(DateConverter.isoStringToDateTimeString(orders.updatedAt!).toString(),
            style: rubikRegular.copyWith(color: Theme.of(context).hintColor,fontSize: Dimensions.fontSizeSmall),)),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(50),
            color: Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha:.1)),
          padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,vertical: Dimensions.paddingSizeExtraSmall),
            child: Row(children: [
                Text('delivery_man_fee'.tr,style: rubikRegular.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer)),
                Text(' ${PriceConverter.convertPrice(orders.effectiveDeliveryEarning)}',
                    style: rubikMedium.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer))]))])),

      if (orders.deliveryDistanceInfo?.shouldShowDistanceBreakdown == true)
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeOverLarge,
            Dimensions.paddingSizeExtraSmall,
            Dimensions.paddingSizeDefault,
            0,
          ),
          child: Text(
            '${orders.deliveryDistanceInfo!.displayDistance.toStringAsFixed(1)} ${'km'.tr}',
            style: rubikRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),

      if (orders.hasTip)
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeOverLarge,
            Dimensions.paddingSizeExtraSmall,
            Dimensions.paddingSizeDefault,
            0,
          ),
          child: Row(
            children: [
              Icon(Icons.volunteer_activism,
                  size: Dimensions.fontSizeSmall, color: Colors.amber.shade700),
              SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                '${'customer_tip'.tr}: ${orders.deliveryManTipFormatted ?? PriceConverter.convertPrice(orders.deliveryManTip)}',
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
        ),

       Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeOverLarge,0,Dimensions.paddingSizeDefault,0,),
        child: Text(PriceConverter.convertPrice(orders.orderAmount),
            style: rubikMedium.copyWith(color: Get.isDarkMode?
            Theme.of(context).hintColor.withValues(alpha:.5) :Theme.of(context).primaryColor))),

      ((index!+1) < length!) ? Padding(padding:  EdgeInsets.only(top: Dimensions.paddingSizeSmall),
        child: QuikseeDividerWidget(height: .5, color: Theme.of(context).hintColor)) : const SizedBox.shrink()],),);
  }
}
