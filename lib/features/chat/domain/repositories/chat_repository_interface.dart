import 'package:file_picker/file_picker.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiksee/interface/repository_interface.dart';

abstract class ChatRepositoryInterface implements RepositoryInterface{
  Future<Response> getConversationList(int offset,String _userTypeIndex);
  Future<Response> searchChatList(String  _userTypeIndex , String searchChat);
  Future<Response> getChatList(int offset,String userType, int? userId);
  Future<Response> sendMessage(String message, int userId,String  userType,List<XFile> files, List<PlatformFile>? platformFile);
  Future<Response> searchConversationList(String name);
}