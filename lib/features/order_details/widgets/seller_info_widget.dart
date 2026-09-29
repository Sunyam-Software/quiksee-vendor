import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/features/order_details/widgets/cal_chat_widget.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';

class SellerInfoWidget extends StatelessWidget {
  final OrderModel? orderModel;

  const SellerInfoWidget({super.key, this.orderModel});

  @override
  Widget build(BuildContext context) {
    final inHouseShop = Get.find<SplashController>().configModel?.inHouseShop;
    final isAdmin = orderModel?.sellerIs == 'admin';
    final showSeller = orderModel != null &&
        (orderModel!.sellerInfo != null || isAdmin);
    final primary = Theme.of(context).primaryColor;
    final shopName = isAdmin
        ? inHouseShop?.name ?? ''
        : orderModel?.sellerInfo?.shop?.name ??
            orderModel?.displayStoreName ??
            '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (showSeller)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: .25),
                    border: Border.all(color: primary, width: 1.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: QuikseeImageWidget(
                      image: isAdmin
                          ? inHouseShop?.imageFullUrl?.path ?? ''
                          : '${orderModel?.sellerInfo?.shop?.imageFullUrl?.path}',
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(
                  width: Get.find<LocalizationController>().isLtr
                      ? 0
                      : Dimensions.paddingSizeSmall,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeSmall, 0, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shopName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: rubikBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Get.isDarkMode
                                      ? Theme.of(context).hintColor
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin ? 'admin'.tr : 'seller'.tr,
                                style: rubikMedium.copyWith(
                                  fontSize: 10,
                                  color: primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                CallAndChatWidget(
                  orderModel: orderModel,
                  isSeller: true,
                  isAdmin: isAdmin,
                ),
              ],
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}
