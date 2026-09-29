import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/profile/domain/models/userinfo_model.dart';
import 'package:quiksee/features/profile/domain/repositories/profile_repository_interface.dart';
import 'package:quiksee/features/profile/domain/services/profile_service_interface.dart';
import 'package:http/http.dart' as http;

class ProfileService implements ProfileServiceInterface{
  ProfileRepositoryInterface profileRepoInterface;

  ProfileService({required this.profileRepoInterface});


  @override
  Future getProfileInfo({bool silent = false}) async {
    Response response = await profileRepoInterface.getProfileInfo();
    if (response.statusCode == 200) {
      try {
        return UserInfoModel.fromJson(response.body);
      } catch (e) {
        debugPrint('UserInfoModel parse error: $e');
        if (!silent) {
          showQuikseeSnackBarWidget('Failed to load profile data');
        }
        return null;
      }
    } else if (!silent) {
      ApiChecker.checkApi(response);
    }
    return null;
  }


  @override
  Future profileStatusOnnOff(
    int status, {
    double? latitude,
    double? longitude,
  }) async {
    Response response = await profileRepoInterface.profileStatusOnnOff(
      status,
      latitude: latitude,
      longitude: longitude,
    );
    if (response.statusCode == 200) {
      return ResponseModel(true, '');
    } else {
      ApiChecker.checkApi(response);
    }
    return ResponseModel(false, '');
  }

  @override
  Future<Response> resetPassword(String? phone, String password, String confirmPassword) async{
    Response response = await profileRepoInterface.resetPassword(phone, password, confirmPassword);
    if (response.statusCode == 200) {
      showQuikseeSnackBarWidget('password_reset_successfully'.tr, isError: false);

    } else {
      ApiChecker.checkApi(response);
    }
    return response;
  }


  @override
  Future<ResponseModel> updateProfile(updateUserModel, pass, file, String token) async {
    http.StreamedResponse response = await profileRepoInterface.updateProfile(updateUserModel, pass, file, token);
    if (response.statusCode == 200) {
      Get.find<ProfileController>().getProfile();
      Map map = jsonDecode(await response.stream.bytesToString());
      String? message = map["message"];
      return ResponseModel(true, message);
    } else {
      return ResponseModel(false, '${response.statusCode} ${response.reasonPhrase}');
    }
  }

  @override
  Future<Response> updateBankInfo({
    String? bankName,
    String? branch,
    String? branchAddress,
    String? accountNumber,
    String? confirmAccountNumber,
    String? ifscCode,
    String? holderName,
  }) async {
    return profileRepoInterface.updateBankInfo(
      bankName: bankName,
      branch: branch,
      branchAddress: branchAddress,
      accountNumber: accountNumber,
      confirmAccountNumber: confirmAccountNumber,
      ifscCode: ifscCode,
      holderName: holderName,
    );
  }

}