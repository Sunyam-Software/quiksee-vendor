import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/features/chat/widgets/quiksee_image_pick_bottom_sheet.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:flutter/foundation.dart' as foundation;


class MessageSendingSectionWidget extends StatefulWidget {
  final int? userId;
  const MessageSendingSectionWidget({super.key, required this.userId,});

  @override
  State<MessageSendingSectionWidget> createState() => _MessageSendingSectionWidgetState();
}

class _MessageSendingSectionWidgetState extends State<MessageSendingSectionWidget> {
  final TextEditingController _inputMessageController = TextEditingController();
  bool emojiPicker = false;

  bool _isMediaExist (ChatController chatController){
    return (chatController.pickedMediaFileModelList?.isNotEmpty ?? false) || (chatController.pickedFiles?.isNotEmpty ?? false);
  }

  bool _isMsgValid(ChatController chatController){
    bool isImageMsgValid = (chatController.pickedMediaFileModelList?.isNotEmpty ?? false) && !chatController.pickedImageCrossMaxLength;
    bool isFileMsgValid = (chatController.pickedFiles?.isNotEmpty ?? false) && !chatController.pickedFIleCrossMaxLength;
    bool isTextMsgValid = _inputMessageController.text.trim().isNotEmpty && !chatController.pickedImageCrossMaxLength && !chatController.pickedFIleCrossMaxLength;
    return (isImageMsgValid || isFileMsgValid  || isTextMsgValid) && !chatController.pickedFIleCrossMaxLimit;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (chatController) {
        return ColoredBox(
          color: _isMediaExist(chatController) ?
          Get.isDarkMode ? Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:0.1) :
          Theme.of(context).primaryColor.withValues(alpha:0.0),
          child: Column(
            children: [
              Padding(
                padding:  EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
                child: Opacity(
                  opacity: (chatController.isSending) ? 0.5 : 1,
                  child: AbsorbPointer(
                    absorbing: (chatController.isSending),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Expanded(child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:1) : Theme.of(context).primaryColor.withValues(alpha:.5), width: .75),
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        child: TextField(
                            onTapOutside: (PointerDownEvent event){
                              FocusScope.of(context).unfocus();
                            },
                            inputFormatters: [LengthLimitingTextInputFormatter(Dimensions.messageInputLength)],
                            controller: _inputMessageController,
                            onTap: (){
                              setState(() {
                                emojiPicker = false;
                              });
                            },
                            textCapitalization: TextCapitalization.sentences,
                            style: rubikRegular,
                            keyboardType: TextInputType.multiline,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(top:  Dimensions.paddingSizeLarge),
                                prefixIcon: GestureDetector(onTap: (){
                                  setState(() {
                                    emojiPicker = !emojiPicker;
                                    FocusScope.of(context).unfocus();
                                  });
                                },
                                  child: Padding(padding: EdgeInsets.symmetric(vertical: Dimensions.iconSizeMedium),
                                      child: Image.asset(Images.emoji, height: 24, width: 24 )),
                                ),

                                suffixIcon : Row(mainAxisSize: MainAxisSize.min, children: [
                                  ColoredBox(
                                    color: Colors.transparent,
                                    child: InkWell(onTap: (){
                                      chatController.pickOtherFile(false);
                                    },
                                    child: Padding(padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                                      child: SizedBox(width: 24, child: Image.asset(Images.file)))),
                                  ),

                                  InkWell(onTap: ()=> Get.bottomSheet(
                                    QuikseeImagePickBottomSheet(chatController),
                                  ),
                                  child: Padding(padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                                    child: SizedBox(width: 24, child: Image.asset(Images.attachment, color: Get.isDarkMode ? ColorHelper.darken(Theme.of(context).primaryColor, 0.1) : Theme.of(context).primaryColor)))),
                                ],
                                ),

                                border: InputBorder.none,
                                hintText: 'type_here'.tr,
                                hintStyle: rubikRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeLarge)),
                            onSubmitted: (String newText) {
                              if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();
                              }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();}
                            },
                            onChanged: (String newText) {
                              if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();
                              }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();
                              }}),
                      )),

                      SizedBox(width: Dimensions.paddingSizeSmall),


                      GetBuilder<ChatController>(builder: (chatController) {
                        return InkWell(onTap: () async {
                          if(_isMsgValid(chatController)) {
                            await chatController.sendMessage(
                                _inputMessageController.text, widget.userId!).then((value) {
                              if(value.isSuccess){
                                Future.delayed(const Duration(seconds: 2),() {
                                  chatController.getChats(1, widget.userId);
                                });
                              }
                            });
                            _inputMessageController.clear();
                          } else {
                            (chatController.pickedImageCrossMaxLength || chatController.pickedFIleCrossMaxLength || chatController.singleFIleCrossMaxLimit) ?
                            showQuikseeSnackBarWidget('${"can_not_select_more_than".tr} ${AppConstants.maxLimitOfTotalFileSent.floor()} ${'files'.tr}') : showQuikseeSnackBarWidget('write_somethings'.tr);
                          }
                        },
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                border: Border.all(color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:1) : Theme.of(context).primaryColor.withValues(alpha:.5), width: .75)
                            ),
                            child: chatController.isSending ? SizedBox(width: 55, height: 55, child: Center(child: SizedBox(
                                width: Dimensions.paddingSizeOverLarge,
                                height: Dimensions.paddingSizeOverLarge,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Get.isLogEnable ? Theme.of(context).hintColor.withValues(alpha:1) : Theme.of(context).primaryColor),
                                  backgroundColor: Theme.of(context).hintColor.withValues(alpha:.5),
                                )
                            ))) :
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 8.0, right: 2, top: 2),
                              child: Image.asset(Images.send, width: 45, height: 45,
                                color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:1) : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        );
                        }
                      ),
                    ]),
                  ),
                ),
              ),
              // SizedBox(height: Dimensions.paddingSizeDefault),


              if(emojiPicker)
                SizedBox(height: 250,
                  child: EmojiPicker(
                    onBackspacePressed: () {
                    },
                    textEditingController: _inputMessageController,
                    config: Config(
                      height: 256,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        // Issue: https://github.com/flutter/flutter/issues/28894
                        emojiSizeMax: 28 *
                            (foundation.defaultTargetPlatform ==
                                TargetPlatform.iOS
                                ? 1.2
                                : 1.0),
                      ),
                      // swapCategoryAndBottomBar: false,
                      skinToneConfig: const SkinToneConfig(),
                      categoryViewConfig: const CategoryViewConfig(),
                      bottomActionBarConfig: const BottomActionBarConfig(),
                      searchViewConfig: const SearchViewConfig(),
                    ),
                  ),
                ),


            ],
          ),
        );


      }
    );
  }
}
