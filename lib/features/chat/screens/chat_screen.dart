
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/features/chat/screens/media_viewer_screen.dart';
import 'package:quiksee/features/chat/widgets/chat_shimmer_widget.dart';
import 'package:quiksee/features/chat/widgets/message_list_view_widget.dart';
import 'package:quiksee/features/chat/widgets/message_sendig_section_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/helper/image_size_checker.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';


class ChatScreen extends StatefulWidget {
  final int? userId;
  final String? name;
  final String? image;
  final bool isShopOnVacation;
  final bool isShopTemporaryClosed;
  const ChatScreen({
    super.key,
    required this.userId,
    this.name = 'chat',
    this.image = '',
    this.isShopOnVacation = false,
    this.isShopTemporaryClosed = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  bool isClosed = false;
  void clickedOnClose(){
    setState(() {
      isClosed = true;
    });
  }


  @override
  void initState() {
    super.initState();
    Get.find<ChatController>().getChats(1, widget.userId,firstLoad: true);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(builder: (chatController) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          Get.find<ChatController>().getConversationList(1);
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).cardColor,
            titleSpacing: 0,
            elevation: 1,
            leading: InkWell(
              ///for making tap transparent
              highlightColor: Theme.of(context).primaryColor.withValues(alpha:0),
              splashColor: Theme.of(context).primaryColor.withValues(alpha:0),
              onTap: ()=> Navigator.pop(context),
              child: Icon(CupertinoIcons.back, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            title: Row(children: [

              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),
                      border: Border.all(width: .5, color: Theme.of(context).primaryColor.withValues(alpha:.125))),
                  height: 40, width: 40,child: QuikseeImageWidget(image: widget.image ?? ''),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: Text(widget.name??'', style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ),
            ]),
          ),

          body: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Stack(children: [
                Column(children: [
                  chatController.messageModel != null ?
                  Expanded(child: (chatController.messageModel!.message != null && chatController.messageModel!.message!.isNotEmpty) ?
                  MessageListViewWidget( scrollController: _scrollController, userId: widget.userId) :
                  const SizedBox()) : const Expanded(child: ChatShimmerWidget()),

                  chatController.hasPicked ?
                  Container(
                      color:  chatController.isLoading == false && ((chatController.pickedMediaFileModelList != null && chatController.pickedMediaFileModelList!.isNotEmpty) || (chatController.pickedFiles != null && chatController.pickedFiles!.isNotEmpty)) ?
                      Theme.of(context).primaryColor.withValues(alpha:0.1) : null,
                      height: (chatController.pickedFIleCrossMaxLimit || chatController.pickedFIleCrossMaxLength || chatController.singleFIleCrossMaxLimit) ? 130 : 110, width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: Dimensions.paddingSizeDefault),
                      child: const Center(child: CircularProgressIndicator()))
                      : (chatController.pickedMediaFileModelList?.isNotEmpty ?? false) && chatController.isSending == false ?
                  Container(
                      color:  chatController.isLoading == false && ((chatController.pickedMediaFileModelList !=null && chatController.pickedMediaFileModelList!.isNotEmpty) || (chatController.pickedFiles != null && chatController.pickedFiles!.isNotEmpty)) ?
                      Theme.of(context).primaryColor.withValues(alpha:0.1) : null,
                      height: (chatController.pickedFIleCrossMaxLimit || chatController.pickedImageCrossMaxLength || chatController.singleFIleCrossMaxLimit) ? 130 : 110, width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: Dimensions.paddingSizeDefault),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(
                          height: 80,
                          child: ListView.builder(scrollDirection: Axis.horizontal,
                              itemBuilder: (context,index){
                                return  Padding(
                                  padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeMin ),
                                  child: Stack(children: [
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 5,),
                                        child: ClipRRect(borderRadius: BorderRadius.circular(10),
                                            child: SizedBox(height: 80, width: 80,
                                                child: Image.file(File(chatController.pickedMediaFileModelList![index].thumbnailPath ?? ''), fit: BoxFit.cover)))),

                                    if(chatController.pickedMediaFileModelList?[index].isVideo ?? false)
                                      Positioned.fill(
                                        child: Align(alignment: Alignment.center, child: InkWell(
                                          onTap: () => Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => MediaViewerScreen(
                                              clickedIndex: index,
                                              localMedia: chatController.getXFileFromMediaFileModel(chatController.pickedMediaFileModelList ?? []),
                                            ),
                                          )),
                                          child: Container(
                                            padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor, size: 30),
                                          ),
                                        )),
                                      ),

                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Transform.translate(
                                        offset: const Offset(2, -8),
                                        child: InkWell(
                                            child: Image.asset(Images.imageCancel, width: 20, height: 20,),
                                            onTap: () => chatController.pickMultipleMedia(true, index: index)),
                                      ),
                                    )]),
                                );},
                              itemCount: chatController.pickedMediaFileModelList!.length),
                        ),

                        if(chatController.pickedFIleCrossMaxLimit || chatController.pickedImageCrossMaxLength || chatController.singleFIleCrossMaxLimit)
                          Text( "${chatController.pickedImageCrossMaxLength ? "• ${"can_not_select_more_than".tr} ${AppConstants.maxLimitOfTotalFileSent.floor()} ${'files'.tr}" :""} "
                              "${chatController.pickedFIleCrossMaxLimit ? "• ${'total_images_size_can_not_be_more_than'.tr} ${AppConstants.maxLimitOfFileSentINConversation.floor()} MB" : ""} "
                              "${chatController.singleFIleCrossMaxLimit ? "• ${'single_file_size_can_not_be_more_than'.tr} "
                              "${(chatController.getExtractSizeInMB(Get.find<SplashController>().configModel?.serverUploadMaxFileSize ?? '') ?? AppConstants.maxSizeOfASingleFile)} MB" : ""} ",
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error.withValues(alpha:0.7),
                            ),
                          ),
                      ],
                      )

                  ) : const SizedBox(),


                  (chatController.pickedFiles?.isNotEmpty ?? false) && chatController.isLoading == false && chatController.isSending == false ?
                  ColoredBox(
                    color: Theme.of(context).primaryColor.withValues(alpha:0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        children: [
                          SizedBox(height: 70,
                            width: MediaQuery.of(context).size.width,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                              child: ListView.separated(
                                shrinkWrap: true, scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(bottom: 5),
                                separatorBuilder: (context, index) =>  SizedBox(width: Dimensions.paddingSizeDefault),
                                itemCount: chatController.pickedFiles!.length,
                                itemBuilder: (context, index){
                                  String fileSize =  ImageValidationHelper.getFileSizeFromPlatformFileToString(chatController.pickedFiles![index]);
                                  return Container(width: 180,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                    ),
                                    padding: const EdgeInsets.only(left: 10, right: 5),
                                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

                                      Image.asset(Images.fileIcon,height: 30, width: 30,),
                                      SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisAlignment: MainAxisAlignment.center, children: [

                                        Text(chatController.pickedFiles![index].name,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: rubikBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                        ),

                                        Text(fileSize, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                          color: Theme.of(context).hintColor,
                                        )),
                                      ])),


                                      InkWell(
                                        onTap: () {
                                          chatController.pickOtherFile(true, index: index);
                                        },
                                        child: Padding(padding: const EdgeInsets.only(top: 5),
                                          child: Align(alignment: Alignment.topRight,
                                            child: Icon(Icons.close,
                                              size: Dimensions.paddingSizeOverLarge,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                        ),
                                      )
                                    ]),
                                  );
                                },
                              ),
                            ),
                          ),

                          if(chatController.pickedFIleCrossMaxLimit || chatController.pickedFIleCrossMaxLength || chatController.singleFIleCrossMaxLimit)
                            Text( "${chatController.pickedFIleCrossMaxLength ? "• ${"can_not_select_more_than".tr} ${AppConstants.maxLimitOfTotalFileSent.floor()} ${'files'.tr}" :""} "
                                "${chatController.pickedFIleCrossMaxLimit ? "• ${'total_images_size_can_not_be_more_than'.tr} ${AppConstants.maxLimitOfFileSentINConversation.floor()} MB" : ""} "
                                "${chatController.singleFIleCrossMaxLimit ? "• ${'single_file_size_can_not_be_more_than'.tr} ${AppConstants.maxSizeOfASingleFile.floor()} MB" : ""} ",
                              style: rubikRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).colorScheme.error.withValues(alpha:0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ) : const SizedBox(),


                  chatController.isSending ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        child: AnimatedContainer(
                          curve: Curves.fastOutSlowIn,
                          duration: const Duration(milliseconds: 500),
                          height: chatController.isSending ? 25.0 : 0.0,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: chatController.isSending ?
                              Dimensions.paddingSizeExtraSmall : 0.0,
                            ),
                            child: Text('sending'.tr, style: rubikRegular.copyWith(color: Theme.of(context).primaryColor.withValues(alpha:.75)),),
                          ),
                        ),
                      ),
                    ],
                  ) : const SizedBox(),


                  chatController.isLoading == false && ((chatController.pickedMediaFileModelList!=null && chatController.pickedMediaFileModelList!.isNotEmpty) || (chatController.pickedFiles != null && chatController.pickedFiles!.isNotEmpty)) ?
                  const SizedBox.shrink() : SizedBox(height: Dimensions.paddingSizeSmall),
                  Column(children: [
                    MessageSendingSectionWidget(userId: widget.userId),
                  ]), //: const SizedBox(),
                ]),

                if(widget.isShopOnVacation && !isClosed)
                  Container(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                    decoration: const BoxDecoration(color: Color(0xFFFEF7D1)),
                    child: Row(children: [
                      Expanded(child: Text("shop_close_message".tr,
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color))),
                      SizedBox(width: Dimensions.paddingSizeSmall,),
                      InkWell(onTap: ()=> clickedOnClose(),
                          child: Icon(Icons.cancel, size: 35, color: Theme.of(context).hintColor, ))
                    ],
                    ),)
              ]),
            ),
          ),
        ),
      );
    }
    );
  }
}
