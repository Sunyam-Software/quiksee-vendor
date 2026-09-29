
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/widgets/customer_info_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/helper/string_extensions.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:timeago/timeago.dart' as timeago;

class OngoingOrderHeaderWidget extends StatelessWidget {
  final OrderModel? orderModel;
  final int? index;
  final bool isExpanded;
  const OngoingOrderHeaderWidget({super.key, this.orderModel, this.index, this.isExpanded = false});

  @override
  Widget build(BuildContext context) {

    String timeAgo = '--';
    final createdAt = orderModel?.createdAt;
    if (createdAt != null && createdAt.isNotEmpty) {
      timeAgo = timeago
          .format(DateConverter.isoStringToLocalDate(createdAt))
          .toCapitalized();
    }
    final inHouseShop = Get.find<SplashController>().configModel?.inHouseShop;

    return Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(orderModel?.displayOrderTitle ?? '${'order'.tr} # --',
                style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black)),
          ),
          if (orderModel?.isCombinedCheckout == true)
            Builder(
              builder: (context) {
                final label = orderModel?.combinedLabel?.trim();
                return Container(
                  margin: EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  child: Text(
                    (label != null && label.isNotEmpty) ? label : 'combine'.tr,
                    style: rubikBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              },
            ),

          const Expanded(child: SizedBox()),

          Padding(
            padding: EdgeInsets.only(right: Dimensions.paddingSizeMin),
            child: Text(timeAgo.toCapitalized(), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),),
          ),

          SizedBox(width: Dimensions.iconSizeDefault, height: Dimensions.iconSizeDefault, child: Image.asset(Images.assignedTime, color: Theme.of(context).hintColor,)),

        ]),
        if ((orderModel?.orderTransferReceived ?? 0) == 1) ...[
          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.shade700.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                () {
                  final from =
                      (orderModel?.orderTransferFromName ?? '').trim();
                  if (from.isNotEmpty) {
                    return 'Order transferred · From $from';
                  }
                  return 'Order transferred';
                }(),
                style: rubikMedium.copyWith(
                  color: Colors.orange.shade900,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ),
          ),
        ],
        if (orderModel?.etaLabel != null && orderModel!.etaLabel!.isNotEmpty) ...[
          SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderModel!.etaLabel!,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (orderModel?.etaBreakdown != null &&
                    orderModel!.etaBreakdown!.isNotEmpty)
                  Text(
                    orderModel!.etaBreakdown!,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
        SizedBox(height: Dimensions.paddingSizeDefault),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            SizedBox(width: Dimensions.iconSizeDefault, child: Image.asset(isExpanded ? Images.sellerIconExpand : Images.sellerIcon)),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Text('seller'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault,
                    color: Get.isDarkMode? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor))]),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Container(width: Dimensions.iconSizeSmall,height: Dimensions.iconSizeSmall,
                        color: Get.find<ThemeController>().darkTheme ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor)),

                SizedBox(width: Dimensions.paddingSizeDefault),
                Text(orderModel?.sellerIs == 'admin'
                    ? inHouseShop?.name ?? ''
                    : (orderModel?.isCombinedCheckout == true
                        ? (orderModel?.displayStoreName ?? '')
                        : orderModel?.sellerInfo?.shop?.name?.trim() ?? 'Shop not found'),
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black))
              ]),


              Row(children: [
                Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Container(width: Dimensions.iconSizeSmall,height: Dimensions.iconSizeSmall,
                        color: Get.find<ThemeController>().darkTheme ? Theme.of(context).colorScheme.primary : Theme.of(context).primaryColor)),

                SizedBox(width: MediaQuery.sizeOf(context).width <= 400 ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge),
                Expanded(child: Text(orderModel?.sellerIs == 'admin' ? inHouseShop?.address ?? '' : orderModel?.sellerInfo?.shop?.address ?? '',
                    maxLines: 2, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).hintColor))),
              ]),
              SizedBox(height: Dimensions.paddingSizeMin),

              Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.tertiary), width: Dimensions.iconSizeSmall,
                  height: Dimensions.iconSizeSmall,
                ),
              ),
            ])),
          ]),
        ]),
        SizedBox(height: Dimensions.paddingSizeExtraSmall),

        CustomerInfoWidget(orderModel: orderModel),


        isExpanded?const SizedBox():
        Container(padding:  EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50),
              color:Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.25) : Theme.of(context).primaryColor.withValues(alpha:.04)),
          child: Icon(Icons.keyboard_arrow_down,
              size: Dimensions.iconSizeMenu, color: Get.isDarkMode? Theme.of(context).hintColor : Theme.of(context).primaryColor),
        ),
      ]),
    );
  }
}