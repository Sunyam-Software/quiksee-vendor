
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order_details/widgets/round_border_icon_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/helper/shop_helper.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/chat/screens/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CallAndChatWidget extends StatelessWidget {
  final OrderModel? orderModel;
  final bool isSeller;
  final bool isAdmin;
  const CallAndChatWidget({super.key, this.orderModel, this.isSeller = false, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final inHouseShop = Get.find<SplashController>().configModel?.inHouseShop;
    final hideCustomerPhone = !isSeller &&
        !isAdmin &&
        OrderStatusHelper.shouldHideCustomerContact(orderModel?.orderStatus);

    final isGuest = orderModel?.isGuest == true;
    String? phone = isSeller
        ? orderModel?.sellerInfo?.phone
        : isGuest
            ? orderModel?.shippingAddress?.phone
            : orderModel?.customer?.phone ?? '';
    if (hideCustomerPhone) {
      phone = null;
    }
    int? id = 0;
    String? name = '';
    String? image;
    if(isAdmin){
      id = inHouseShop?.sellerId;
      name = inHouseShop?.name;
      image = inHouseShop?.imageFullUrl?.path ?? '';
    }else{
      id = isSeller ? orderModel?.sellerInfo?.id : orderModel?.customer?.id ?? -1;
      name = isSeller
          ? orderModel?.sellerInfo?.shop?.name ?? ''
          : '${orderModel?.customer?.fName ?? ''} ${orderModel?.customer?.lName ?? ''}';
      image = isSeller ? orderModel?.sellerInfo?.shop?.imageFullUrl?.path : orderModel?.customer?.imageFullUrl?.path;
    }

    return Row(children: [
      if (isAdmin || isSeller || !isGuest)
        InkWell(
          onTap: () {
            if (!isSeller && !isAdmin && isGuest) {
              showQuikseeSnackBarWidget('you_cant_chat_with_guest_user'.tr);
            } else if (!isSeller && !isAdmin && !isGuest) {
              Get.find<ChatController>().setUserTypeIndex(1);
            }else if(isAdmin){
              Get.find<ChatController>().setUserTypeIndex(3);
            }else if(isSeller){
              Get.find<ChatController>().setUserTypeIndex(0);
            }
            if(id != -1){
              Get.to(()=> ChatScreen(
                userId: id,
                name: name,
                image: image,
                isShopOnVacation: isSeller ? ShopHelper.isVacationActive(
                  context,
                  startDate: orderModel?.sellerInfo?.shop?.vacationStartDate,
                  endDate: orderModel?.sellerInfo?.shop?.vacationEndDate,
                  vacationDurationType: orderModel?.sellerInfo?.shop?.vacationDurationType,
                  vacationStatus: orderModel?.sellerInfo?.shop?.vacationStatus,
                  isInHouseSeller: orderModel?.sellerIs == 'admin',
                ) : false,
                isShopTemporaryClosed: isSeller
                    ? orderModel?.sellerInfo?.shop?.temporaryClose ?? false
                    : false,
              ));
            } else if(id  == -1) {
              showQuikseeSnackBarWidget('user_account_was_deleted'.tr);
            }
          },
          child: RoundBorderIconWidget(
            image: Images.smsIcon,
            backgroundColor: const Color(0xFFFFF3E0),
          ),
        ),

      if (!hideCustomerPhone)
        InkWell(
          onTap: () async {
            final dial = phone?.trim();
            if (dial == null || dial.isEmpty) {
              showQuikseeSnackBarWidget('phone_number_not_available'.tr, isError: true);
              return;
            }
            await _launchUrl('tel:$dial');
          },
          child: RoundBorderIconWidget(
            image: Images.callIcon,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          ),
        ),

    ]);
  }
}

Future<void> _launchUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      showQuikseeSnackBarWidget('could_not_launch_url'.tr, isError: true);
    }
  } catch (_) {
    showQuikseeSnackBarWidget('could_not_launch_url'.tr, isError: true);
  }
}