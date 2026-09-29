import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' ;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/chat/domain/models/chat_model.dart';
import 'package:quiksee/features/chat/domain/models/media_file_model.dart';
import 'package:quiksee/features/chat/domain/models/message_model.dart';
import 'package:quiksee/features/chat/domain/services/chat_service_interface.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/splash/domain/models/config_model.dart' hide Colors;
import 'package:quiksee/helper/date_converter.dart';
import 'package:quiksee/helper/image_size_checker.dart';
import 'package:quiksee/utill/app_constants.dart';


enum SenderType {
  customer,
  seller,
  admin,
  deliveryMan,
  unknown
}

class ChatController extends GetxController implements GetxService{
  ChatServiceInterface chatServiceInterFace;
  ChatController({required this.chatServiceInterFace});

  List<bool>? _showDate;
  List<XFile>? _imageFiles;
  bool _isSendButtonActive = false;
  final bool _isSeen = false;
  final bool _isSend = true;
  final bool _isMe = false;
  bool _isLoading= false;
  bool _isSending= false;
  bool get isSending=> _isSending;
  final List <XFile>_chatImage = [];
  int? _pageSize;
  int? _offset;
  ChatModel? _conversationModel;
  MessageModel? _messageModel;
  int _userTypeIndex = 0;
  int _apiHitCount = 0;


  bool get isLoading => _isLoading;
  List<bool>? get showDate => _showDate;
  List<XFile>? get imageFiles => _imageFiles;
  bool get isSendButtonActive => _isSendButtonActive;
  bool get isSeen => _isSeen;
  bool get isSend => _isSend;
  bool get isMe => _isMe;
  int? get pageSize => _pageSize;
  int? get offset => _offset;
  List<XFile>? get chatImage => _chatImage;
  ChatModel? get conversationModel => _conversationModel;
  MessageModel? get messageModel => _messageModel;
  int get userTypeIndex =>  _userTypeIndex;


  bool _pickedFIleCrossMaxLimit = false;
  bool get pickedFIleCrossMaxLimit => _pickedFIleCrossMaxLimit;

  bool _pickedFIleCrossMaxLength = false;
  bool get pickedFIleCrossMaxLength => _pickedFIleCrossMaxLength;

  bool _singleFIleCrossMaxLimit = false;
  bool get singleFIleCrossMaxLimit => _singleFIleCrossMaxLimit;

  List<PlatformFile>? _pickedFiles;
  List<PlatformFile>? get pickedFiles => _pickedFiles;


  String _onImageOrFileTimeShowID = '';
  String get onImageOrFileTimeShowID => _onImageOrFileTimeShowID;

  bool _isClickedOnImageOrFile = false;
  bool get isClickedOnImageOrFile => _isClickedOnImageOrFile;

  bool _isClickedOnMessage = false;
  bool get isClickedOnMessage => _isClickedOnMessage;

  String _onMessageTimeShowID = '';
  String get onMessageTimeShowID => _onMessageTimeShowID;


  Future<void> getConversationList(int offset, {bool isUpdate = true}) async{
    _apiHitCount ++;
    if(offset == 1){
      _conversationModel = null;
      if(isUpdate){
        update();
      }
    }
    _isLoading = true;
    Response response = await chatServiceInterFace.getConversationList(offset, _userTypeIndex == 0 ? 'seller' : _userTypeIndex == 1 ? 'customer' : 'admin');
    if(response.statusCode == 200) {
      if(offset == 1) {
        _conversationModel = null;
        _conversationModel = ChatModel.fromJson(response.body);
      }else {
        _conversationModel!.totalSize = ChatModel.fromJson(response.body).totalSize;
        _conversationModel!.offset = ChatModel.fromJson(response.body).offset;
        _conversationModel!.chat!.addAll(ChatModel.fromJson(response.body).chat!);
      }
    }else {
      ApiChecker.checkApi(response);
    }
    _apiHitCount--;
    _isLoading = false;

    if(_apiHitCount == 0){
      update();
    }
  }

  bool isSearching = false;
  Future<void> searchConversationList(String searchChat) async{

    if(searchChat.isNotEmpty){
      isSearching = true;
    } else {
      setUserTypeIndex(_userTypeIndex);
    }

    _isLoading = true;
    _conversationModel = await chatServiceInterFace.searchChatList(_userTypeIndex == 0 ? 'seller' : _userTypeIndex == 1 ? 'customer':'admin', searchChat);
    _isLoading = false;
    update();
  }

  Future<void> getChats(int offset, int? userId, {bool firstLoad = false}) async {
    if(firstLoad){
      _isLoading = true;
      _messageModel = null;
    }
    Response _response = await chatServiceInterFace.getChatList(offset, userId);
    if (_response.body != {} && _response.statusCode == 200) {
      if(offset == 1 ){
        _messageModel = null;
        _messageModel = MessageModel.fromJson(_response.body);


      }else{
        _messageModel?.totalSize =  MessageModel.fromJson(_response.body).totalSize;
        _messageModel?.offset =  MessageModel.fromJson(_response.body).offset;
        _messageModel?.message?.addAll(MessageModel.fromJson(_response.body).message ?? []) ;

      }
    } else {
      ApiChecker.checkApi(_response);
    }
    _isLoading = false;
    update();
  }

  void toggleSendButtonActivity() {
    _isSendButtonActive = !_isSendButtonActive;
    update();
  }


  Future<ResponseModel> sendMessage(String message, int userId) async {

    _isSending = true;
    update();
    
    ResponseModel _response = await chatServiceInterFace.sendMessage(message, userId, getXFileFromMediaFileModel(pickedMediaFileModelList ?? []) ?? [], _pickedFiles ?? []);
    
    if(_response.isSuccess){
      _isSendButtonActive = false;
      
      getChats(1, userId);
      
      _emptyAllPickedData();
      
    }else{
      _isSendButtonActive = false;
    }
    
    _isSending = false;
    update();
    
    return _response;
  }


  void setUserTypeIndex(int index, {bool isUpdate = true}) {
    _userTypeIndex = index;
    getConversationList(1, isUpdate: isUpdate);
    if(isUpdate) {
      update();
    }
  }

  List<PlatformFile> _pickedMediaFiles =[];
  List<PlatformFile>? get pickedMediaFiles => _pickedMediaFiles;
  List<MediaFileModel>? pickedMediaFileModelList = [];
  bool hasPicked = false;
  bool pickedImageCrossMaxLength = false;


  void pickMultipleMedia(bool isRemove,{int? index, bool openCamera = false,}) async {
    _pickedFIleCrossMaxLimit = false;
    pickedImageCrossMaxLength = false;
    _singleFIleCrossMaxLimit = false;
    
    hasPicked = true;
    update();


    if(isRemove) {
      if(index != null){
        pickedMediaFileModelList?.removeAt(index);
      }
    } else if(openCamera) {
      final XFile? pickedImage =  await ImageValidationHelper.validateAndPickImage(
        source: ImageSource.gallery,
        context: Get.context!,
      );

      if(pickedImage != null) {
        pickedMediaFileModelList?.add(MediaFileModel(file: pickedImage, thumbnailPath: pickedImage.path, isVideo: false));
      }
    } else {

      FilePickerResult? filePickerResult =  await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: [
          ...AppConstants.imageExtensions,
          ...AppConstants.videoExtensions,
        ],
      );

      _pickedMediaFiles = filePickerResult?.files ?? [];
      List<PlatformFile> validatedFiles = [];
      bool hasInvalidFile = false;

      for (var file in _pickedMediaFiles) {
        if (
        [
          ...AppConstants.imageExtensions,
          ...AppConstants.videoExtensions,
        ].contains(file.extension?.toLowerCase())) {
          validatedFiles.add(file);
        } else {
          hasInvalidFile = true;
        }
      }

      if (hasInvalidFile) {
        showQuikseeSnackBarWidget('invalid_file_type'.tr);
      }

      for (PlatformFile file in validatedFiles) {
        if (isVideoExtension(file.path ?? '')) {
          final thumbnailPath = await generateThumbnail(file.path ?? '');
          double size =  await ImageValidationHelper.getImageSizeFromXFile(file.xFile);
          ConfigModel? configModel = Get.find<SplashController>().configModel;

          if (thumbnailPath != null && size <= (configModel?.systemGeneralFileUploadMaxSize ?? AppConstants.maxSizeOfASingleFile)) {
            pickedMediaFileModelList?.add(MediaFileModel(file: file.xFile, thumbnailPath: thumbnailPath, isVideo: true));
          } else {
            showQuikseeSnackBarWidget('${'maximum_file_size'.tr} ${(configModel?.systemImageFileUploadMaxSize ?? AppConstants.fileImageMaxLimit)}MB');
          }

        } else {
          double value =  await ImageValidationHelper.getImageSizeFromXFile(file.xFile);

          ConfigModel? configModel = Get.find<SplashController>().configModel;
          if(value > (configModel?.systemImageFileUploadMaxSize ?? AppConstants.fileImageMaxLimit)) {
            showQuikseeSnackBarWidget('${'maximum_file_size'.tr} ${(configModel?.systemImageFileUploadMaxSize ?? AppConstants.fileImageMaxLimit)}MB');
          } else {
            pickedMediaFileModelList?.add(MediaFileModel(file: file.xFile, thumbnailPath: file.path, isVideo: false));
          }

        }
      }
    }

    pickedImageCrossMaxLength = _isMediaCrossMaxLen();
    _pickedFIleCrossMaxLimit = await _isCrossMediaMaxLimit();

    pickedMediaFileModelList?.forEach((element) {
      if(ImageValidationHelper.getFileSizeFromXFileSync(element.file!) > (getExtractSizeInMB(Get.find<SplashController>().configModel?.serverUploadMaxFileSize ?? '') ?? AppConstants.maxSizeOfASingleFile)  ) {
        _singleFIleCrossMaxLimit = true;
      }
    });


    
    hasPicked = false;
    update();
  }

  bool _isMediaCrossMaxLen() => pickedMediaFileModelList!.length > AppConstants.maxLimitOfTotalFileSent;

  Future<bool> _isCrossMediaMaxLimit() async =>
    _pickedMediaFiles.length == AppConstants.maxLimitOfTotalFileSent
       && await ImageValidationHelper.getMultipleImageSizeFromXFile(getXFileFromMediaFileModel(pickedMediaFileModelList ?? []) ?? [])
        > AppConstants.maxLimitOfFileSentINConversation;


  Future<void> pickOtherFile(bool isRemove, {int? index}) async {
    _pickedFIleCrossMaxLength = false;
    _singleFIleCrossMaxLimit = false;
    if(isRemove){
      if(_pickedFiles!=null){
        _pickedFiles!.removeAt(index!);
      }

      _pickedFIleCrossMaxLength = _isFileCrossMaxLen();
      _pickedFIleCrossMaxLimit = await _isCrossFileMaxLimit();

    }else{
      List<String> documentExtensions = [];
      documentExtensions.addAll(AppConstants.documentExtensions);

      if(!AppConstants.demo) {
        documentExtensions.addAll(['rar', 'tar', 'targz', 'zip']);
      }

      List<PlatformFile>? platformFile = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: documentExtensions,
        allowMultiple: true,
        withReadStream: true,
      ))?.files;

      _pickedFiles = [];


      if(platformFile != null) {
        bool hasInvalidFile = false;

        List<PlatformFile> validatedFiles = [];

        for (var file in platformFile) {
          double fileSize =  ImageValidationHelper.getFileSizeFromPlatformFileToDouble(file);

          if(!hasInvalidFile && fileSize > (Get.find<SplashController>().configModel?.systemGeneralFileUploadMaxSize ?? AppConstants.maxSizeOfASingleFile)) {
            showQuikseeSnackBarWidget('${'maximum_file_size'.tr} ${(Get.find<SplashController>().configModel?.systemGeneralFileUploadMaxSize ?? AppConstants.maxSizeOfASingleFile)}MB');
          } else if (documentExtensions.contains(file.extension?.toLowerCase())) {
            validatedFiles.add(file);
          } else {
            hasInvalidFile = true;
          }
        }

        if (hasInvalidFile) {
          showQuikseeSnackBarWidget('invalid_file_type'.tr);
        }

        validatedFiles.forEach((element) {
          if(ImageValidationHelper.getFileSizeFromPlatformFileToDouble(element) > AppConstants.maxSizeOfASingleFile) {
            _singleFIleCrossMaxLimit = true;
          } else{
            _pickedFiles!.add(element);
          }
        });

        if(_pickedFiles?.length == AppConstants.maxLimitOfTotalFileSent  &&   validatedFiles.length > AppConstants.maxLimitOfTotalFileSent){
          _pickedFIleCrossMaxLength = true;
        }
        if(_pickedFiles?.length == AppConstants.maxLimitOfTotalFileSent && ImageValidationHelper.getMultipleFileSizeFromPlatformFiles(validatedFiles) > AppConstants.maxLimitOfFileSentINConversation){
          _pickedFIleCrossMaxLimit = true;
        }

        _pickedFIleCrossMaxLength = _isFileCrossMaxLen();

        _pickedFIleCrossMaxLimit = await _isCrossFileMaxLimit();
      }

    }
    update();
  }

  bool _isFileCrossMaxLen() => _pickedFiles!.length > AppConstants.maxLimitOfTotalFileSent;

  Future<bool> _isCrossFileMaxLimit() async =>
      _pickedFiles?.length == AppConstants.maxLimitOfTotalFileSent && _pickedFiles != null &&
          ImageValidationHelper.getMultipleFileSizeFromPlatformFiles(_pickedFiles!) > AppConstants.maxLimitOfFileSentINConversation;


  bool isSameUserWithPreviousMessage(Message? previousConversation, Message currentConversation){
    if(getSenderType(previousConversation) == getSenderType(currentConversation) && previousConversation?.message != null && currentConversation.message !=null){
      return true;
    }
    return false;
  }
  bool isSameUserWithNextMessage( Message currentConversation, Message? nextConversation){
    if(getSenderType(currentConversation) == getSenderType(nextConversation) && nextConversation?.message != null && currentConversation.message !=null){
      return true;
    }
    return false;
  }

  SenderType getSenderType(Message? senderData) {
    if (senderData?.sentByCustomer == true) {
      return SenderType.customer;
    } else if (senderData?.sentBySeller == true) {
      return SenderType.seller;
    } else {
      return SenderType.unknown;
    }
  }


  String getChatTimeWithPrevious (Message currentChat, Message? previousChat) {
    DateTime todayConversationDateTime = DateConverter
        .isoUtcStringToLocalTimeOnly(currentChat.createdAt ?? "");

    DateTime previousConversationDateTime;

    if (previousChat?.createdAt == null) {
      return 'Not-Same';
    } else {
      previousConversationDateTime =
          DateConverter.isoUtcStringToLocalTimeOnly(previousChat!.createdAt!);
      if (kDebugMode) {
        print("The Difference is ${previousConversationDateTime.difference(todayConversationDateTime) < const Duration(minutes: 30)}");
      }
      if (previousConversationDateTime.difference(todayConversationDateTime) <
          const Duration(minutes: 30) &&
          todayConversationDateTime.weekday ==
              previousConversationDateTime.weekday && isSameUserWithPreviousMessage(currentChat, previousChat)) {
        return '';
      } else {
        return 'Not-Same';
      }
    }
  }


  String getChatTime (String todayChatTimeInUtc , String? nextChatTimeInUtc) {
    String chatTime = '';
    DateTime todayConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(todayChatTimeInUtc);

    DateTime nextConversationDateTime;
    DateTime currentDate = DateTime.now();

    if(nextChatTimeInUtc == null){
      String chatTime = DateConverter.isoStringToLocalDateAndTime(todayChatTimeInUtc);
      return chatTime;
    }else{
      nextConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(nextChatTimeInUtc);
      if(todayConversationDateTime.difference(nextConversationDateTime) < const Duration(minutes: 30) &&
          todayConversationDateTime.weekday == nextConversationDateTime.weekday){
        chatTime = '';
      }else if(currentDate.weekday != todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) < 6){

        if( (currentDate.weekday -1 == 0 ? 7 : currentDate.weekday -1) == todayConversationDateTime.weekday){
          chatTime = DateConverter.convert24HourTimeTo12HourTimeWithDay(todayConversationDateTime, false);
        }else{
          chatTime = DateConverter.convertStringTimeToDate(todayConversationDateTime).toString();
        }
      }else if(currentDate.weekday == todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) < 6){
        chatTime = DateConverter.convert24HourTimeTo12HourTimeWithDay(todayConversationDateTime, true);
      }else{
        chatTime = DateConverter.isoStringToLocalDateAndTime(todayChatTimeInUtc);
      }
    }

    return chatTime;
  }


  void downloadFile(String url, String dir, String openFileUrl, String fileName) async {

    var snackBar = SnackBar(content: Text('Downloading....'),backgroundColor: Colors.black54, duration: const Duration(seconds: 1),);
    ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);

    final task  = await FlutterDownloader.enqueue(
      url: url,
      savedDir: dir,
      fileName: fileName,
      showNotification: true,
      saveInPublicStorage: true,
      openFileFromNotification: true,
    );

    if(task !=null){
      await OpenFile.open(openFileUrl);
    }
  }

  void toggleOnClickMessage ({required String onMessageTimeShowID}) {
    _onImageOrFileTimeShowID = '';
    _isClickedOnImageOrFile = false;
    if(_isClickedOnMessage && _onMessageTimeShowID != onMessageTimeShowID){
      _onMessageTimeShowID = onMessageTimeShowID;
    }else if(_isClickedOnMessage && _onMessageTimeShowID == onMessageTimeShowID){
      _isClickedOnMessage = false;
      _onMessageTimeShowID = '';
    }else{
      _isClickedOnMessage = true;
      _onMessageTimeShowID = onMessageTimeShowID;
    }

    update();
  }


  String? getOnPressChatTime(Message currentConversation){
    if(currentConversation.id.toString() == _onMessageTimeShowID || currentConversation.id.toString() == _onImageOrFileTimeShowID){
      DateTime currentDate = DateTime.now();
      DateTime todayConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(
          currentConversation.createdAt ?? ""
      );

      if(currentDate.weekday != todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) <= 7){
        return DateConverter.convertStringTimeToDateChatting(todayConversationDateTime);
      }else if(currentDate.weekday == todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) <= 7){
        return  DateConverter.convert24HourTimeTo12HourTime(todayConversationDateTime);
      }else{
        return DateConverter.isoStringToLocalDateAndTime(currentConversation.createdAt!);
      }
    }else{
      return null;
    }
  }


  String getConversionTime(String? conversationTime){
    if(conversationTime!.isNotEmpty){
      DateTime currentDate = DateTime.now();
      DateTime todayConversationDateTime = DateConverter.isoUtcStringToLocalTimeOnly(conversationTime);

      if(currentDate.weekday != todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) <= 7){
        return DateConverter.convertStringTimeToDateChatting(todayConversationDateTime);
      }else if(currentDate.weekday == todayConversationDateTime.weekday
          && DateConverter.countDays(todayConversationDateTime) <= 7){
        return  DateConverter.convert24HourTimeTo12HourTime(todayConversationDateTime);
      }else{
        return DateConverter.isoStringToLocalDateAndTime(conversationTime);
      }
    }else{
      return '';
    }
  }


  bool isVideoExtension(String path) {
    final fileExtension = path.split('.').last.toLowerCase();

    return AppConstants.videoExtensions.contains(fileExtension);
  }

  Future<String?> generateThumbnail(String filePath) async {
    final directory = await getTemporaryDirectory();

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: filePath, // Replace with your video URL
      thumbnailPath: directory.path,
      imageFormat: ImageFormat.PNG,
      maxHeight: 100,
      maxWidth: 200,
      quality: 1,
    );

    return thumbnailPath.path;
  }

  List<XFile>? getXFileFromMediaFileModel(List<MediaFileModel> mediaFileModel) {
    return mediaFileModel
        .map((model) => model.file)
        .whereType<XFile>() // Filters out any null values
        .toList();
  }
  
  void _emptyAllPickedData() {
    _pickedMediaFiles = [];
    pickedMediaFileModelList = [];
    _pickedFiles = [];
    _pickedFiles = [];
  }
  double? getExtractSizeInMB(String sizeString) {
    final regex = RegExp(r'^(\d+(\.\d+)?)\s*([kKmMgG])[bB]?$');
    final match = regex.firstMatch(sizeString.trim());

    if (match != null) {
      double value = double.parse(match.group(1)!);
      String unit = match.group(3)!.toUpperCase();

      if (unit == 'G') {
        return value * 1024; // Convert GB to MB
      } else if (unit == 'M') {
        return value; // Already in MB
      } else {
        return null;
      }
    } else {
      return null;
    }
  }


}