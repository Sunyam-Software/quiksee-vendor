import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/features/auth/domain/models/register_model.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/data/model/response/response_model.dart';
import 'package:quiksee_vendor_app/features/auth/domain/services/auth_service_interface.dart';
import 'package:quiksee_vendor_app/features/auth/enums/from_page.dart';
import 'package:quiksee_vendor_app/features/auth/screens/otp_verification_screen.dart';
import 'package:quiksee_vendor_app/features/auth/widgets/login_approval_dialog.dart';
import 'package:quiksee_vendor_app/features/auth/widgets/reset_password_widget.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:quiksee_vendor_app/features/order/controllers/order_controller.dart';
import 'package:quiksee_vendor_app/features/transaction/controllers/transaction_controller.dart';
import 'package:quiksee_vendor_app/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee_vendor_app/features/refund/controllers/refund_controller.dart';
import 'package:quiksee_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee_vendor_app/features/coupon/controllers/coupon_controller.dart';
import 'package:quiksee_vendor_app/features/pos/controllers/cart_controller.dart';
import 'package:quiksee_vendor_app/features/review/controllers/product_review_controller.dart';
import 'package:quiksee_vendor_app/features/restock/controllers/restock_controller.dart';
import 'package:quiksee_vendor_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:quiksee_vendor_app/features/splash/domain/models/config_model.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/helper/country_code_helper.dart';
import 'package:quiksee_vendor_app/helper/image_size_checker.dart';
import 'package:quiksee_vendor_app/localization/app_localization.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/localization/controllers/localization_controller.dart';
import 'package:quiksee_vendor_app/main.dart';

class AuthController with ChangeNotifier {
  final AuthServiceInterface authServiceInterface;
  AuthController({required this.authServiceInterface});
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final String _loginErrorMessage = '';
  String get loginErrorMessage => _loginErrorMessage;
  XFile? _sellerProfileImage;
  XFile? _shopLogo;
  XFile? _shopBanner;
  XFile? secondaryBanner;
  XFile? offerBanner;
  XFile? get sellerProfileImage => _sellerProfileImage;
  XFile? get shopLogo => _shopLogo;
  XFile? get shopBanner => _shopBanner;
  bool? _isTermsAndCondition = false;
  bool? get isTermsAndCondition => _isTermsAndCondition;
  bool _isActiveRememberMe = false;
  bool get isActiveRememberMe => _isActiveRememberMe;
  int _selectionTabIndex = 1;
  int get selectionTabIndex =>_selectionTabIndex;
  String _verificationCode = '';
  String get verificationCode => _verificationCode;
  bool _isEnableVerificationCode = false;
  bool get isEnableVerificationCode => _isEnableVerificationCode;
  String? _verificationMsg = '';
  String? get verificationMessage => _verificationMsg;
  final String _email = '';
  final String _phone = '';
  String get email => _email;
  String get phone => _phone;
  bool _isPhoneNumberVerificationButtonLoading = false;
  bool get isPhoneNumberVerificationButtonLoading => _isPhoneNumberVerificationButtonLoading;
  String? _countryDialCode = '+91';
  String? get countryDialCode => _countryDialCode;

  bool _resendButtonLoading = false;
  bool get resendButtonLoading => _resendButtonLoading;

  String? _verificationID = '';
  String? get verificationID => _verificationID;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController shopNameController = TextEditingController();
  TextEditingController shopAddressController = TextEditingController();
  TextEditingController tinNumberController = TextEditingController();

  FocusNode firstNameNode = FocusNode();
  FocusNode lastNameNode = FocusNode();
  FocusNode emailNode = FocusNode();
  FocusNode phoneNode = FocusNode();
  FocusNode passwordNode = FocusNode();
  FocusNode confirmPasswordNode = FocusNode();
  FocusNode shopNameNode = FocusNode();
  FocusNode shopAddressNode = FocusNode();

  bool _lengthCheck = false;
  bool _numberCheck = false;
  bool _uppercaseCheck = false;
  bool _lowercaseCheck = false;
  bool _spatialCheck = false;
  bool _showPassView = false;

  bool get lengthCheck => _lengthCheck;
  bool get numberCheck => _numberCheck;
  bool get uppercaseCheck => _uppercaseCheck;
  bool get lowercaseCheck => _lowercaseCheck;
  bool get spatialCheck => _spatialCheck;
  bool get showPassView => _showPassView;

  bool _isUnAuthorize = false;
  bool get isUnAuthorize => _isUnAuthorize;

  static String? activeLoginApprovalRequestId;

  bool _waitingLoginApproval = false;
  bool get waitingLoginApproval => _waitingLoginApproval;

    Future<ApiResponse> login(BuildContext context, {String? emailAddress, String? password}) async {
    _isLoading = true;
    _waitingLoginApproval = false;
    notifyListeners();
    ApiResponse apiResponse = await authServiceInterface.login(emailAddress: emailAddress, password: password);
    if (apiResponse.response?.statusCode == 200) {
      final data = apiResponse.response?.data;
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final hasToken = map['token'] != null && '${map['token']}'.trim().isNotEmpty;

      if (!hasToken) {
        _waitingLoginApproval = false;
        _isLoading = false;
        notifyListeners();
        showQuikseeSnackBarWidget(
          map['message']?.toString().trim().isNotEmpty == true
              ? map['message'].toString()
              : (getTranslated('login_failed', Get.context!) ?? 'Login failed. Please try again.'),
          Get.context!,
          sanckBarType: SnackBarType.error,
        );
        return apiResponse;
      }

      _waitingLoginApproval = false;
      _isLoading = false;
      await updateToken(context);
      setCurrentLanguage(Provider.of<LocalizationController>(Get.context!, listen: false).getCurrentLanguage()??'en');
      setUnAuthorize(false);
      notifyListeners();
      return apiResponse;
    }
    _isLoading = false;
    notifyListeners();
    return apiResponse;
  }

  Future<bool> _pollLoginApproval({required String requestId, required int expiresIn}) async {
    final deadline = DateTime.now().add(Duration(seconds: expiresIn + 5));

    while (true) {
      final handled = await _handleLoginApprovalStatus(requestId);
      if (handled != null) {
        return handled;
      }
      if (!DateTime.now().isBefore(deadline)) {
        break;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    showQuikseeSnackBarWidget(
      getTranslated('login_approval_expired', Get.context!) ?? 'Login approval expired. Try again.',
      Get.context!,
      sanckBarType: SnackBarType.warning,
    );
    return false;
  }

  Future<bool?> _handleLoginApprovalStatus(String requestId) async {
    final statusResp = await authServiceInterface.loginApprovalStatus(requestId: requestId);
    if (statusResp.response?.statusCode != 200 || statusResp.response?.data is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(statusResp.response!.data as Map);
    final status = '${map['status'] ?? ''}';
    if (status == 'approved' && map['token'] != null) {
      await authServiceInterface.saveUserToken(map['token'].toString());
      showQuikseeSnackBarWidget(
        getTranslated('login_approval_approved', Get.context!) ?? 'Login approved',
        Get.context!,
        sanckBarType: SnackBarType.success,
      );
      return true;
    }
    if (status == 'denied') {
      showQuikseeSnackBarWidget(
        getTranslated('login_approval_denied', Get.context!) ?? 'Login denied by the other device',
        Get.context!,
        sanckBarType: SnackBarType.error,
      );
      return false;
    }
    if (status == 'expired' || status == 'not_found') {
      showQuikseeSnackBarWidget(
        getTranslated('login_approval_expired', Get.context!) ?? 'Login approval expired. Try again.',
        Get.context!,
        sanckBarType: SnackBarType.warning,
      );
      return false;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLoginApprovalStatus(String requestId) async {
    final statusResp = await authServiceInterface.loginApprovalStatusPeek(requestId: requestId);
    if (statusResp.response?.statusCode != 200 || statusResp.response?.data is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(statusResp.response!.data as Map);
  }

  Future<void> resolveLoginApproval({required String requestId, required String action}) async {
    final resp = await authServiceInterface.resolveLoginApproval(requestId: requestId, action: action);
    if (resp.response?.statusCode == 200) {
      final data = resp.response?.data is Map
          ? Map<String, dynamic>.from(resp.response!.data as Map)
          : <String, dynamic>{};
      final success = data['success'] != false;
      final msg = '${data['message'] ?? ''}';
      if (!success) {

        return;
      }
      if (msg.isNotEmpty) {
        showQuikseeSnackBarWidget(
          msg,
          Get.context!,
          sanckBarType: action == 'approve' ? SnackBarType.success : SnackBarType.warning,
        );
      }
      if (action == 'approve') {

        notifyListeners();
      }
      return;
    }

    final err = resp.error?.toString() ?? '';
    if (err.toLowerCase().contains('already') || err.toLowerCase().contains('resolved')) {
      return;
    }
    showQuikseeSnackBarWidget(
      err.isNotEmpty ? err : 'Failed',
      Get.context!,
      sanckBarType: SnackBarType.error,
    );
  }

  Future<void> checkPendingLoginApproval() async {

    return;
  }

  Future<void> acknowledgePendingLoginApproval() async {
    return;
  }

  Future<void> setCurrentLanguage(String currentLanguage) async {
      await authServiceInterface.setLanguageCode(currentLanguage);
  }

  Future<ResponseModel?> forgotPassword(String email, bool isNumber, ConfigModel? config, {FromPage? fromPage})async {
    bool isResend = fromPage == FromPage.verification;
    ResponseModel? responseModel;

    _isLoading = true;
    if(isResend) {
      _resendButtonLoading = true;
    }
    notifyListeners();

    if(isNumber && config?.forgotPasswordVerification == 'phone' &&  config?.vendorForgotPasswordSmsMethod == 'firebase') {
      checkVendorExistPhone(email).then((response) {
        if(response.response?.statusCode == 200) {
          firebaseVerifyPhoneNumber(email, isResend: isResend, isForgetPassword: true);
        } else {
          _isLoading = false;
          if(isResend) {
            _resendButtonLoading = false;
          }
          notifyListeners();
          showQuikseeSnackBarWidget(response.error, Get.context!, sanckBarType: SnackBarType.error);
        }
      });
    } else {
      responseModel = await authServiceInterface.forgotPassword(email);
      _isLoading = false;
    }

    if(isResend) {
      _resendButtonLoading = false;
    }
    notifyListeners();
    return responseModel;
  }

  Future<void> updateToken(BuildContext context) async {
      await authServiceInterface.updateToken();
  }

  void updateTermsAndCondition(bool? value) {
    _isTermsAndCondition = value;
    notifyListeners();
  }

  void toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    notifyListeners();
  }

  void setIndexForTabBar(int index, {bool isNotify = true}){
    _selectionTabIndex = index;
    if(isNotify){
      notifyListeners();
    }
  }

  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  Future<bool> clearSharedData({bool fromUnAuthorizationError = false, bool clearServerSession = true}) async {
    if(fromUnAuthorizationError){
      if (kDebugMode) {
        print("===Inside==fromUnAuthorizationError");
      }
      clearServerSession = false;
    }
    _clearVendorSessionProviders();
    return await authServiceInterface.clearSharedData(clearServerSession: clearServerSession);
  }

  void _clearVendorSessionProviders() {
    final context = Get.context;
    if (context == null) return;
    try {
      Provider.of<ShopController>(context, listen: false).clearShopModel(isUpdate: false);
    } catch (_) {}
    try {
      Provider.of<ProductController>(context, listen: false).clearSessionData(notify: false);
    } catch (_) {}
    try {
      Provider.of<ProfileController>(context, listen: false).clearSessionData(notify: false);
    } catch (_) {}
    try {
      Provider.of<BankInfoController>(context, listen: false).clearSessionData(notify: false);
    } catch (_) {}
    try {
      Provider.of<OrderController>(context, listen: false).clearSessionData(notify: false);
    } catch (_) {}
    try {
      Provider.of<TransactionController>(context, listen: false).clearSessionData(notify: false);
    } catch (_) {}
    try {
      Provider.of<WalletController>(context, listen: false).clearSessionData(notify: false);
    } catch (_) {}
    try {
      Provider.of<RefundController>(context, listen: false).emptyRefundModel();
      Provider.of<RefundController>(context, listen: false).emptyRefundDetailsModel();
    } catch (_) {}
    try {
      Provider.of<OrderDetailsController>(context, listen: false).emptyOrderDetails();
    } catch (_) {}
    try {
      Provider.of<CouponController>(context, listen: false).clearCouponData();
    } catch (_) {}
    try {
      Provider.of<CartController>(context, listen: false).removeAllCartList();
    } catch (_) {}
    try {
      Provider.of<ProductReviewController>(context, listen: false).resetReviewData(isUpdate: false);
    } catch (_) {}
    try {
      Provider.of<RestockController>(context, listen: false).emptyReStockData();
    } catch (_) {}
    try {
      Provider.of<BottomMenuController>(context, listen: false).resetNavBar();
    } catch (_) {}
  }

  void saveUserNumberAndPassword(String number, String password) {
    authServiceInterface.saveUserNumberAndPassword(number, password);
  }

  String getUserEmail() {
    return authServiceInterface.getUserEmail();
  }

  String getUserPassword() {
    return authServiceInterface.getUserPassword();
  }

  Future<bool> clearUserEmailAndPassword() async {
    return await authServiceInterface.clearUserNumberAndPassword();
  }

  String getUserToken() {
    return authServiceInterface.getUserToken();
  }

  void updateVerificationCode(String query) {
    if (query.length == 6) {
      _isEnableVerificationCode = true;
    } else {
      _isEnableVerificationCode = false;
    }
    _verificationCode = query;
    notifyListeners();
  }

  Future<ResponseModel> verifyOtp(String phone) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ResponseModel responseModel = await authServiceInterface.verifyOtp(phone, _verificationCode);
    _isPhoneNumberVerificationButtonLoading = false;
    _verificationMsg = responseModel.message;
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> resetPassword(String identity, String otp, String password, String confirmPassword, String? token) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ResponseModel responseModel = await authServiceInterface.resetPassword(identity,otp,password,confirmPassword, token);
    _isPhoneNumberVerificationButtonLoading = false;
    _verificationMsg = responseModel.message;
    notifyListeners();
    return responseModel;
  }

  void pickImage(bool isProfile, bool shopLogo, bool isRemove, {bool secondary = false, bool offer = false}) async {
    if(isRemove) {
      _sellerProfileImage = null;
      _shopLogo = null;
      _shopBanner = null;
      secondaryBanner = null;
    } else {
      XFile? image = await ImageValidationHelper.validateAndPickImage(
        source: ImageSource.gallery,
        context: Get.context!
      );

      double value = 0;

      if (isProfile && image != null) {
        _sellerProfileImage = image;
      } else if(shopLogo && image != null) {
        _shopLogo = image;
      }else if(secondary && image != null) {
        secondaryBanner = image;
      }else if(offer && image != null) {
        offerBanner = image;
      }else if ( image != null) {
        _shopBanner = image;
      }
    }
    notifyListeners();
  }

  Future<ApiResponse> registration(BuildContext context,RegisterModel registerModel, XFile? tinCertificate) async {
    _isLoading = true;
    notifyListeners();
    try {
      ApiResponse response = await authServiceInterface.registration(_sellerProfileImage, _shopLogo, _shopBanner, secondaryBanner, registerModel, tinCertificate);

      if(response.response?.statusCode == 200) {
        firstNameController.clear();
        lastNameController.clear();
        phoneController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        shopNameController.clear();
        shopAddressController.clear();
        _sellerProfileImage = null;
        _shopLogo = null;
        _shopBanner = null;
        secondaryBanner = null;
        Provider.of<ShopController>(Get.context!, listen: false).clearShopModel();
        showQuikseeSnackBarWidget(getTranslated("you_are_successfully_registered", Get.context!), Get.context!, isError: false, sanckBarType: SnackBarType.success);
      } else {
        final errorMessage = _registrationErrorMessage(response);
        log("---->registration error===> ${response.response?.statusCode}/${response.error}/${response.response?.statusMessage}/${response.response?.data}");
        showQuikseeSnackBarWidget(
          errorMessage ?? 'Registration failed. Please try again.',
          Get.context!,
          sanckBarType: SnackBarType.warning,
        );
      }
      return response;
    } catch (e, stack) {
      log('registration exception: $e', stackTrace: stack);
      showQuikseeSnackBarWidget(
        'Registration failed. Please check your connection and try again.',
        Get.context!,
        sanckBarType: SnackBarType.warning,
      );
      return ApiResponse.withError(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _registrationErrorMessage(ApiResponse response) {
    try {
      final statusCode = response.response?.statusCode;
      final data = response.response?.data;
      if (data is String && data.contains('<!DOCTYPE html>')) {
        if (statusCode == 404) {
          return 'Registration service not found. Please update the app or contact support.';
        }
        return 'Server error ($statusCode). Please try again later.';
      }
      dynamic decoded;
      if (data is String && data.isNotEmpty) {
        decoded = jsonDecode(data);
      } else if (data is Map) {
        decoded = data;
      } else if (response.error != null && response.error.toString().isNotEmpty) {
        return response.error.toString();
      } else {
        return null;
      }

      if (decoded is! Map) return null;
      final message = decoded['message'];
      if (message is List && message.isNotEmpty) {
        final first = message.first;
        if (first is Map && first['message'] != null) {
          return first['message'].toString();
        }
      } else if (message is String && message.isNotEmpty) {
        return message;
      }
      if (decoded['error'] != null && decoded['error'].toString().isNotEmpty) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return null;
  }

  void setCountryDialCode(String? setValue, {bool notify = true}) {
    _countryDialCode = CountryCodeHelper.dialCodeOrDefault(setValue);
    if (notify) {
      notifyListeners();
    }
  }

  void emptyRegistrationData ({bool isUpdate = false}) {
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    shopNameController.clear();
    shopAddressController.clear();
    _sellerProfileImage = null;
    _shopLogo = null;
    _shopBanner = null;
    secondaryBanner = null;
    if(isUpdate){
      notifyListeners();
    }
  }

  void validPassCheck(String pass, {bool isUpdate = true}){
    _lengthCheck = false;
    _numberCheck = false;
    _uppercaseCheck = false;
    _lowercaseCheck = false;
    _spatialCheck = false;

    if(pass.length > 7){
      _lengthCheck = true;
    }
    if(pass.contains(RegExp(r'[a-z]'))){
      _lowercaseCheck = true;
    }
    if(pass.contains(RegExp(r'[A-Z]'))){
      _uppercaseCheck = true;
    }
    if(pass.contains(RegExp(r'[ .!@#$&*~^%]'))){
      _spatialCheck = true;
    }
    if(pass.contains(RegExp(r'[\d+]'))){
      _numberCheck = true;
    }
    if(isUpdate) {
      notifyListeners();
    }
  }

  void showHidePass({bool isUpdate = true}) {
    _showPassView = ! _showPassView;
    if(isUpdate) {
      notifyListeners();
    }
  }

  bool isPasswordValid (){
    return (_lengthCheck && _numberCheck && _lowercaseCheck && _uppercaseCheck && _spatialCheck && _numberCheck);
  }

  void setUnAuthorize(bool value, {bool update = false}) {
    _isUnAuthorize = value;
    if(update) {
      notifyListeners();
    }
  }

  Future<void> firebaseVerifyPhoneNumber(String phoneNumber, {bool isForgetPassword = false, bool isResend = false, String? toNavigateScreen, VoidCallback? onLoginSuccess}) async {
    if(!isResend) {
      _isLoading = true;
    }
    _resendButtonLoading = true;
    notifyListeners();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        _isPhoneNumberVerificationButtonLoading = false;
        _isLoading = false;
        notifyListeners();

        if(e.code == 'invalid-phone-number') {

          showQuikseeSnackBarWidget(getTranslated('please_submit_a_valid_phone_number', Get.context!), Get.context!);
        }else{
          showQuikseeSnackBarWidget(getTranslated('${e.message}'.replaceAll('_', ' ').toCapitalized(), Get.context!), Get.context!);
        }

      },
      codeSent: (String vId, int? resendToken) async {
        _isPhoneNumberVerificationButtonLoading = false;
        _resendButtonLoading = false;
        notifyListeners();

        bool callRoute = !isResend;

        await callFirebaseStoretiken(phoneNumber, vId);

        _verificationID = vId;

        if(isResend) {
          showQuikseeSnackBarWidget(getTranslated('resend_code_successful', Get.context!), Get.context!, isError: false);
        }

        if(callRoute) {
          Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => VerificationScreen(phoneNumber, session: vId)));
          _isLoading = false;
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _resendButtonLoading = false;
        _isLoading = false;
      },
    );

    _resendButtonLoading = false;
    notifyListeners();
  }

  Future<void> callFirebaseStoretiken (String phoneNumber, String vID) async {
     await authServiceInterface.firebaseAuthTokenStore(userInput: phoneNumber, token: vID);
  }

  Future<ApiResponse> checkVendorExistPhone(String  phone) async {
    notifyListeners();
    ApiResponse responseModel = await authServiceInterface.checkVendorExistPhone(phoneNumber: phone);

    notifyListeners();
    return responseModel;
  }

  Future<void> firebaseOtpVerification({required String phoneNumber, required String session, required String otp, bool isForgetPassword = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();

    ApiResponse apiResponse = await authServiceInterface.firebaseAuthVerify(
      session: session, phoneNumber: phoneNumber,
      otp: otp, isForgetPassword: isForgetPassword,
    );

    if(apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(
        builder: (_) => ResetPasswordWidget(
          mobileNumber: phoneNumber,
          otp: otp,
          token: session,
        )), (route) => false
      );
    } else {
      ApiChecker.checkApi(apiResponse, firebaseResponse: true);
    }

    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
  }

}
