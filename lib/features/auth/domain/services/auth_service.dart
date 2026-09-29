import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/data/model/response/base/error_response.dart';
import 'package:quiksee_vendor_app/data/model/response/response_model.dart';
import 'package:quiksee_vendor_app/features/auth/domain/models/register_model.dart';
import 'package:quiksee_vendor_app/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:quiksee_vendor_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/main.dart';

class AuthService implements AuthServiceInterface{
  final AuthRepositoryInterface authRepoInterface;
  AuthService({required this.authRepoInterface});

  @override
  Future clearSharedData({bool clearServerSession = true}) {
   return authRepoInterface.clearSharedData(clearServerSession: clearServerSession);
  }

  @override
  Future clearUserNumberAndPassword(){
    return authRepoInterface.clearUserNumberAndPassword();
  }

  @override
  Future forgotPassword(String identity) async{
    ApiResponse apiResponse = await authRepoInterface.forgotPassword(identity);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      return ResponseModel(true, apiResponse.response!.data["message"]);
    } else {
      String? errorMessage;
      if (apiResponse.error is String) {
        if (kDebugMode) {
          print(apiResponse.error.toString());
        }
        errorMessage = apiResponse.error.toString();
      } else {
        ErrorResponse errorResponse = apiResponse.error;
        if (kDebugMode) {
          print(errorResponse.errors![0].message);
        }
        errorMessage = errorResponse.errors![0].message;
      }
     return ResponseModel(false, errorMessage);
    }
  }

  @override
  String getUserEmail() {
    return authRepoInterface.getUserEmail();

  }

  @override
  String getUserPassword() {
    return authRepoInterface.getUserPassword();
  }

  @override
  String getUserToken() {
    return authRepoInterface.getUserToken();

  }

  @override
  bool isLoggedIn() {
    return authRepoInterface.isLoggedIn();
  }

  @override
  Future login({String? emailAddress, String? password}) async{
    ApiResponse apiResponse = await authRepoInterface.login(emailAddress: emailAddress, password: password);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data is Map
          ? Map<String, dynamic>.from(apiResponse.response!.data as Map)
          : <String, dynamic>{};
      if (map["token"] != null) {
        String token = map["token"].toString();
        saveUserToken(token);
      }
    } else if (apiResponse.error == 'pending'){
      showQuikseeSnackBarWidget(getTranslated('your_account_is_in_review_process', Get.context!), Get.context!, sanckBarType: SnackBarType.error);
    } else if(apiResponse.error == 'unauthorized'){
      showQuikseeSnackBarWidget(getTranslated('invalid_credential', Get.context!), Get.context!, sanckBarType: SnackBarType.error);
    } else {
      final dynamic error = apiResponse.error;
      final String message;
      if (error is String && error.trim().isNotEmpty) {
        message = error.trim();
      } else if (apiResponse.response?.statusCode != null &&
          apiResponse.response!.statusCode! >= 500) {
        message = 'Server error. Please try again later.';
      } else {
        message = getTranslated('account_not_verified_yet', Get.context!)!;
      }
      showQuikseeSnackBarWidget(message, Get.context!, sanckBarType: SnackBarType.error);
    }
    return apiResponse;
  }

  @override
  Future loginApprovalStatus({required String requestId}) {
    return authRepoInterface.loginApprovalStatus(requestId: requestId);
  }

  @override
  Future loginApprovalStatusPeek({required String requestId}) {
    return authRepoInterface.loginApprovalStatusPeek(requestId: requestId);
  }

  @override
  Future resolveLoginApproval({required String requestId, required String action}) {
    return authRepoInterface.resolveLoginApproval(requestId: requestId, action: action);
  }

  @override
  Future pendingLoginApproval() {
    return authRepoInterface.pendingLoginApproval();
  }

  @override
  Future logout() {
    return authRepoInterface.logout();
  }

  @override
  Future registration(XFile? profileImage, XFile? shopLogo, XFile? shopBanner, XFile? secondaryBanner, RegisterModel registerModel, XFile? tinCertificate) async{
    return authRepoInterface.registration(profileImage, shopLogo, shopBanner, secondaryBanner, registerModel, tinCertificate);
  }

  @override
  Future resetPassword(String identity, String otp, String password, String confirmPassword, String? token) async{
    ApiResponse apiResponse = await authRepoInterface.resetPassword(identity, otp, password, confirmPassword, token);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      return ResponseModel(true, apiResponse.response!.data["message"]);
    } else {
      String? errorMessage;
      if (apiResponse.error is String) {

        errorMessage = apiResponse.error.toString();
      } else {
        ErrorResponse errorResponse = apiResponse.error;
        errorMessage = errorResponse.errors![0].message;
      }
      return ResponseModel(false ,errorMessage);
    }
  }

  @override
  Future<void> saveUserNumberAndPassword(String number, String password) {
    return authRepoInterface.saveUserCredentials(number, password);
  }

  @override
  Future<void> saveUserToken(String token) {
    return authRepoInterface.saveUserToken(token);
  }

  @override
  Future setLanguageCode(String languageCode) {
    return authRepoInterface.setLanguageCode(languageCode);
  }

  @override
  Future updateToken() async{
      ApiResponse apiResponse = await authRepoInterface.updateToken();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      return apiResponse;
    } else {

    }
  }

  @override
  Future verifyOtp(String identity, String otp) async{
   ApiResponse apiResponse = await authRepoInterface.verifyOtp(identity, otp);
   if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
     return ResponseModel(true, apiResponse.response!.data["message"]);
   } else {
     String? errorMessage;
     if (apiResponse.error is String) {
       if (kDebugMode) {
         print(apiResponse.error.toString());
       }
       errorMessage = apiResponse.error.toString();
     } else {
       ErrorResponse errorResponse = apiResponse.error;
       if (kDebugMode) {
         print(errorResponse.errors![0].message);
       }
       errorMessage = errorResponse.errors![0].message;
     }
     return ResponseModel(false, errorMessage);
   }
  }

  @override
  Future firebaseAuthTokenStore({required String userInput, required String token}) {
    return authRepoInterface.firebaseAuthTokenStore(userInput, token);
  }

  @override
  Future firebaseAuthVerify({required String phoneNumber, required String session, required String otp, required bool isForgetPassword}) {
    return authRepoInterface.firebaseAuthVerify(phoneNumber: phoneNumber, session: session, otp: otp, isForgetPassword: isForgetPassword);
  }

  @override
  Future checkVendorExistPhone({required String phoneNumber}) {
    return authRepoInterface.checkVendorExistPhone(phoneNumber: phoneNumber);
  }

}