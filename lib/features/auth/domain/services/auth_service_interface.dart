import 'package:image_picker/image_picker.dart';
import 'package:quiksee_vendor_app/features/auth/domain/models/register_model.dart';

abstract class AuthServiceInterface {
  Future<dynamic> login({String? emailAddress, String? password});
  Future<dynamic> loginApprovalStatus({required String requestId});
  Future<dynamic> loginApprovalStatusPeek({required String requestId});
  Future<dynamic> resolveLoginApproval({required String requestId, required String action});
  Future<dynamic> pendingLoginApproval();
  Future<dynamic> logout();
  Future<dynamic> setLanguageCode(String languageCode);
  Future<dynamic> forgotPassword(String identity);
  Future<dynamic> resetPassword(String identity, String otp ,String password, String confirmPassword, String? token);
  Future<dynamic> verifyOtp(String identity, String otp);
  Future<dynamic> updateToken();
  Future<void> saveUserToken(String token);
  String getUserToken();
  bool isLoggedIn();
  Future<dynamic> clearSharedData({bool clearServerSession = true});
  Future<dynamic> saveUserNumberAndPassword(String number, String password);
  String getUserEmail();
  String getUserPassword();
  Future<dynamic> clearUserNumberAndPassword();
  Future<dynamic> registration(XFile? profileImage, XFile? shopLogo, XFile? shopBanner, XFile? secondaryBanner, RegisterModel registerModel, XFile? tinCertificate);
  Future<dynamic>  firebaseAuthTokenStore({required String userInput, required String token});
  Future<dynamic> firebaseAuthVerify({required String phoneNumber, required String session, required String otp, required bool isForgetPassword});
  Future<dynamic> checkVendorExistPhone({required String phoneNumber});
}