import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/live_tracking/screens/order_navigation_sdk_screen.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/screens/order_details_screen.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/distance_payment/widgets/delivery_distance_earning_widget.dart';
import 'package:quiksee/features/order/widgets/new_order_action_buttons_widget.dart';
import 'package:quiksee/features/home/widgets/on_going_order_header_widget.dart';
import 'package:quiksee/features/home/widgets/receiver_widget.dart';
import 'package:quiksee/features/order_details/widgets/food_pickup_otp_card_widget.dart';
import 'package:quiksee/utill/styles.dart';


class OnGoingOrderWidget extends StatelessWidget {
  final OrderModel? orderModel;
  final int? index;
  const OnGoingOrderWidget({super.key, this.orderModel, this.index});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      final order = orderModel;
      if (order == null) return const SizedBox.shrink();

      final bool needsAccept = orderController.needsAcceptForOrder(order);
      final int? orderId = order.id;

    return Padding(padding:  EdgeInsets.fromLTRB(0, 0, 0, Dimensions.paddingSizeSmall),
      child: Container(decoration: BoxDecoration(color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        boxShadow:  [BoxShadow(color: Get.find<ThemeController>().darkTheme ? Colors.black.withValues(alpha:0.10) : Colors.grey.shade100,
            blurRadius: 15, spreadRadius: 0, offset: const Offset(0,2))],),
        padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),

        child: ExpandableNotifier(
          initialExpanded: index == 0 ? true : false,
          child: Column(children: [
            if (needsAccept && orderId != null)
              Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  0,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                ),
                padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                  border: Border.all(color: Colors.orange.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'accept_order_to_start'.tr,
                      style: rubikMedium.copyWith(color: Colors.orange.shade900),
                    ),
                    SizedBox(height: Dimensions.paddingSizeSmall),
                    NewOrderActionButtonsWidget(orderId: orderId),
                  ],
                ),
              ),
            Expandable(collapsed: ExpandableButton(
              child: Column(children: [
                OngoingOrderHeaderWidget(orderModel: order,index: index)])),

                expanded: Column(children: [
                  InkWell(onTap: () {
                    Get.to(()=>OrderDetailsScreen(orderModel: order, fromNotification: false));
                    Get.find<OrderController>().selectedOrderLatLng(order.shippingAddress?.latitude??'23',
                      order.shippingAddress?.longitude??'90');
                  },
                  child: OngoingOrderHeaderWidget(orderModel: order, index: index, isExpanded: true)),

                  Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // Store Pickup OTP only after Reach Store/Hub.
                      FoodPickupOtpCardWidget(
                        orderModel: order,
                      ),

                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [

                        SizedBox(width: Dimensions.iconSizeDefault, child: Image.asset(Images.calenderIcon,
                          color:Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.25) :
                          Theme.of(context).primaryColor.withValues(alpha:.5))),
                        SizedBox(width: Dimensions.paddingSizeSmall),
                        Text('${'assigned'.tr} : ', style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),),
                        if (order.createdAt != null && order.createdAt!.isNotEmpty)
                          Text(
                            DateConverter.isoStringToLocalDateOnly(
                              order.createdAt!,
                            ),
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Get.isDarkMode
                                  ? Theme.of(context).hintColor
                                  : Colors.black,
                            ),
                          ),
                      ]),


                      if (order.isScheduledDeliveryOrder &&
                          order.scheduledDeliveryDisplayLabel != null)
                        Padding(
                          padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: Dimensions.iconSizeDefault,
                                child: Icon(
                                  Icons.schedule_rounded,
                                  size: Dimensions.iconSizeDefault,
                                  color: Get.isDarkMode
                                      ? Theme.of(context).hintColor.withValues(alpha: .25)
                                      : Theme.of(context).primaryColor.withValues(alpha: .5),
                                ),
                              ),
                              SizedBox(width: Dimensions.paddingSizeSmall),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: rubikRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Get.isDarkMode
                                          ? Theme.of(context).hintColor
                                          : Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${'scheduled_delivery'.tr} : ',
                                        style: rubikRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                      TextSpan(text: order.scheduledDeliveryDisplayLabel!),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (order.expectedDate != null)
                        Padding(padding:  EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                          child: Row(children: [
                            SizedBox(width: Dimensions.iconSizeDefault, child: Image.asset(Images.calenderIcon,
                              color: Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.25) :
                              Theme.of(context).primaryColor.withValues(alpha:.5))),
                            SizedBox(width: Dimensions.paddingSizeSmall),
                            Text('${'expected_date'.tr} : ', style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),),
                            Text(order.expectedDate??'', style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black))]),
                        )
                      else
                        const SizedBox(),
                    ])),


                  Padding(
                    padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    child: GetBuilder<DistancePaymentController>(
                      builder: (_) => DeliveryDistanceEarningWidget(
                        order: order,
                        compact: true,
                      ),
                    ),
                  ),

                  SizedBox(height: Dimensions.paddingSizeSmall,),
                  Get.find<SplashController>().configModel?.mapApiStatus == 1 ?
                  GestureDetector(onTap: () => Get.to(()=> OrderNavigationSdkScreen(orderModel: order)),
                    child: Container(height: Get.width/3,
                      padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: Image.asset(Images.previewMap, fit: BoxFit.fill))) : const SizedBox(),

                  ReceiverWidget(orderModel: order),

                  ExpandableButton(child: Container(decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Get.isDarkMode? Theme.of(context).hintColor.withValues(alpha:.25) : Theme.of(context).primaryColor.withValues(alpha:.08),),
                      padding:  EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                      child:  Icon(Icons.keyboard_arrow_up, size: Dimensions.iconSizeMenu, color: Get.isDarkMode? Theme.of(context).hintColor : Theme.of(context).primaryColor),
                  ),),
                ]),

              ),
            ],
          ),
        ),
      ),
    );
    });
  }
}


