import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order_details/widgets/cal_chat_widget.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';

class ReceiverWidget extends StatelessWidget {
  final OrderModel? orderModel;
  final bool fromReviewPage;
  final bool showAddress;
  const ReceiverWidget({
    super.key,
    this.orderModel,
    this.fromReviewPage = false,
    this.showAddress = false,
  });

  String? _formattedAddress() {
    final ShippingAddress? addr =
        orderModel?.resolvedCustomerShipping ?? orderModel?.shippingAddress;
    if (addr == null) return null;
    final parts = <String>[
      if (addr.address != null && addr.address!.trim().isNotEmpty) addr.address!,
      if (addr.area != null && addr.area!.trim().isNotEmpty) addr.area!,
      if (addr.city != null && addr.city!.trim().isNotEmpty) addr.city!,
      if (addr.state != null && addr.state!.trim().isNotEmpty) addr.state!,
      if (addr.zip != null && addr.zip!.trim().isNotEmpty) addr.zip!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final hideContact =
        OrderStatusHelper.shouldHideCustomerContact(orderModel?.orderStatus);
    final String? addressText = showAddress ? _formattedAddress() : null;
    final primary = Theme.of(context).primaryColor;
    final name = orderModel?.isGuest ?? false
        ? orderModel?.shippingAddress?.contactPersonName ?? ''
        : '${orderModel?.customer?.fName ?? ''} ${orderModel?.customer?.lName ?? ''}'
                .trim()
                .isEmpty
            ? (orderModel?.shippingAddress?.contactPersonName ?? 'receiver'.tr)
            : '${orderModel?.customer?.fName ?? ''} ${orderModel?.customer?.lName ?? ''}'
                .trim();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        children: [
          if (orderModel != null &&
              (orderModel!.customer != null ||
                  orderModel!.isGuest == true ||
                  orderModel!.shippingAddress != null))
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: .25),
                    border: Border.all(color: primary, width: 1.5),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: QuikseeImageWidget(
                      image: '${orderModel?.customer?.imageFullUrl?.path}',
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
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
                                name,
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
                                'receiver'.tr,
                                style: rubikMedium.copyWith(
                                  fontSize: 10,
                                  color: primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (addressText != null)
                          Padding(
                            padding: EdgeInsets.only(
                                top: Dimensions.paddingSizeExtraSmall),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    addressText,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: rubikRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                fromReviewPage
                    ? Container(
                        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .hintColor
                              .withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(
                              Dimensions.paddingSizeSmall),
                        ),
                        child: Icon(
                          Icons.bookmark,
                          color: (Get.find<ThemeController>().darkTheme
                                  ? ColorHelper.blendColors(
                                      Colors.white,
                                      Theme.of(context).primaryColor,
                                      0.9)
                                  : ColorHelper.darken(
                                      Theme.of(context).primaryColor, 0.1))
                              .withValues(alpha: .125),
                        ),
                      )
                    : hideContact
                        ? const SizedBox.shrink()
                        : CallAndChatWidget(orderModel: orderModel),
              ],
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}
