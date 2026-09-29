import 'dart:io';
import 'package:quiksee/features/auth/domain/models/response_model.dart';

abstract class ProfileServiceInterface {

  Future<ResponseModel> updateProfile(dynamic updateUserModel,String pass,File? file, String token);
  Future<dynamic> getProfileInfo({bool silent = false});
  Future<dynamic> profileStatusOnnOff(int status, {double? latitude, double? longitude});
  Future<dynamic> resetPassword(String? phone, String password ,String confirmPassword);
  Future<dynamic> updateBankInfo({
    String? bankName,
    String? branch,
    String? branchAddress,
    String? accountNumber,
    String? confirmAccountNumber,
    String? ifscCode,
    String? holderName,
  });

}