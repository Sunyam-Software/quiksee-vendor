import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiksee/features/dashboard/controllers/dashboard_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';

class TripStatusWidget extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF0F6B2D);
  static const Color _brandGreenLight = Color(0xFFD3E7D3);
  static const Color _brandGold = Color(0xFFA36A00);
  static const Color _brandGoldLight = Color(0xFFF1D18A);

  final Function(int index) onTap;
  const TripStatusWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(padding:  EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeExtraLarge,vertical: Dimensions.paddingSizeExtraSmall),
      child: GetBuilder<OrderController>(
        builder: (orderController) {
          return GetBuilder<ProfileController>(
            builder: (profileController) {
              final profile = profileController.profileModel;
              final assignedCount = orderController.activeAssignedCount;
              final pausedCount = orderController.pauseOrderHistory != null
                  ? orderController.pausedHistoryCountValue
                  : (profile?.pauseDelivery ?? 0);
              final deliveredCount = profile?.completedDelivery ?? 0;

              return Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                Padding(padding:  EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  child: Text('order_status'.tr,style:  rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: _brandGold))),

                GestureDetector(onTap: ()=> Get.to(()=> const DashboardScreen(pageIndex: 1)),
                  child: TripItem(backgroundColor: _brandGreenLight, accentColor: _brandGreen, icon: Images.assigned,
                      title: 'assigned', totalCount: assignedCount,
                    onTap: (){
                    Get.find<DashboardController>().selectOrderHistoryScreen(fromHome: true);
                    Get.find<OrderController>().setOrderTypeIndex(0);
                    onTap(1);})),

                TripItem(backgroundColor: _brandGoldLight, accentColor: _brandGold, icon: Images.pending,
                    title: 'paused',totalCount: pausedCount,
                  onTap: () {
                     Get.find<DashboardController>().selectOrderHistoryScreen(fromHome: true);
                     onTap(1);
                      Get.find<OrderController>().setOrderTypeIndex(2, reload: true);}),

                TripItem(backgroundColor: _brandGreenLight, accentColor: _brandGreen,icon: Images.completed,
                    title: 'delivered', totalCount: deliveredCount,
                  onTap: (){
                    Get.find<DashboardController>().selectOrderHistoryScreen(fromHome: true);
                    onTap(1);
                    Get.find<OrderController>().setOrderTypeIndex(3, reload: true);}),
              ],);
            },
          );
        },
      ),
    );
  }
}

class TripItem extends StatelessWidget {
  final Color backgroundColor;
  final Color accentColor;
  final String? icon;
  final String? title;
  final int? totalCount;
  final Function? onTap;
  const TripItem({
    super.key,
    required this.backgroundColor,
    required this.accentColor,
    this.icon,
    this.title,
    this.totalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = totalCount ?? 0;
    final countLabel =
        count < 10 ? '0$count' : NumberFormat.compact().format(count);

    return GestureDetector(
      onTap: onTap as void Function()?,
      child: Padding(padding:  EdgeInsets.only(top: Dimensions.paddingSizeChat),
        child: Container(decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeChat),
          color: backgroundColor,
          border: Border.all(color: accentColor.withValues(alpha:.18)),
          boxShadow: [ BoxShadow(color: accentColor.withValues(alpha:.14), spreadRadius: 0, blurRadius: 6, offset: const Offset(1, 1))],
        ),
            child: Container(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeChat),
              color: backgroundColor,
            ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
               Container(padding:  EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                 child: Row(children: [
                  Padding(padding:  EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: SizedBox(
                      width: 30,
                      child: icon != null
                          ? Image.asset(icon!)
                          : const SizedBox.shrink(),
                    )),
                   Text((title ?? '').tr, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w500, color: accentColor))])),

                Padding(padding:  EdgeInsets.symmetric(horizontal : Dimensions.rememberMeSizeDefault, vertical: Dimensions.paddingSizeDefault),
                  child: Container(padding:  EdgeInsets.symmetric(vertical : Dimensions.paddingSizeSmall,
                      horizontal: Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeMin),
                        color: accentColor.withValues(alpha:.20)),
                    child: Text(countLabel,
                      style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: accentColor))))]),
            ))),
    );
  }
}
