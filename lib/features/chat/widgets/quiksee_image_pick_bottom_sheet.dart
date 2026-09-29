import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_asset_image_widget.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';

class QuikseeImagePickBottomSheet extends StatelessWidget {
  final ChatController chatController;
   const QuikseeImagePickBottomSheet(this.chatController, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.paddingSizeOverLarge), topRight: Radius.circular(Dimensions.paddingSizeOverLarge)),
        color: Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).cardColor,
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeOverLarge),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [

            InkWell(
              onTap: () {
                chatController.pickMultipleMedia(false);
                Navigator.pop(context);
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                const QuikseeAssetImageWidget(Images.fromGallery, width: 70, height: 70,),
                SizedBox(height: Dimensions.paddingSizeSmall,),

                Text('from_gallery'.tr, style: robotoRegular,),

              ]),
            ),
            const SizedBox(width: Dimensions.iconSizeExtraLarge),

            InkWell(
              onTap: () {
                chatController.pickMultipleMedia(false, openCamera: true);
                Navigator.pop(context);
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                const QuikseeAssetImageWidget(Images.openCamera, width: 70, height: 70,),
                SizedBox(height: Dimensions.paddingSizeSmall,),

                Text('open_camera'.tr, style: robotoRegular,),

              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

