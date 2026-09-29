import 'dart:io';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/interface/repository_interface.dart';

abstract class ProfileRepositoryInterface implements RepositoryInterface{

  Future<dynamic> updateProfile(dynamic updateUserModel,String pass,File? file, String token);
  Future<Response> getProfileInfo();
  Future<Response> profileStatusOnnOff(int status, {double? latitude, double? longitude});
  Future<Response> resetPassword(String? phone, String password ,String confirmPassword);
  Future<Response> updateBankInfo({
    String? bankName,
    String? branch,
    String? branchAddress,
    String? accountNumber,
    String? confirmAccountNumber,
    String? ifscCode,
    String? holderName,
  });
}