import 'package:file_picker/file_picker.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/chat/domain/repositories/chat_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';

class ChatRepository implements ChatRepositoryInterface{
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  ChatRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response> getConversationList(int offset, String userType) async {
    return apiClient.getData('${AppConstants.chatListUri}$userType?limit=10&offset=$offset');
  }

  @override
  Future<Response> searchConversationList(String name) async {
    return apiClient.getData('${AppConstants.searchConversationListUri}?name=$name&limit=20&offset=1');
  }

  @override
  Future<Response> getChatList(int offset, String userType, int? id) async {
    return await apiClient.getData('${AppConstants.messageListUri}$userType/$id?offset=$offset&limit=25');
  }

  @override
  Future<Response> searchChatList(String userType, String search) async {
    return await apiClient.getData('${AppConstants.chatSearch}$userType?search=$search');
  }

  @override
  Future<Response> sendMessage(String message, int? userId, String userType, List<XFile> files, List<PlatformFile>? platformFile) async {

    return apiClient.postMultipartData('${AppConstants.sendMessageUri}$userType',
      {'message': message, 'id': userId.toString() }, _getMultipartBody(files), platformFile: (platformFile != null && platformFile.isNotEmpty) ? platformFile : null,
    );
  }

  List<MultipartBody> _getMultipartBody(List<XFile> files) {
    List<MultipartBody> multipartBodies = [];
    for(int i = 0; i < files.length; i++){
      multipartBodies.add(MultipartBody('media[$i]', files[i]));
    }
    return multipartBodies;
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList() {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }

}