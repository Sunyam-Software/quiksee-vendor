import 'dart:async';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/auth/domain/models/password_recovery_config_model.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/auth/domain/services/auth_service_interface.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/utill/app_constants.dart';

class AuthController extends GetxController implements GetxService {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface}) ;


  final bool _notification = true;
  XFile? _pickedFile;
  final String _loginErrorMessage = '';
  String get loginErrorMessage => _loginErrorMessage;
  bool _willPhoneNumberVerificationButtonLoading = false;
  bool get willPhoneNumberVerificationButtonLoading => _willPhoneNumberVerificationButtonLoading;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _loginInProgress = false;
  bool get loginInProgress => _loginInProgress;
  bool get notification => _notification;
  XFile? get pickedFile => _pickedFile;
  String _countryDialCode = "+1";
  String get countryCode => _countryDialCode;

  int _selectionTabIndex = 1;
  int get selectionTabIndex =>_selectionTabIndex;


  void updateCountryDialCode (String value,{bool isUpdate = true}){
    _countryDialCode = value;
    if(isUpdate){
      update();
    }
  }


  void setIndexForTabBar(int index, {bool notify = true}){
    _selectionTabIndex = index;
    if(notify){
      update();
    }
  }


  Future<ResponseModel> login(String countryCode, String phone, String password) async {
    if (_loginInProgress) {
      return ResponseModel(false, '');
    }
    _loginInProgress = true;
    _isLoading = true;
    update();
    try {
      final responseModel =
          await authServiceInterface.login(countryCode, phone, password);
      if (responseModel.isSuccess) {
        await setCurrentLanguage(
            Get.find<LocalizationController>().getCurrentLanguage() ?? 'en');
      }
      return responseModel;
    } finally {
      _loginInProgress = false;
      _isLoading = false;
      update();
    }
  }


  Future<void> setCurrentLanguage(String currentLanguage) async {
    await authServiceInterface.setLanguageCode(currentLanguage);
  }

  void pickImage() async {
    _pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: AppConstants.imageQuality,
    );
    update();
  }


  Future<void> updateToken() async {
    await authServiceInterface.updateToken();
  }


  String _verificationCode = '';
  String get verificationCode => _verificationCode;

  PasswordRecoveryConfigModel? _recoveryConfig;
  PasswordRecoveryConfigModel? get recoveryConfig => _recoveryConfig;
  bool get isEmailRecovery => _recoveryConfig?.isEmail ?? true;

  String _recoveryIdentity = '';
  String get recoveryIdentity => _recoveryIdentity;

  bool _isLoadingRecoveryConfig = false;
  bool get isLoadingRecoveryConfig => _isLoadingRecoveryConfig;

  void setRecoveryIdentity(String identity) {
    _recoveryIdentity = identity;
    update();
  }

  Future<void> loadPasswordRecoveryConfig() async {
    _isLoadingRecoveryConfig = true;
    update();
    _recoveryConfig = await authServiceInterface.getPasswordRecoveryConfig();
    if (_recoveryConfig == null) {
      final splashMethod = Get.find<SplashController>()
          .configModel
          ?.forgotPasswordVerification;
      if (splashMethod != null && splashMethod.isNotEmpty) {
        _recoveryConfig = PasswordRecoveryConfigModel(
          forgotPasswordMethod: splashMethod,
          identityField: splashMethod == 'email' ? 'email' : 'phone',
          otpExpiryMinutes: 2,
        );
      }
    }
    _isLoadingRecoveryConfig = false;
    update();
  }

  void updateVerificationCode(String query) {
    _verificationCode = query;
    update();
  }


  bool _isActiveRememberMe = false;

  bool get isActiveRememberMe => _isActiveRememberMe;

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    update();
  }

  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  Future<bool> clearSharedData() async {
    if (Get.isRegistered<OrderTransferController>()) {
      Get.find<OrderTransferController>().resetSessionForLogout();
    }
    return await authServiceInterface.clearSharedData();
  }

  void saveUserCredentials(String countryCode, String number, String password) {
    authServiceInterface.saveUserCredentials(countryCode, number, password);
  }


  String getUserEmail() {
    return authServiceInterface.getUserEmail();
  }

  String getUserPassword() {
    return authServiceInterface.getUserPassword();
  }

  String? getUserCountryCode() {
    return authServiceInterface.getUserCountryCode();
  }

  Future<bool> clearUserEmailAndPassword() async {
    return authServiceInterface.clearUserCredentials();
  }


  String getUserToken() {
    return authServiceInterface.getUserToken();
  }


  void initData() {
    _pickedFile = null;
  }

  Future <Response> forgotPassword(String? identity) async {
    _isLoading = true;
    update();
    Response _response = await authServiceInterface.forgotPassword(identity);

    _isLoading = false;
    update();
    return _response;
  }


  Future<Response> verifyOtp(String otp, String? identity) async {
    _willPhoneNumberVerificationButtonLoading = true;
    update();
    Response response = await authServiceInterface.verifyOtp(otp, identity);
    _willPhoneNumberVerificationButtonLoading = false;
    update();
    return response;
  }

  Future<Response> resetPassword({
    required String identity,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    update();
    final response = await authServiceInterface.resetPassword(
      identity: identity,
      otp: otp,
      password: password,
      confirmPassword: confirmPassword,
    );
    _isLoading = false;
    update();
    return response;
  }
}