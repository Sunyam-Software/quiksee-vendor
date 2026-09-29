import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee/features/review/screens/review_screen.dart';

class OrderDeliveredScreen extends StatelessWidget {
  final OrderModel? orderModel;
  final String? orderID;
  const OrderDeliveredScreen({super.key, this.orderID, this.orderModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Padding(padding:  EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Spacer(),
              Image.asset(Images.orderCompletedImage),
               SizedBox(height: Dimensions.paddingSizeLarge),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('order_delivered'.tr, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                  Padding(padding:  EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    child: Text('successfully'.tr,
                      style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge,
                          color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor)))]),
               SizedBox(height: Dimensions.paddingSizeOverLarge),


              InkWell(onTap: ()=> Get.to(ReviewScreen(orderModel: orderModel)),
                child: Container(width : 150, decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha:.05),
                  borderRadius: BorderRadius.circular(Dimensions.fontSizeExtraLarge),),
                  padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,vertical: Dimensions.paddingSizeExtraSmall),
                  child: Center(child: Text('see_review'.tr,
                      style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight : Theme.of(context).primaryColor, decoration: TextDecoration.underline))))),
               SizedBox(height: Dimensions.topSpace),


              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: QuikseeButtonWidget(btnTxt: 'dashboard'.tr,
                  onTap: () async {
                    await Get.find<ProfileController>().refreshAfterDelivery();
                    final orders = Get.find<OrderController>();
                    unawaited(orders.refreshAssignedOrderHistory());
                    unawaited(orders.getAllOrderHistory(
                      orders.dateType,
                      'delivered',
                      '',
                      '',
                      '',
                      0,
                      force: true,
                    ));
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(pageIndex: 0),
                      ),
                      (route) => false,
                    );
                  }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
