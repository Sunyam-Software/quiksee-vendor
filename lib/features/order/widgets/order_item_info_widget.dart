import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_details/widgets/ordered_product_list_view_widget.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
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
  final TextStyle? textStyle;
  final TextStyle? titleTextStyle;
  const OrderItemInfoWidget({super.key, this.title, this.info, this.isProduct = false,
    this.isDate = false, this.isDeliveryCost = false, this.isPrice = false,
    this.isCount = false, this.textColor, this.textStyle, this.titleTextStyle});

  int _lineItemQty() {
    final details = Get.find<OrderDetailsController>().orderDetails;
    if (details == null || details.isEmpty) return 0;
    return details.first.qty ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isCount ? Text(
              '${title!.tr} (*${_lineItemQty()})',
              style: titleTextStyle ?? rubikRegular.copyWith(
                color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                fontSize: Dimensions.fontSizeSmall
              ),
          ) :

          isDeliveryCost?
          Text(title!.tr, style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeSmall)):
          Text(title!.tr, style: titleTextStyle ?? rubikRegular.copyWith(
              color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
              fontSize: Dimensions.fontSizeSmall,
          )),
          SizedBox(width: Dimensions.paddingSizeDefault),

          isProduct?
          InkWell(
            splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
            onTap: () => Get.bottomSheet(
              OrderedItemProductListWidget(orderController: Get.find<OrderDetailsController>()),
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              clipBehavior: Clip.none,
              enableDrag: true,
            ),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
              color: Theme.of(context).primaryColor.withValues(alpha:.075)),
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions (
                  color:Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.5) : Theme.of(context).primaryColor.withValues(alpha: 0.30),
                  radius: const Radius.circular(45),
                ),
                child: Container(
                    padding:  EdgeInsets.only(
                      left: Dimensions.paddingSizeSmall,
                      right: Dimensions.paddingSizeMin,
                      top: Dimensions.paddingSizeExtraSmall,
                      bottom: Dimensions.paddingSizeExtraSmall,
                    ),
                    child: Row( children: [
                      Text('${'item'.tr} x $info',style: rubikBold.copyWith(
                          color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor,
                          fontSize: Dimensions.fontSizeSmall,
                      )),
                      SizedBox(width: Dimensions.paddingSizeSmall),

                      QuikseeAssetImageWidget(Images.infoCircleIcon, height: 14, width: 14, color:Get.isDarkMode ?
                      Theme.of(context).hintColor : Theme.of(context).primaryColor),
                    ])),
              )
            ),
          ) :


          isDeliveryCost?
          DottedBorder(
            options: RoundedRectDottedBorderOptions (
              color: Theme.of(context).primaryColor,
              radius: const Radius.circular(45),
            ),
            child: Container(
              color: Theme.of(context).primaryColor.withValues(alpha:.05),
              padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
              child: Row( children: [
                Text(PriceConverter.convertPrice(double.parse(info!)), style: rubikMedium.copyWith(
                  color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black,
                  fontSize: Dimensions.fontSizeSmall,
                )),
              ]),
            ),
          ) :


          isDate ?
          Directionality(
            textDirection: TextDirection.ltr,
            child:  Text(
              (info != null && info!.trim().isNotEmpty && info != 'null')
                  ? DateConverter.isoStringToDateTimeString(info!)
                  : '--',
              style: textStyle ?? rubikMedium.copyWith(
                color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.70),
                fontSize: Dimensions.fontSizeSmall,
              )
            ),
          ) :
          isPrice ?
          Row(
            children: [
              Text(PriceConverter.convertPrice(double.parse(info!)), style: textStyle ?? rubikMedium.copyWith(
                color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).textTheme.bodyLarge!.color?.withValues(alpha: 0.70),
                fontSize: Dimensions.fontSizeSmall,
              ))
            ],
          ) :
          Flexible(child: Text(
            (info ?? '').tr,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.clip,
            style: textStyle ?? rubikMedium.copyWith(
              color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black,
              fontSize: Dimensions.fontSizeSmall,
            ),
          )),
        ],
      ),
    );
  }
}