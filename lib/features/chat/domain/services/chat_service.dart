import 'package:get/get.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/chat/controllers/chat_controller.dart';
import 'package:quiksee/features/chat/domain/models/chat_model.dart';
import 'package:quiksee/features/chat/domain/repositories/chat_repository_interface.dart';
import 'package:quiksee/features/chat/domain/services/chat_service_interface.dart';

class ChatService implements ChatServiceInterface{
  ChatRepositoryInterface chatRepoInterface;
  ChatService({required this.chatRepoInterface});

  @override
  Future getConversationList(offset, _userTypeIndex) async{
    return chatRepoInterface.getConversationList(offset, _userTypeIndex);
  }

  @override
  Future getChatList(offset, userId) async{
    String userType = 'admin';
    if(userId == 0){
      userType = 'admin';
    }else{
      userType = Get.find<ChatController>().userTypeIndex == 0 ? 'seller' : Get.find<ChatController>().userTypeIndex == 1? "customer" : "admin";
    }
    return chatRepoInterface.getChatList(offset, userType, userId);
  }

  @override
  Future searchChatList(_userTypeIndex, searchChat) async{
    Response response = await chatRepoInterface.searchChatList(_userTypeIndex, searchChat);
    ChatModel _conversationModel = ChatModel(totalSize: 1, limit: '1', offset: '1', chat: []);
    if(response.statusCode == 200) {
      _conversationModel = ChatModel(totalSize: 1, limit: '1', offset: '1', chat: []);
      response.body.forEach((chat) {
        _conversationModel.chat!.add(Chat.fromJson(chat));
      });
    }else {
      ApiChecker.checkApi(response);
    }
    return _conversationModel;
  }

  @override
  Future sendMessage(message, userId, files, platformFile) async{
    String userType = 'admin';
    if(userId == 0){
      userType = 'admin';
    }else{
      userType = Get.find<ChatController>().userTypeIndex == 0 ? 'seller' : Get.find<ChatController>().userTypeIndex == 1? "customer" : "admin";
    }
    Response _response = await chatRepoInterface.sendMessage(message, userId, userType, files, platformFile);
    if (_response.statusCode == 200) {
      return ResponseModel(true, '');
    }else{
      return ResponseModel(false, '');
    }
  }

  @override
  Future searchConversationList(String name) async {
    return chatRepoInterface.searchConversationList(name);
  }
}