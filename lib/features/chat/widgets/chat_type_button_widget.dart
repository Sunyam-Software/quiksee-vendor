import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class ChatTypeButtonWidget extends StatelessWidget {
  final String text;
  final int index;
  const ChatTypeButtonWidget({super.key, required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: ()=> Get.find<ChatController>().setUserTypeIndex(index),
      child: GetBuilder<ChatController>(builder: (chat) {
        return Padding(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall,
              vertical: chat.userTypeIndex == index ?  Dimensions.fontSizeLarge : Dimensions.fontSizeExtraLarge),
          child: Container(padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault,),
            decoration: BoxDecoration(color: chat.userTypeIndex == index ?
            Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.5) : Theme.of(context).cardColor :  Get.isDarkMode ? Theme.of(context).cardColor :
             Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeOverLarge)),
            child: Center(
              child: Text(text, style: chat.userTypeIndex == index ?
              rubikMedium.copyWith(color: chat.userTypeIndex == index ?
              Get.isDarkMode ? Colors.white : Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color) :
              rubikRegular.copyWith(color: chat.userTypeIndex == index ?
              Theme.of(context).cardColor : Theme.of(context).shadowColor.withValues(alpha:1),
              fontSize: chat.userTypeIndex == index ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall)),
            )));})
    );
  }
}