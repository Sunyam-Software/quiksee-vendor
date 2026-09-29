import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_body.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/data/model/response/response_model.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/features/profile/domain/services/profice_service_interface.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/helper/country_code_helper.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class ProfileController with ChangeNotifier {
  final ProfileServiceInterface profileServiceInterface;

  ProfileController({required this.profileServiceInterface}) {

    unawaited(hydrateSellerIdFromCache());
  }

  ProfileInfoModel? _userInfoModel;
  ProfileInfoModel? get userInfoModel => _userInfoModel;
  int? _userId;
  int? get userId =>_userId;
  String? _profileImage;
  String? get profileImage =>_profileImage;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  Future<ResponseModel>? _sellerInfoInFlight;
  bool _hydratedFromCache = false;

  String? _countryDialCode = '+91';
  String? get countryDialCode => _countryDialCode;

  Future<void> hydrateSellerIdFromCache() async {
    if (_userId != null) {
      _hydratedFromCache = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getInt(AppConstants.cachedSellerId);
      if (cached != null && cached > 0) {
        _userId = cached;
        _hydratedFromCache = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistSellerId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.cachedSellerId, id);
    } catch (_) {}
  }

  Future<void> _clearPersistedSellerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.cachedSellerId);
    } catch (_) {}
  }

  Future<int?> resolveSellerId({Duration networkTimeout = const Duration(seconds: 8)}) async {
    if (_userId != null) return _userId;
    await hydrateSellerIdFromCache();
    if (_userId != null) return _userId;
    try {
      await getSellerInfo().timeout(networkTimeout);
    } catch (_) {}
    return _userId;
  }

  Future<ResponseModel> getSellerInfo() async {

    if (_sellerInfoInFlight != null) {
      return _sellerInfoInFlight!;
    }
    _sellerInfoInFlight = _fetchSellerInfo();
    try {
      return await _sellerInfoInFlight!;
    } finally {
      _sellerInfoInFlight = null;
    }
  }

  Future<ResponseModel> _fetchSellerInfo() async {
    if (!_hydratedFromCache && _userId == null) {
      await hydrateSellerIdFromCache();
    }
    ResponseModel responseModel;
    ApiResponse apiResponse = await profileServiceInterface.getSellerInfo();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _userInfoModel = ProfileInfoModel.fromJson(apiResponse.response!.data);
      _userId = _userInfoModel!.id;
      _profileImage = _userInfoModel!.image;
      if (_userId != null) {
        unawaited(_persistSellerId(_userId!));
      }
      responseModel = ResponseModel(true, 'successful');
    } else {
      String? errorMessage;
      if (apiResponse.error is String) {
        errorMessage = apiResponse.error.toString();
      } else {
        errorMessage = apiResponse.error.errors[0].message;
      }
      if (kDebugMode) {
        print(errorMessage);
      }
      responseModel = ResponseModel(false, errorMessage);
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return responseModel;
  }

  void setFreeDeliveryStatus(String val){
    _userInfoModel?.freeOverDeliveryAmountStatus = int.parse(val);
    notifyListeners();
  }

  Future<bool> updateUserInfo(ProfileInfoModel updateUserModel, ProfileBody seller, File? file, String token, String password) async {
    _isLoading = true;
    notifyListeners();

    ApiResponse apiResponse = await profileServiceInterface.updateProfile(updateUserModel, seller, file, token, password);
    _isLoading = false;

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      await getSellerInfo();
      showQuikseeSnackBarWidget(getTranslated('updated_successfully', Get.context!) ?? "", Get.context!, isError: false);
      notifyListeners();
      return true;
    }

    if (kDebugMode) {
      print('Profile update failed: ${apiResponse.response?.statusCode} ${apiResponse.error}');
    }
    showQuikseeSnackBarWidget(
      apiResponse.error?.toString() ?? getTranslated('something_went_wrong', Get.context!) ?? 'Update failed',
      Get.context!,
      sanckBarType: SnackBarType.error,
    );
    notifyListeners();
    return false;
  }

  Future<ApiResponse> deleteCustomerAccount(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    ApiResponse apiResponse = await profileServiceInterface.deleteUserAccount();
    _isLoading = false;
    notifyListeners();
    return apiResponse;
  }

  void setCountryDialCode (String? setValue){
    _countryDialCode = CountryCodeHelper.dialCodeOrDefault(setValue);
  }

  void updateWalletAmount(String balance) {
    if( _userInfoModel!.wallet!.totalEarning != null){
      _userInfoModel!.wallet!.totalEarning = (_userInfoModel?.wallet?.totalEarning ?? 0) + double.parse(balance);
      if(_userInfoModel?.wallet?.pendingWithdraw != null) {
        _userInfoModel!.wallet!.pendingWithdraw = (_userInfoModel?.wallet?.pendingWithdraw ?? 0) - double.parse(balance);
      }
      notifyListeners();
    }
  }

  void clearSessionData({bool notify = true}) {
    _userInfoModel = null;
    _userId = null;
    _profileImage = null;
    _isLoading = false;
    _sellerInfoInFlight = null;
    _hydratedFromCache = false;
    unawaited(_clearPersistedSellerId());
    if (notify) {
      notifyListeners();
    }
  }

}
