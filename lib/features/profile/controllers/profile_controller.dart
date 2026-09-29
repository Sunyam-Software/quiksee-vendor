import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/auth/domain/models/response_model.dart';
import 'package:quiksee/features/profile/domain/services/profile_service_interface.dart';
import 'package:quiksee/features/profile/domain/models/userinfo_model.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/features/withdraw/controllers/withdraw_controller.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/helper/app_permissions_helper.dart';
import 'package:quiksee/helper/force_stop_warning_helper.dart';
import 'package:quiksee/helper/image_size_checker.dart';
import 'package:quiksee/helper/location_permission_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController extends GetxController implements GetxService {
  final ProfileServiceInterface profileServiceInterface;
  ProfileController({required this.profileServiceInterface});


  UserInfoModel? _profileModel;
  UserInfoModel? get profileModel => _profileModel;
  String? _profileImage;
  String? get profileImage => _profileImage;
  File? file;
  final picker = ImagePicker();
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _pendingProfileRefresh = false;
  Future<void>? _ongoingProfileFetch;
  DateTime? _withdrawWalletGuardUntil;
  double? _guardedWithdrawableBalance;
  double? _guardedPendingWithdraw;
  double? _guardedTotalWithdraw;
  double? _lastWithdrawRequestAmount;
  bool _pendingGoOnline = false;
  bool _syncingOnlineGps = false;


  UserInfoModel? _userInfoModel;
  UserInfoModel? get userInfoModel => _userInfoModel;

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


  final FocusNode fNameFocus = FocusNode();
  final FocusNode lNameFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();


  Future<void> getProfile({
    bool isUpdate = true,
    bool silent = false,
    bool skipSideEffects = false,
    bool bypassWalletGuard = false,
    bool waitForInFlight = false,
  }) async {
    if (_ongoingProfileFetch != null) {
      _pendingProfileRefresh = true;
      if (!waitForInFlight) return;
      try {
        await _ongoingProfileFetch!.timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('getProfile waitForInFlight error: $e');
        _ongoingProfileFetch = null;
      }
      if (!_pendingProfileRefresh) return;
      _pendingProfileRefresh = false;
    }

    _ongoingProfileFetch = _fetchProfile(
      isUpdate: isUpdate,
      silent: silent,
      bypassWalletGuard: bypassWalletGuard,
    );
    try {
      await _ongoingProfileFetch;
    } finally {
      _ongoingProfileFetch = null;
    }

    if (!skipSideEffects) {
      unawaited(_runProfileSideEffects(isUpdate: isUpdate));
    }

    if (_pendingProfileRefresh) {
      _pendingProfileRefresh = false;
      await getProfile(
        isUpdate: isUpdate,
        silent: silent,
        skipSideEffects: skipSideEffects,
        bypassWalletGuard: bypassWalletGuard,
        waitForInFlight: waitForInFlight,
      );
    }
  }

  Future<void> _fetchProfile({
    required bool isUpdate,
    required bool silent,
    required bool bypassWalletGuard,
  }) async {
    _isLoading = true;
    if (isUpdate) update();

    try {
      final info =
          await profileServiceInterface.getProfileInfo(silent: silent);
      if (info != null) {
        _profileModel = info;
        _profileImage = _profileModel?.imageFullUrl?.path;
        await _restoreBankExtrasFromCache();
        if (!bypassWalletGuard) {
          _applyWithdrawWalletGuardIfNeeded();
        }
      }
    } catch (e) {
      debugPrint('getProfile error: $e');
    } finally {
      _isLoading = false;
      if (isUpdate) update();
    }
  }

  Future<void> _runProfileSideEffects({required bool isUpdate}) async {
    final deferAssignmentSync = Get.isRegistered<AssignmentController>() &&
        Get.find<AssignmentController>().isBusyWithOffer;
    if (_profileModel != null &&
        Get.isRegistered<AssignmentController>() &&
        !deferAssignmentSync) {
      try {
        Get.find<AssignmentController>().loadDeliveryAreas();
        await Get.find<AssignmentController>().syncWithDriverStatus();
        if ((_profileModel?.pendingOffersCount ?? 0) > 0) {
          await Get.find<AssignmentController>()
              .fetchPendingOffers(showSheet: true);
        }
      } catch (e) {
        debugPrint('assignment sync error: $e');
      }
      if (isUpdate) {
        update();
      }
    }

    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().syncNewOrderPolling();
    }
    if (_profileModel?.isAccountActive == true && _profileModel?.isOnline == 1) {
      unawaited(syncOnlineGpsAndLocation());
    }
    unawaited(_syncDriverOnlineService());
  }

  /// Refreshes balance, delivery counts, and wallet stats after a completed order.
  Future<void> refreshAfterDelivery() async {
    await refreshWalletBalances();
  }

  void syncDashboardWalletOnReturn() {
    update();
    unawaited(refreshWalletBalances());
  }

  Future<void> refreshWalletBalances({bool includeWalletLists = false}) async {
    await getProfile(
      silent: true,
      skipSideEffects: true,
      waitForInFlight: true,
    );
    update();
    if (!includeWalletLists || !Get.isRegistered<WalletController>()) return;
    try {
      final wallet = Get.find<WalletController>();
      await wallet.getDepositedList('', '', 1, '', reload: true);
      if (wallet.selectedItem == 0) {
        await wallet.getOrderWiseDeliveryCharge('', '', 1, '');
      } else if (wallet.selectedItem == 1) {
        await wallet.refreshWithdrawLists(pending: false, withdrawn: true);
      } else if (wallet.selectedItem == 2) {
        await wallet.refreshWithdrawLists(pending: true, withdrawn: false);
      }
    } catch (e, stack) {
      debugPrint('refreshWalletBalances error: $e\n$stack');
    }
  }

  /// Refreshes wallet after admin approves/denies a withdraw push notification.
  Future<void> onWithdrawStatusNotification({bool denied = false}) async {
    clearWithdrawWalletGuard();
    applyWithdrawStatusFromNotification(denied: denied);
    try {
      await getProfile(
        silent: true,
        skipSideEffects: true,
        bypassWalletGuard: true,
        waitForInFlight: true,
      );
      update();

      if (Get.isRegistered<WithdrawController>()) {
        final withdraw = Get.find<WithdrawController>();
        await withdraw.getWithdrawList(
          '',
          '',
          1,
          'pending',
          reload: true,
          skipProfileRefresh: true,
        );
        await withdraw.getWithdrawList(
          '',
          '',
          1,
          'withdrawn',
          reload: true,
          skipProfileRefresh: true,
        );
      }

      if (Get.isRegistered<WalletController>()) {
        final wallet = Get.find<WalletController>();
        await wallet.getDepositedList('', '', 1, '', reload: true);
        wallet.update();
      }
    } catch (e, stack) {
      debugPrint('onWithdrawStatusNotification error: $e\n$stack');
    }
  }

  /// Clears optimistic withdraw guard so fresh server wallet data can apply.
  void clearWithdrawWalletGuard() {
    _clearWithdrawWalletGuard();
  }

  /// Updates wallet cards immediately after a withdraw request succeeds.
  void applyWithdrawLocally(double amount) {
    if (_profileModel == null || amount <= 0) return;
    final withdrawable = _profileModel!.withdrawableBalance ?? 0;
    if (amount > withdrawable) return;
    _profileModel!.withdrawableBalance = withdrawable - amount;
    _profileModel!.pendingWithdraw =
        (_profileModel!.pendingWithdraw ?? 0) + amount;
    _lastWithdrawRequestAmount = amount;
    _guardedWithdrawableBalance = _profileModel!.withdrawableBalance;
    _guardedPendingWithdraw = _profileModel!.pendingWithdraw;
    _guardedTotalWithdraw = _profileModel!.totalWithdraw;
    _withdrawWalletGuardUntil =
        DateTime.now().add(const Duration(seconds: 90));
    update();
  }

  /// Instantly updates dashboard wallet when admin approves/denies via push.
  void applyWithdrawStatusFromNotification({required bool denied}) {
    if (_profileModel == null) return;
    final amount = _lastWithdrawRequestAmount;
    if (amount == null || amount <= 0) return;

    final pending = _profileModel!.pendingWithdraw ?? 0;
    if (pending + 0.001 < amount) return;

    if (denied) {
      _profileModel!.pendingWithdraw = pending - amount;
      if (_profileModel!.pendingWithdraw! < 0) {
        _profileModel!.pendingWithdraw = 0;
      }
      _profileModel!.withdrawableBalance =
          (_profileModel!.withdrawableBalance ?? 0) + amount;
    } else {
      _profileModel!.pendingWithdraw = pending - amount;
      if (_profileModel!.pendingWithdraw! < 0) {
        _profileModel!.pendingWithdraw = 0;
      }
      _profileModel!.totalWithdraw =
          (_profileModel!.totalWithdraw ?? 0) + amount;
    }
    _lastWithdrawRequestAmount = null;
    update();
  }

  /// Keeps optimistic wallet values when the server profile has not caught up yet.
  void _applyWithdrawWalletGuardIfNeeded() {
    if (_withdrawWalletGuardUntil == null || _profileModel == null) return;
    if (DateTime.now().isAfter(_withdrawWalletGuardUntil!)) {
      _clearWithdrawWalletGuard();
      return;
    }

    final serverPending = _profileModel!.pendingWithdraw ?? 0;
    final serverWithdrawable = _profileModel!.withdrawableBalance ?? 0;
    final serverTotalWithdraw = _profileModel!.totalWithdraw ?? 0;

    // Server caught up with our optimistic withdraw request.
    if (_guardedPendingWithdraw != null &&
        serverPending + 0.001 >= _guardedPendingWithdraw! &&
        (_guardedWithdrawableBalance == null ||
            serverWithdrawable <= _guardedWithdrawableBalance! + 0.001)) {
      _clearWithdrawWalletGuard();
      return;
    }

    if (_guardedPendingWithdraw != null &&
        serverPending + 0.001 < _guardedPendingWithdraw!) {
      final withdrawableUnchanged = _guardedWithdrawableBalance == null ||
          serverWithdrawable <= _guardedWithdrawableBalance! + 0.001;

      if (withdrawableUnchanged ||
          (_guardedTotalWithdraw != null &&
              serverTotalWithdraw > _guardedTotalWithdraw! + 0.001)) {
        _clearWithdrawWalletGuard();
        return;
      }

      _profileModel!.pendingWithdraw = _guardedPendingWithdraw;
      _profileModel!.withdrawableBalance = _guardedWithdrawableBalance;
      return;
    }

    if (_guardedWithdrawableBalance != null &&
        serverWithdrawable > _guardedWithdrawableBalance! + 0.001) {
      _profileModel!.withdrawableBalance = _guardedWithdrawableBalance;
      return;
    }

    if (_guardedTotalWithdraw != null &&
        serverTotalWithdraw > _guardedTotalWithdraw! + 0.001) {
      _clearWithdrawWalletGuard();
    }
  }

  void _clearWithdrawWalletGuard() {
    _withdrawWalletGuardUntil = null;
    _guardedWithdrawableBalance = null;
    _guardedPendingWithdraw = null;
    _guardedTotalWithdraw = null;
  }


  Future<void> requestGoOnline(BuildContext context) async {
    if (_profileModel?.isAccountActive != true) {
      showQuikseeSnackBarWidget('account_not_activated'.tr);
      return;
    }
    final ready = await LocationPermissionHelper.ensureLocationReadyForOnline(
      context: context,
    );
    if (!ready) {
      _pendingGoOnline = true;
      showQuikseeSnackBarWidget('location_service_disabled'.tr);
      return;
    }
    _pendingGoOnline = false;
    await profileStatusChange(context, 1);
  }

  /// Keeps GPS on and pushes live location while the driver is online.
  Future<void> syncOnlineGpsAndLocation({BuildContext? context}) async {
    if (_profileModel?.isAccountActive != true || _profileModel?.isOnline != 1) {
      return;
    }
    if (_syncingOnlineGps) return;
    _syncingOnlineGps = true;
    try {
      final ready = await LocationPermissionHelper.ensureLocationReadyForOnline(
        context: context ?? Get.context,
      );
      if (!ready) return;

      if (Get.isRegistered<AssignmentController>()) {
        await Get.find<AssignmentController>().sendIdleLocation();
      }
    } finally {
      _syncingOnlineGps = false;
    }
  }

  Future<void> onAppResumed() async {
    if (_pendingGoOnline && _profileModel?.isOnline != 1) {
      if (await LocationPermissionHelper.isLocationReady()) {
        _pendingGoOnline = false;
        final ctx = Get.context;
        if (ctx != null) {
          await profileStatusChange(ctx, 1);
        }
        return;
      }
    }
    await syncOnlineGpsAndLocation();
  }

  Future <void> profileStatusChange(BuildContext context, int status) async {
    if (status == 1 && _profileModel?.isAccountActive != true) {
      showQuikseeSnackBarWidget('account_not_activated'.tr);
      return;
    }

    double? latitude;
    double? longitude;
    if (status == 1) {
      final ready = await LocationPermissionHelper.ensureLocationReadyForOnline(
        context: context,
      );
      if (!ready) {
        _pendingGoOnline = true;
        showQuikseeSnackBarWidget('location_service_disabled'.tr);
        return;
      }
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        latitude = position.latitude;
        longitude = position.longitude;
      } catch (_) {
        _pendingGoOnline = true;
        showQuikseeSnackBarWidget('location_service_disabled'.tr);
        return;
      }
    }

    ResponseModel response = await profileServiceInterface.profileStatusOnnOff(
      status,
      latitude: latitude,
      longitude: longitude,
    );
    if (response.isSuccess) {
      _pendingGoOnline = false;
      await getProfile(silent: false);
      await _syncDriverOnlineService();
      if (status == 1) {
        await AppPermissionsHelper.requestNotifications();
        await AppForegroundHelper.requestBatteryOptimizationExemption();
        await syncOnlineGpsAndLocation(context: context);
        unawaited(ForceStopWarningHelper.maybeShowAfterGoOnline());
      } else if (Get.isRegistered<AssignmentController>()) {
        Get.find<AssignmentController>().stopServices();
      }
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().syncNewOrderPolling();
      }
    }
    update();
  }

  Future<void> _syncDriverOnlineService() async {
    if (!Get.isRegistered<AuthController>() ||
        !Get.find<AuthController>().isLoggedIn()) {
      return;
    }
    final online = _profileModel?.isAccountActive == true &&
        _profileModel?.isOnline == 1;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.driverOnlineNative, online);
    } catch (_) {}
    await AppForegroundHelper.setDriverOnline(online);
  }

  Future <Response> resetPassword (String? phone, String password ,String confirmPassword) async {
    _isLoading = true;
    update();
    Response _response = await profileServiceInterface.resetPassword(phone, password, confirmPassword);
    _isLoading = false;
    update();
    return _response;
  }

  Future<ResponseModel> updateUserInfo(UserInfoModel updateUserModel, String pass) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await profileServiceInterface.updateProfile(updateUserModel, pass, file, Get.find<AuthController>().getUserToken());
    responseModel.isSuccess ? _userInfoModel = updateUserModel : null;
    if(responseModel.isSuccess){
      _showPassView = false;
    }
    showQuikseeSnackBarWidget(responseModel.message, isError: false);
    _isLoading = false;

    update();
    return responseModel;
  }

  bool _isUpdate = false;
  bool get isUpdate => _isUpdate;

  static String _bankIfscCacheKey(int userId) => 'dm_bank_ifsc_$userId';
  static String _bankBranchAddressCacheKey(int userId) =>
      'dm_bank_branch_address_$userId';

  void _applyBankFields({
    required String bankName,
    required String branch,
    String branchAddress = '',
    required String accountNumber,
    required String ifscCode,
    required String holderName,
  }) {
    if (_profileModel == null) return;
    _profileModel!
      ..bankName = bankName
      ..branch = branch
      ..branchAddress = branchAddress
      ..accountNo = accountNumber
      ..ifscCode = ifscCode.toUpperCase()
      ..holderName = holderName;
  }

  Future<void> _persistBankExtras({
    required String ifscCode,
    required String branchAddress,
  }) async {
    final userId = _profileModel?.id;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bankIfscCacheKey(userId), ifscCode.toUpperCase());
      await prefs.setString(_bankBranchAddressCacheKey(userId), branchAddress);
    } catch (e) {
      debugPrint('persistBankExtras error: $e');
    }
  }

  Future<void> _restoreBankExtrasFromCache() async {
    final userId = _profileModel?.id;
    if (userId == null || _profileModel == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if ((_profileModel!.ifscCode ?? '').trim().isEmpty) {
        _profileModel!.ifscCode = prefs.getString(_bankIfscCacheKey(userId));
      }
      if ((_profileModel!.branchAddress ?? '').trim().isEmpty) {
        _profileModel!.branchAddress =
            prefs.getString(_bankBranchAddressCacheKey(userId));
      }
    } catch (e) {
      debugPrint('restoreBankExtrasFromCache error: $e');
    }
  }

  void _mergeBankInfoFromResponseBody(dynamic body) {
    if (_profileModel == null || body is! Map) return;
    final nested = body['delivery_man'] ?? body['data'] ?? body['bank_info'];
    if (nested is Map) {
      _mergeBankFieldsFromMap(Map<String, dynamic>.from(nested));
    }
  }

  void _mergeBankFieldsFromMap(Map<String, dynamic> json) {
    if (_profileModel == null) return;
    final holderName = _readNonEmptyString(json, ['holder_name', 'holderName']);
    final bankName = _readNonEmptyString(json, ['bank_name', 'bankName']);
    final branch = _readNonEmptyString(json, ['branch']);
    final branchAddress =
        _readNonEmptyString(json, ['branch_address', 'branchAddress']);
    final accountNo =
        _readNonEmptyString(json, ['account_no', 'accountNo']);
    final ifscCode =
        _readNonEmptyString(json, ['ifsc_code', 'ifsc', 'IFSC_code']);

    if (holderName != null) _profileModel!.holderName = holderName;
    if (bankName != null) _profileModel!.bankName = bankName;
    if (branch != null) _profileModel!.branch = branch;
    if (branchAddress != null) _profileModel!.branchAddress = branchAddress;
    if (accountNo != null) _profileModel!.accountNo = accountNo;
    if (ifscCode != null) _profileModel!.ifscCode = ifscCode.toUpperCase();
  }

  String? _readNonEmptyString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  Future<Response> updateBankInfo({
    required String bankName,
    required String branch,
    String branchAddress = '',
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifscCode,
    required String holderName,
  }) async {
    _isUpdate = true;
    update();
    Response response = await profileServiceInterface.updateBankInfo(
      bankName: bankName,
      branch: branch,
      branchAddress: branchAddress,
      accountNumber: accountNumber,
      confirmAccountNumber: confirmAccountNumber,
      ifscCode: ifscCode,
      holderName: holderName,
    );
    if (response.statusCode == 200) {
      _applyBankFields(
        bankName: bankName,
        branch: branch,
        branchAddress: branchAddress,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        holderName: holderName,
      );
      await _persistBankExtras(
        ifscCode: ifscCode,
        branchAddress: branchAddress,
      );
      _mergeBankInfoFromResponseBody(response.body);
      await getProfile(isUpdate: false, skipSideEffects: true);
      await _restoreBankExtrasFromCache();
      update();
      final message = response.body is Map
          ? response.body['message']?.toString()
          : null;
      showQuikseeSnackBarWidget(
        (message != null && message.isNotEmpty)
            ? message
            : 'bank_info_updated_successfully'.tr,
        isError: false,
      );
      Get.back();
    } else {
      ApiChecker.checkApi(response);
    }
    _isUpdate = false;
    update();
    return response;
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
      update();
    }
  }

  void showHidePass({bool isUpdate = true}){
    _showPassView = ! _showPassView;
    if(isUpdate) {
      update();
    }
  }


  void clearPassword() {
    passwordController.text = '';
    confirmPasswordController.text = '';
  }


  bool isPasswordValid(){
    return (_lengthCheck && _lowercaseCheck && _uppercaseCheck && _spatialCheck && _numberCheck);
  }

  void choose() async {
    final pickedFile = await ImageValidationHelper.validateAndPickImage(
      source: ImageSource.gallery,
      context: Get.context!,
    );

    if (pickedFile != null) {
      file = File(pickedFile.path);
    }
    update();
  }

}