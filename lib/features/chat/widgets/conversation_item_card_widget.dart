import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_ink_well_widget.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/chat/domain/models/chat_model.dart';
import 'package:quiksee/helper/shop_helper.dart';
import 'package:quiksee/helper/string_extensions.dart';
import 'package:quiksee/features/chat/screens/chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';

class ConversationItemCardWidget extends StatelessWidget {
  final Chat? chat;
  const ConversationItemCardWidget({super.key, this.chat});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
        builder: (chatController) {
          final inHouseShop = Get.find<SplashController>().configModel?.inHouseShop;

          String? image = chatController.userTypeIndex == 0 ?  chat!.sellerInfo != null ? chat!.sellerInfo!.shops![0].imageFullUrl?.path ?? '' : '' :
          chatController.userTypeIndex == 1 ? chat!.customer?.imageFullUrl?.path ?? '' : inHouseShop?.imageFullUrl?.path ?? '';

          String name = chatController.userTypeIndex == 0 ? chat!.sellerInfo != null ? chat!.sellerInfo!.shops![0].name! : 'Shop not found' :
          chatController.userTypeIndex == 1 ? '${chat!.customer?.fName?? ''} ${chat!.customer?.lName??''}' : inHouseShop?.name ?? '';

          int? userId = chatController.userTypeIndex == 0 ?  chat?.sellerId : chatController.userTypeIndex == 1 ? chat?.userId : inHouseShop?.sellerId;

          String path = image;

          return Container(margin:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
            padding: EdgeInsets.all(Dimensions.paddingSizeMin),
            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.10), width: 1),
              color: (chat?.seenByDeliveryMan ?? false) ? Get.isDarkMode
                  ? Theme.of(context).cardColor.withValues(alpha: 0.50)
                  : Theme.of(context).cardColor : Get.isDarkMode
                  ? Theme.of(context).hintColor : Theme.of(context).primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Dimensions.chatProfileSize),
            ),
            child: QuikseeInkWellWidget(onTap: () => Get.to(ChatScreen(
              userId: userId,
              name: name,
              image: image,
              isShopOnVacation: chatController.userTypeIndex == 0 ? ShopHelper.isVacationActive(
                context,
                startDate: DateTime.tryParse(chat?.sellerInfo?.shops?[0].vacationStartDate ?? ''),
                endDate: DateTime.tryParse(chat!.sellerInfo!.shops?[0].vacationEndDate ?? ''),
                vacationDurationType: chat!.sellerInfo!.shops?[0].vacationDurationType,
                vacationStatus: chat!.sellerInfo!.shops?[0].vacationStatus,
                isInHouseSeller: chat?.sentByAdmin ?? false,
              ) : false,
              isShopTemporaryClosed: chatController.userTypeIndex == 0
                  ? (chat?.sellerInfo?.shops?[0].temporaryClose ?? false)
                  : false,
            )),
              highlightColor: Theme.of(context).colorScheme.surface.withValues(alpha:0.1),
              radius: Dimensions.profileImageSize,

              child: Stack(children: [
                Padding(padding:  EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: Row(children: [

                      Stack(children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha:.15),
                              width: 1.2, // Border width
                            ),
                            borderRadius: BorderRadius.circular(100), // Optional: Rounded corners
                          ),
                          child: ClipOval(child: QuikseeImageWidget(height: 50, width: 50,fit: BoxFit.cover, image: path)),
                        ),

                        if(chat?.sellerInfo?.shops?[0].temporaryClose ?? false)
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.black54.withValues(alpha:.65),
                            borderRadius: BorderRadius.circular(100), // Optional: Rounded corners
                          ),
                          child: ClipOval(child: Center(child: Text("close".tr, style: rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)))),
                        ),
                      ]),
                      SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(name, style: rubikBold.copyWith(
                                  color: chatController.userTypeIndex == 0 && chat!.sellerInfo == null ?
                                  Colors.red : chatController.userTypeIndex == 1 && chat!.customer == null ?
                                  Colors.red : Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).primaryColor), overflow: TextOverflow.ellipsis,),
                            ),

                            SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Transform.translate(
                              offset: const Offset(0,-5),
                              child: Text(timeago.format(DateConverter.isoStringToLocalDate(chat!.createdAt!)).toCapitalized(),
                                style: rubikMedium.copyWith(
                                    color: Get.isDarkMode ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).primaryColor,
                                    fontSize: Dimensions.fontSizeExtraSmall
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          ],
                        ),

                        Padding(
                          padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                          child: Row(
                            children: [
                              Expanded(child: Text((chat!.message == null &&  chat!.attachment!.isNotEmpty) ? 'sent_attachment'.tr : chat!.message ?? "",
                                  maxLines: 1,overflow: TextOverflow.ellipsis,
                                  style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor))),
                            ],
                          ),
                        ),
                      ]))])),

              ]),
            ),
          );
        }
    );
  }
}
