import 'package:flutter/foundation.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_body.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/data/model/response/base/error_response.dart';
import 'package:quiksee_vendor_app/data/model/response/response_model.dart';
import 'package:quiksee_vendor_app/features/bank_info/domain/repositories/bank_info_repository_interface.dart';
import 'package:quiksee_vendor_app/features/bank_info/domain/services/bank_info_service_interface.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';

class BankInfoService implements BankInfoServiceInterface{
  BankInfoRepositoryInterface bankInfoRepoInterface;
  BankInfoService({required this.bankInfoRepoInterface});

  @override
  Future chartFilterData(String? type) {
    return bankInfoRepoInterface.chartFilterData(type);
  }

  @override
  Future getBankList() async{
    ApiResponse apiResponse = await bankInfoRepoInterface.getList();
    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200) {
    return ProfileInfoModel.fromJson(apiResponse.response!.data);
    } else {
    ApiChecker.checkApi(apiResponse);
    }
  }

  @override
  String getBankToken() {
    return bankInfoRepoInterface.getBankToken();
  }

  @override
  Future updateBank(ProfileInfoModel userInfoModel, ProfileBody seller, String token) async{
    ApiResponse apiResponse = await bankInfoRepoInterface.updateBank(userInfoModel, seller, token);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      return ResponseModel(true, '');
    }
    if (kDebugMode) {
      print('Bank update failed: ${apiResponse.response?.statusCode} ${apiResponse.error}');
    }
    return ResponseModel(false, _readApiError(apiResponse));
  }

  String _readApiError(ApiResponse apiResponse) {
    final responseData = apiResponse.response?.data;
    if (responseData is Map) {
      final message = responseData['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
      if (responseData['errors'] != null) {
        final errorResponse = ErrorResponse.fromJson(responseData);
        final first = errorResponse.errors?.isNotEmpty == true
            ? errorResponse.errors!.first.message
            : null;
        if (first != null && first.trim().isNotEmpty) {
          return first.trim();
        }
      }
    }

    final err = apiResponse.error;
    if (err == null) {
      final fallback =
          '${apiResponse.response?.statusCode ?? ''} ${apiResponse.response?.statusMessage ?? ''}'
              .trim();
      return fallback.isNotEmpty ? fallback : 'Update failed';
    }
    if (err is String && err.trim().isNotEmpty) {
      return err.trim();
    }
    if (err is ErrorResponse &&
        err.errors != null &&
        err.errors!.isNotEmpty &&
        (err.errors!.first.message ?? '').trim().isNotEmpty) {
      return err.errors!.first.message!.trim();
    }
    final text = err.toString().trim();
    return text.isNotEmpty && text != 'null' ? text : 'Update failed';
  }

  @override
  Future getOrderFilterData(String? type) {
    return bankInfoRepoInterface.getOrderFilterData(type);
  }

}