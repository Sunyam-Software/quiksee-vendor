import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

abstract class ChatServiceInterface {

  Future<dynamic> getConversationList(int offset,String _userTypeIndex);
  Future<dynamic> searchChatList(String  _userTypeIndex , String searchChat);
  Future<dynamic> getChatList(int offset, int? userId);
  Future<dynamic> sendMessage(String message, int userId, List<XFile> files,  List<PlatformFile>? platformFile);
  Future<dynamic> searchConversationList(String name);
}