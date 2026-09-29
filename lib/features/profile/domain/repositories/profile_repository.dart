import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show basename;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_body.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class ProfileRepository implements ProfileRepositoryInterface{
  final DioClient? dioClient;
  final SharedPreferences? sharedPreferences;
  ProfileRepository({required this.dioClient, required this.sharedPreferences});

  @override
  Future<ApiResponse> getSellerInfo() async {
    try {
      final response = await dioClient!.get(AppConstants.sellerUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateProfile(ProfileInfoModel userInfoModel, ProfileBody seller,  File? file, String token, String password) async {
    try {
      final Map<String, dynamic> fields = <String, dynamic>{
        'f_name': (userInfoModel.fName ?? '').trim(),
        'l_name': (userInfoModel.lName ?? '').trim(),
        'phone': (userInfoModel.phone ?? '').trim(),
        'bank_name': (userInfoModel.bankName ?? seller.bankName ?? '').trim(),
        'branch': (userInfoModel.branch ?? seller.branch ?? '').trim(),
        'holder_name': (userInfoModel.holderName ?? seller.holderName ?? '').trim(),
        'account_no': (userInfoModel.accountNo ?? seller.accountNo ?? '').trim(),
      };
      if (password.isNotEmpty) {
        fields['password'] = password;
      }

      final bool hasImage = file != null && await file.exists();
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      if (kDebugMode) {
        print(
          'Profile update => hasImage: $hasImage, '
          'method: ${hasImage ? 'POST(_method=PUT)' : 'PUT'}',
        );
      }

      final Response response;
      if (hasImage) {
        final formData = FormData.fromMap(<String, dynamic>{
          '_method': 'PUT',
          ...fields,
          'image': await MultipartFile.fromFile(
            file.path,
            filename: basename(file.path),
          ),
        });
        response = await dioClient!.post(
          AppConstants.sellerAndBankUpdate,
          data: formData,
          options: Options(
            headers: headers,
            contentType: 'multipart/form-data',
          ),
        );
      } else {
        response = await dioClient!.put(
          AppConstants.sellerAndBankUpdate,
          data: fields,
          options: Options(
            headers: headers,
            contentType: Headers.formUrlEncodedContentType,
          ),
        );
      }
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deleteUserAccount() async {
    try {
      final response = await dioClient!.get(AppConstants.deleteAccount);
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