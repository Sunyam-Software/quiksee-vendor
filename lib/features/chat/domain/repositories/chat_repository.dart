import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/features/chat/domain/models/message_body.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/chat/domain/repositories/chat_repository_interface.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class ChatRepository implements ChatRepositoryInterface{
  final DioClient? dioClient;
  ChatRepository({required this.dioClient});

  @override
  Future<ApiResponse> getChatList(String type, int offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.cartUri}$type?limit=30&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> searchChat(String type, String search) async {
    try {
      final response = await dioClient!.get('${AppConstants.chatSearchUri}$type?search=$search');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getMessageList(String type, int offset, int? id) async {
    try {
      final response = await dioClient!.get('${AppConstants.messageUri}$type/$id?limit=30&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> sendMessage(MessageBody messageBody, String type, List<XFile?> files, List<PlatformFile>? platformFile) async {
    try {
      final Map<String, dynamic> fields = <String, dynamic>{
        'id': '${messageBody.userId ?? 0}',
        'message': messageBody.message ?? '',
      };

      final List<MapEntry<String, MultipartFile>> multipartFiles = <MapEntry<String, MultipartFile>>[];
      for (final XFile? media in files) {
        if (media == null) continue;
        multipartFiles.add(MapEntry(
          'media[]',
          await MultipartFile.fromFile(
            media.path,
            filename: path.basename(media.path),
          ),
        ));
      }

      if (platformFile != null && platformFile.isNotEmpty) {
        for (final PlatformFile pfile in platformFile) {
          if (pfile.readStream == null) continue;
          multipartFiles.add(MapEntry(
            'file[]',
            MultipartFile.fromStream(
              () => pfile.readStream!,
              pfile.size,
              filename: path.basename(pfile.name),
            ),
          ));
        }
      }

      final FormData formData = FormData.fromMap(fields);
      if (multipartFiles.isNotEmpty) {
        formData.files.addAll(multipartFiles);
      }

      if (kDebugMode) {
        print('Chat send => type: $type, id: ${messageBody.userId}, message: ${messageBody.message}');
      }

      final response = await dioClient!.post(
        '${AppConstants.sendMessageUri}$type',
        data: formData,
        options: Options(
          headers: <String, String>{'Accept': 'application/json'},
        ),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> seenMessage(int id, String type) async {
    try {
      final response = await dioClient!.post('${AppConstants.seenMessageUri}$type',
          data: {'id':id});
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    throw UnimplementedError();
  }
}
