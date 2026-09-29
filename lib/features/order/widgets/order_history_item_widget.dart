import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee/features/distance_payment/widgets/delivery_distance_earning_widget.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order/widgets/scheduled_delivery_badge_widget.dart';
import 'package:quiksee/features/order_details/screens/order_details_screen.dart';
import 'package:quiksee/features/order_details/widgets/cal_chat_widget.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';


// class OrderHistoryItemWidget extends StatelessWidget {
//   final OrderModel? orderModel;
//   const OrderHistoryItemWidget({super.key, this.orderModel});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => Get.to(OrderDetailsScreen(orderModel: orderModel, fromNotification: false,)),
//       child: Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall,
//           bottom : Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
//         child: Container(padding:  EdgeInsets.all(Dimensions.paddingSizeSmall),
//           decoration: BoxDecoration(color: Theme.of(context).cardColor,
//             boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha:.125),
//               spreadRadius: .7, blurRadius: 2, offset: const Offset(0, 1))],
//             borderRadius: BorderRadius.circular(10),
//           ),
//
//           child: Stack(children: [
//               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   Padding(padding:  EdgeInsets.only(left: 7,top: Dimensions.paddingSizeSmall),
//                     child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
//                       Expanded(child: Text('${'order'.tr} #${orderModel!.id}',
//                         style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge,
//                           color:  (
//                             Get.find<ThemeController>().darkTheme ?
//                             ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.9):
//                             ColorHelper.darken(Theme.of(context).primaryColor, 0.1)
//                           )),
//                       )),
//
//                       CallAndChatWidget(orderModel: orderModel),
//                     ]),
//                   ),
//
//
//                 Padding(padding:  EdgeInsets.fromLTRB( Dimensions.paddingSizeDefault,
//                     Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 0),
//                   child: CustomerInfoWidget(orderModel: orderModel, showCustomerImage: true),
//                 ),
//
//                 Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
//                   child: Column(children: [
//                     Row(children: [
//
//                       SizedBox(width: Dimensions.iconSizeDefault, child: Image.asset(Images.calenderIcon,
//                           color: Get.find<ThemeController>().darkTheme ?Theme.of(context).hintColor.withValues(alpha:.5) :Theme.of(context).primaryColor.withValues(alpha:.5))),
//                       SizedBox(width: Dimensions.paddingSizeSmall),
//
//                       Text('${'assigned'.tr} : ',style: rubikRegular.copyWith(
//                           color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),),
//                       Text(DateConverter.isoStringToLocalDateOnly(orderModel!.createdAt!),
//                         style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black),
//                       ),
//                     ]),
//
//
//                     orderModel!.expectedDate != null?
//                     Padding(padding:  EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
//                       child: Row(children: [
//                         SizedBox(width: Dimensions.iconSizeDefault, child: Image.asset(Images.calenderIcon,
//                             color: Get.find<ThemeController>().darkTheme ?Theme.of(context).hintColor.withValues(alpha:.5) :Theme.of(context).primaryColor.withValues(alpha:.5))),
//                         SizedBox(width: Dimensions.paddingSizeSmall),
//                         Text('${'expected_date'.tr} : ',
//                           style: rubikRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),),
//                         Text(orderModel!.expectedDate!, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black))])): const SizedBox(),
//                     SizedBox(height: Dimensions.paddingSizeSmall,),
//                   ]),
//                 ),
//               ]),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


class OrderHistoryItemWidget extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF0F6B2D);
  static const Color _brandGold = Color(0xFFD4A62A);

  final OrderModel? orderModel;
  const OrderHistoryItemWidget({super.key, this.orderModel});

  @override
  Widget build(BuildContext context) {
    String customerName = orderModel?.isGuest == true
        ? '${orderModel!.billingAddress != null ? orderModel!.billingAddress?.contactPersonName : orderModel?.billingAddress?.contactPersonName}'
        : '${orderModel?.customer?.fName ?? ''} ${orderModel?.customer?.lName ?? ''}';
    final createdAt = orderModel?.createdAt;
    final assignedAtLabel = createdAt != null && createdAt.isNotEmpty
        ? DateConverter.localDateToIsoStringAMPM(DateTime.parse(createdAt))
        : '--';
    final bool isCombined = orderModel?.isCombinedCheckout == true;
    final String combineLabel =
        (orderModel?.combinedLabel?.trim().isNotEmpty == true)
            ? orderModel!.combinedLabel!.trim()
            : 'combine'.tr;
    final hideContact =
        OrderStatusHelper.shouldHideCustomerContact(orderModel?.orderStatus);

    return GestureDetector(
      onTap: () => Get.to(OrderDetailsScreen(orderModel: orderModel, fromNotification: false)),
      child: Container(
        margin: EdgeInsets.only(
          left: Dimensions.paddingSizeSmall,
          right: Dimensions.paddingSizeSmall,
          bottom: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: _brandGold.withValues(alpha: 0.90), width: 1.4),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _brandGold.withValues(alpha: 0.22),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: const Color(0xFFFFE08A).withValues(alpha: 0.35),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 0),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          orderModel!.displayOrderTitle,
                          style: rubikBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: _brandGreen,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCombined)
                        Container(
                          margin: EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _brandGold.withValues(alpha: 0.18),
                            border: Border.all(color: _brandGold, width: 1.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            combineLabel,
                            style: rubikBold.copyWith(
                              color: _brandGreen,
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                          ),
                        ),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _brandGreen.withValues(alpha: 0.08),
                          border: Border.all(color: _brandGold.withValues(alpha: 0.85), width: 1.1),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFE08A).withValues(alpha: 0.20),
                              blurRadius: 8,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Text(
                          () {
                            final key =
                                OrderStatusHelper.labelKey(orderModel!.orderStatus);
                            if (key.isNotEmpty) return key.tr;
                            return OrderStatusHelper.label(orderModel!.orderStatus);
                          }(),
                          style: rubikMedium.copyWith(
                            color: _brandGreen,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Text(
                    '${'assigned'.tr} : $assignedAtLabel',
                    style: rubikRegular.copyWith(color: _brandGreen.withValues(alpha: 0.70), fontSize: Dimensions.fontSizeSmall),
                  ),
                  if ((orderModel?.orderTransferReceived ?? 0) == 1) ...[
                    SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                        vertical: 6,
                      ),
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
                  ],
                  if (isCombined && (orderModel?.displayStoreName?.isNotEmpty ?? false))
                    Padding(
                      padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                      child: Text(
                        orderModel!.displayStoreName!,
                        style: rubikMedium.copyWith(
                          color: _brandGreen.withValues(alpha: 0.85),
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 0.2, thickness: 1.1, color: _brandGold.withValues(alpha: 0.80)),


            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'customer_info'.tr,
                    style: rubikMedium.copyWith(
                      color: _brandGreen.withValues(alpha: 0.70),
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: QuikseeImageWidget(
                          image: '${orderModel!.customer?.imageFullUrl?.path}',
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: rubikBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: _brandGreen),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            if (!hideContact)
                              Text(
                                orderModel!.customerDeliveryAddressText ??
                                    'no_address_found'.tr,
                                style: rubikRegular.copyWith(
                                  color: _brandGreen.withValues(alpha: 0.70),
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      if (!hideContact)
                        CallAndChatWidget(orderModel: orderModel),
                    ],
                  ),
                ],
              ),
            ),


            Padding(
              padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: DeliveryDistanceEarningWidget(
                order: orderModel,
                compact: true,
                showTitle: false,
              ),
            ),

            if (orderModel!.scheduledDeliveryDisplayLabel != null)
              Padding(
                padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: ScheduledDeliveryBadgeWidget(order: orderModel),
              ),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              decoration: BoxDecoration(
                color: _brandGold.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          orderModel!.isScheduledDeliveryOrder
                              ? '${'scheduled_delivery'.tr} : '
                              : '${'expected_date'.tr} : ',
                          style: rubikRegular.copyWith(
                            color: _brandGreen.withValues(alpha: 0.75),
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            orderModel!.isScheduledDeliveryOrder
                                ? (orderModel!.scheduledDeliveryDisplayLabel ?? '--')
                                : (orderModel!.expectedDate != null
                                    ? DateConverter.formatDateToDayMonthYear(
                                        DateTime.parse(
                                            orderModel!.expectedDate!.split(' at ').first))
                                    : '--'),
                            style: rubikMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: _brandGreen,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    'view_details'.tr,
                    style: rubikMedium.copyWith(
                      color: _brandGreen,
                      fontSize: Dimensions.fontSizeLarge,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}