import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_body.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/bank_info/domain/repositories/bank_info_repository_interface.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class BankInfoRepository implements BankInfoRepositoryInterface{

  final DioClient? dioClient;
  final SharedPreferences? sharedPreferences;
  BankInfoRepository({required this.dioClient, required this.sharedPreferences});

  @override
  Future<ApiResponse> chartFilterData(String? type) async {
    try {
      final response = await dioClient!.get('${AppConstants.chartFilterData}$type');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getOrderFilterData(String? type) async {
    try {
      final response = await dioClient!.get('${AppConstants.businessAnalytics}$type');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateBank(ProfileInfoModel userInfoModel, ProfileBody seller, String token) async {
    try {
      final accountNo = (userInfoModel.accountNo ?? seller.accountNo ?? '').trim();
      final fields = <String, dynamic>{
        '_method': 'PUT',
        'bank_name': (userInfoModel.bankName ?? seller.bankName ?? '').trim(),
        'branch': (userInfoModel.branch ?? seller.branch ?? '').trim(),
        'branch_address':
            (userInfoModel.branchAddress ?? seller.branchAddress ?? '').trim(),
        'holder_name':
            (userInfoModel.holderName ?? seller.holderName ?? '').trim(),
        'account_no': accountNo,
        'confirm_account_no': accountNo,
        'ifsc_code': (userInfoModel.ifscCode ?? seller.ifscCode ?? '')
            .trim()
            .toUpperCase(),
        'account_type': _normalizeAccountType(
          userInfoModel.accountType ?? seller.accountType,
        ),
        'f_name': (seller.fName ?? userInfoModel.fName ?? '').trim(),
        'l_name': (seller.lName ?? userInfoModel.lName ?? '').trim(),
        'phone': (userInfoModel.phone ?? '').trim(),
      };

      if (kDebugMode) {
        print('Bank update payload => $fields');
      }

      final response = await dioClient!.post(
        AppConstants.sellerAndBankUpdate,
        data: fields,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      if (kDebugMode) {
        print('Bank update => ${response.statusCode}');
      }
      return ApiResponse.withSuccess(response);
    } catch (e) {
      if (kDebugMode && e is DioException) {
        print('Bank update error body => ${e.response?.data}');
      }
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  String getBankToken() {
    return sharedPreferences!.getString(AppConstants.token) ?? "";
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
  Future getList({int? offset = 1}) async {
    try {
      final response = await dioClient!.get(AppConstants.sellerUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future update(Map<String, dynamic> body, int id) {

    throw UnimplementedError();
  }

  String _normalizeAccountType(String? accountType) {
    final normalized = accountType?.trim().toLowerCase() ?? '';
    if (normalized == 'current') {
      return 'current';
    }
    return 'saving';
  }
}
