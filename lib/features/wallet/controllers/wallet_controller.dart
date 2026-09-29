import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/withdraw_model.dart';
import 'package:quiksee_vendor_app/features/shop/controllers/shop_controller.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/payment_information_model.dart';
import 'package:quiksee_vendor_app/features/transaction/controllers/transaction_controller.dart';
import 'package:quiksee_vendor_app/features/wallet/domain/services/wallet_service_interface.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';

class WalletController with ChangeNotifier{

  final WalletServiceInterface walletServiceInterface;
  WalletController({required this.walletServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  WithdrawModel? withdrawModel;
  List<WithdrawModel> methodList = [];
  MethodModel? methodSelected;
  List<MethodModel?> methodsIds = [];
  List<MethodModel?> myMethodsIds = [];

  List<MethodModel?> get visibleOtherMethodIds {
    if (myMethodsIds.isEmpty) return List<MethodModel?>.from(methodsIds);
    final savedWithdrawIds = <int>{
      for (final m in myMethodsIds)
        if (m?.id != null) m!.id!,
    };
    return methodsIds
        .where((m) => m?.id == null || !savedWithdrawIds.contains(m!.id))
        .toList();
  }

  List<String> inputValueList = [];
  bool validityCheck = false;

  PaymentInformationModel ? _paymentInformationModel;
  PaymentInformationModel ? get paymentInformationModel => _paymentInformationModel;

  void clearSessionData({bool notify = true}) {
    withdrawModel = null;
    methodList = [];
    methodSelected = null;
    methodsIds = [];
    myMethodsIds = [];
    inputValueList = [];
    validityCheck = false;
    _paymentInformationModel = null;
    _isLoading = false;
    keyList = [];
    for (final controller in inputFieldControllerList) {
      controller.dispose();
    }
    inputFieldControllerList = [];
    if (notify) {
      notifyListeners();
    }
  }

  void setTitle(int index, String title) {
    inputFieldControllerList[index].text = title;
  }

  List<TextEditingController> inputFieldControllerList = [];
  void getInputFieldList(){
    for (final controller in inputFieldControllerList) {
      controller.dispose();
    }
    inputFieldControllerList = [];
    if(methodList.isNotEmpty){
      for(int i= 0; i< (methodSelected?.methodFields?.length ?? 0 ) ; i++){
        inputFieldControllerList.add(TextEditingController());
      }
    }
  }

  List <String?> keyList = [];

  void setMethodTypeIndex(MethodModel? index, {bool notify = true}) {
    methodSelected = index;

    keyList = [];
    if(methodList.isNotEmpty){
      for(int i= 0; i< (methodSelected?.methodFields?.length ?? 0) ; i++){
        keyList.add(methodSelected?.methodFields![i].inputName);
      }
      getInputFieldList();
      _prefillOtherMethodFromSavedPaymentInfo();
    }
    if(notify){
      notifyListeners();
    }
  }

  bool _isCurrentSelectionValid() {
    final selected = methodSelected;
    if (selected == null) return false;
    final options = selected.type == 'my_methods'
        ? myMethodsIds
        : visibleOtherMethodIds;
    return options.any((m) => m == selected);
  }

  ProfileInfoModel? _readSellerProfile() {
    try {
      return Provider.of<ProfileController>(Get.context!, listen: false)
          .userInfoModel;
    } catch (_) {
      return null;
    }
  }

  bool isBankWithdrawMethod(MethodModel? method) {
    if (method == null) return false;
    final name = (method.inputName ?? '').toLowerCase();
    if (name.contains('bank')) return true;

    final keys = <String>{
      ...(method.methodInfo ?? {}).keys.map((k) => k.toString().toLowerCase()),
      ...(method.methodFields ?? [])
          .map((f) => (f.inputName ?? '').toLowerCase())
          .where((k) => k.isNotEmpty),
    };
    const bankKeys = {
      'bank_account',
      'bank_name',
      'holder_name',
      'ifsc_code',
      'ifsc',
      'account_no',
      'account_number',
      'branch_name',
      'branch',
      'branch_address',
      'account_type',
    };
    return keys.any(bankKeys.contains);
  }

  Map<String, dynamic> resolvedMethodInfo(MethodModel? method) {
    if (method == null) return {};
    final raw = Map<String, dynamic>.from(method.methodInfo ?? {});
    if (!isBankWithdrawMethod(method)) {
      return raw;
    }
    return mergeProfileBankIntoMethodInfo(raw, _readSellerProfile());
  }

  bool get usesProfileBankDetailsCard =>
      isBankWithdrawMethod(methodSelected) &&
      selectedMethodInfoEntries.isNotEmpty;

  bool get shouldHideOtherMethodInputs =>
      methodSelected?.type == 'other' && usesProfileBankDetailsCard;

  Map<String, dynamic> mergeProfileBankIntoMethodInfo(
    Map<String, dynamic>? methodInfo,
    ProfileInfoModel? profile,
  ) {
    final info = Map<String, dynamic>.from(methodInfo ?? {});
    if (profile == null || !profile.isBankInfoComplete) return info;

    void put(String key, String? value) {
      if (value == null || value.trim().isEmpty) return;
      info[key] = value.trim();
    }

    put('holder_name', profile.holderName);
    put('bank_name', profile.bankName);
    put('branch_name', profile.branch);
    put('branch_address', profile.branchAddress);
    put('ifsc_code', profile.ifscCode);
    put('account_no', profile.accountNo);
    put('account_type', profile.displayAccountType());
    return info;
  }

  static const _methodInfoAliasKeys = <String, List<String>>{
    'holder_name': ['holder_name', 'account_holder_name'],
    'bank_name': ['bank_name'],
    'branch_name': ['branch_name', 'branch'],
    'branch_address': ['branch_address'],
    'ifsc_code': ['ifsc_code', 'ifsc'],
    'account_no': ['account_no', 'bank_account', 'account_number'],
    'account_type': ['account_type'],
  };

  static const _aliasOnlyKeys = <String>{
    'branch',
    'bank_account',
    'account_number',
    'ifsc',
    'account_holder_name',
  };

  String? _valueFromMethodInfoAliases(
    String canonicalKey,
    Map<String, dynamic> info,
  ) {
    for (final key in _methodInfoAliasKeys[canonicalKey] ?? [canonicalKey]) {
      final v = info[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  List<MapEntry<String, dynamic>> orderedMethodInfoEntries(
    Map<String, dynamic>? info,
  ) {
    const displayOrder = <String>[
      'holder_name',
      'bank_name',
      'branch_name',
      'branch_address',
      'ifsc_code',
      'account_no',
      'account_type',
    ];
    if (info == null || info.isEmpty) return [];

    final out = <MapEntry<String, dynamic>>[];
    for (final key in displayOrder) {
      final value = _valueFromMethodInfoAliases(key, info);
      if (value == null) continue;
      out.add(MapEntry(key, value));
    }

    for (final e in info.entries) {
      final key = e.key.toString();
      if (displayOrder.contains(key) || _aliasOnlyKeys.contains(key)) continue;
      final v = e.value?.toString().trim() ?? '';
      if (v.isEmpty) continue;
      out.add(MapEntry(key, v));
    }
    return out;
  }

  void _appendResolvedMethodFieldsForSubmit(
    Map<String, dynamic> info,
    List<String?> keyList,
    List<String> inputValueList,
  ) {
    final fields = methodSelected?.methodFields;
    if (fields != null && fields.isNotEmpty) {
      for (final field in fields) {
        final key = field.inputName;
        if (key == null || key.isEmpty) continue;
        final value =
            _aliasValueForFieldKey(key, info) ?? info[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          keyList.add(key);
          inputValueList.add(value);
        }
      }
      return;
    }

    for (final entry in orderedMethodInfoEntries(info)) {
      keyList.add(entry.key);
      inputValueList.add(entry.value.toString());
    }
  }

  List<MapEntry<String, dynamic>> get selectedMethodInfoEntries =>
      orderedMethodInfoEntries(resolvedMethodInfo(methodSelected));

  void _prefillOtherMethodFromSavedPaymentInfo() {
    if (methodSelected?.type != 'other') return;

    Map<String, dynamic>? info;
    if (myMethodsIds.isNotEmpty) {
      MethodModel? saved;
      for (final m in myMethodsIds) {
        if (m?.isDefault ?? false) {
          saved = m;
          break;
        }
      }
      saved ??= myMethodsIds.first;
      info = Map<String, dynamic>.from(saved?.methodInfo ?? {});
    } else if (isBankWithdrawMethod(methodSelected)) {
      final profile = _readSellerProfile();
      if (profile?.isBankInfoComplete ?? false) {
        info = mergeProfileBankIntoMethodInfo({}, profile);
      }
    }

    info = resolvedMethodInfo(
      MethodModel(
        id: methodSelected?.id,
        inputName: methodSelected?.inputName,
        type: methodSelected?.type,
        methodFields: methodSelected?.methodFields,
        methodInfo: info,
      ),
    );
    if (info.isEmpty) return;

    for (int i = 0; i < keyList.length; i++) {
      final key = keyList[i];
      if (key == null || key.isEmpty) continue;
      if (i >= inputFieldControllerList.length) break;
      if (inputFieldControllerList[i].text.trim().isNotEmpty) continue;

      final direct = info[key];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        inputFieldControllerList[i].text = direct.toString();
        continue;
      }

      final alias = _aliasValueForFieldKey(key, info);
      if (alias != null && alias.trim().isNotEmpty) {
        inputFieldControllerList[i].text = alias;
      }
    }
  }

  String? _aliasValueForFieldKey(String key, Map<String, dynamic> info) {
    const aliases = <String, List<String>>{
      'bank_account': ['account_no', 'account_number', 'bank_account'],
      'account_number': ['bank_account', 'account_no', 'account_number'],
      'account_no': ['bank_account', 'account_number', 'account_no'],
      'bank_name': ['bank_name'],
      'holder_name': ['holder_name', 'account_holder_name'],
      'ifsc_code': ['ifsc_code', 'ifsc'],
      'branch_name': ['branch_name', 'branch'],
    };
    for (final candidate in aliases[key] ?? [key]) {
      final v = info[candidate];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return null;
  }

  Future<void> getWithdrawMethods(BuildContext context) async{
    methodList = [];
    methodsIds = [];
    ApiResponse response = await walletServiceInterface.getDynamicWithDrawMethod();
      response.response!.data.forEach((method) => methodList.add(WithdrawModel.fromJson(method)));
      getInputFieldList();
      for(int index = 0; index < methodList.length; index++) {
        methodsIds.add(
          MethodModel(
            id: methodList[index].id,
            inputName: methodList[index].methodName,
            type: 'other',
            methodFields: methodList[index].methodFields
          )
        );
      }
    notifyListeners();
  }

  void checkValidity(){
    for(int i= 0; i< inputValueList.length; i++){
      if(inputValueList[i].isEmpty){
        inputValueList.clear();
        validityCheck = true;
        notifyListeners();
      }
    }

  }

  Future<ApiResponse> updateBalance(String balance, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    if(methodSelected?.type == 'other') {
      inputValueList = [];
      if (shouldHideOtherMethodInputs) {
        keyList = [];
        final info = resolvedMethodInfo(methodSelected);
        _appendResolvedMethodFieldsForSubmit(info, keyList, inputValueList);
      } else {
        for(TextEditingController textEditingController in inputFieldControllerList) {
          inputValueList.add(textEditingController.text.trim());
        }
      }
    } else if(methodSelected?.type == 'my_methods') {
      inputValueList = [];
      keyList = [];

      final info = resolvedMethodInfo(methodSelected);
      _appendResolvedMethodFieldsForSubmit(info, keyList, inputValueList);
    }

    ApiResponse apiResponse = await walletServiceInterface.withdrawBalance(keyList, inputValueList, methodSelected?.id, balance);
    if(Provider.of<ShopController>(Get.context!, listen: false).shopModel?.setupGuideApp != null && Provider.of<ShopController>(Get.context!, listen: false).shopModel?.setupGuideApp?['withdraw_setup'] != 1) {
      Provider.of<ShopController>(Get.context!, listen: false).updateTutorialFlow('withdraw_setup');
      Provider.of<ShopController>(Get.context!, listen: false).updateSetupGuideApp('withdraw_setup', 1);
    }

    if(apiResponse.response?.statusCode == 200) {
      inputValueList.clear();
      for (final controller in inputFieldControllerList) {
        controller.dispose();
      }
      inputFieldControllerList = [];
      Provider.of<TransactionController>(Get.context!, listen: false).getTransactionList(Get.context!,'all','','');
      Provider.of<ProfileController>(Get.context!, listen: false).getSellerInfo();
      _isLoading = false;
      notifyListeners();
      showQuikseeSnackBarWidget(getTranslated('withdraw_request_sent_successfully', Get.context!), Get.context!, isToaster: true, isError: false);
      Navigator.pop(Get.context!);
    } else if (apiResponse.error != null && apiResponse.error.isNotEmpty) {
      showToast(message: apiResponse.error.toString());
      _isLoading = false;
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<ApiResponse> updateWithdrawRequest(String balance, int requestId, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    if (methodSelected?.type == 'other') {
      inputValueList = [];
      if (shouldHideOtherMethodInputs) {
        keyList = [];
        final info = resolvedMethodInfo(methodSelected);
        _appendResolvedMethodFieldsForSubmit(info, keyList, inputValueList);
      } else {
        for (TextEditingController textEditingController in inputFieldControllerList) {
          inputValueList.add(textEditingController.text.trim());
        }
      }
    } else if (methodSelected?.type == 'my_methods') {
      inputValueList = [];
      keyList = [];

      final info = resolvedMethodInfo(methodSelected);
      _appendResolvedMethodFieldsForSubmit(info, keyList, inputValueList);
    }

    ApiResponse apiResponse = await walletServiceInterface.updateWithdrawRequest(keyList, inputValueList, methodSelected?.id, balance, requestId);

    if (apiResponse.response?.statusCode == 200) {
      inputValueList.clear();
      for (final controller in inputFieldControllerList) {
        controller.dispose();
      }
      inputFieldControllerList = [];
      Provider.of<TransactionController>(Get.context!, listen: false).getTransactionList(Get.context!, 'all', '', '');
      Provider.of<ProfileController>(Get.context!, listen: false).getSellerInfo();
      showQuikseeSnackBarWidget(getTranslated('withdraw_request_updated_successfully', Get.context!), Get.context!, isToaster: true, isError: false);
      Navigator.pop(Get.context!);
    } else if (apiResponse.error != null && apiResponse.error.isNotEmpty) {
      showToast(message: apiResponse.error.toString());
      _isLoading = false;
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    _isLoading = false;
    notifyListeners();
    return apiResponse;
  }

  Future<void> getPaymentInfoList() async {
    ApiResponse apiResponse = await walletServiceInterface.getPaymentInfoList();
    myMethodsIds = [];
    if(apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _paymentInformationModel = PaymentInformationModel.fromJson(apiResponse.response?.data);

      for(int index = 0; index < (_paymentInformationModel?.data?.length ?? 0) ; index++) {
        myMethodsIds.add(
          MethodModel(
            id: _paymentInformationModel?.data?[index].withdrawMethodId,
            inputName: _paymentInformationModel?.data?[index].methodName,
            type: 'my_methods',
            methodFields: _paymentInformationModel?.data?[index].withdrawMethod?.methodFields,
            methodInfo: _paymentInformationModel?.data?[index].methodInfo,
            isDefault: _paymentInformationModel?.data?[index].isDefault ?? false,
          )
        );
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }

  void setDefaultPaymentMethod({bool force = false}) {
    if (myMethodsIds.isNotEmpty) {
      MethodModel? pick;
      for (final paymentInfo in myMethodsIds) {
        if (paymentInfo?.isDefault ?? false) {
          pick = paymentInfo;
          break;
        }
      }
      pick ??= myMethodsIds.first;

      if (force ||
          !_isCurrentSelectionValid() ||
          methodSelected?.type != 'my_methods') {
        setMethodTypeIndex(pick, notify: false);
        return;
      }
      if (!(methodSelected?.isDefault ?? false) &&
          (pick?.isDefault ?? false)) {
        setMethodTypeIndex(pick, notify: false);
      }
      return;
    }

    if (methodsIds.isEmpty) {
      if (force) {
        methodSelected = null;
      }
      return;
    }

    if (force ||
        !_isCurrentSelectionValid() ||
        methodSelected == null) {
      setMethodTypeIndex(methodsIds.first, notify: false);
    }
  }

  Future<ApiResponse> closeWithdrawRequest(int id, String balance) async {
    _isLoading = true;
    notifyListeners();

    ApiResponse apiResponse = await walletServiceInterface.closeWithdrawRequest(id, balance);
    if(apiResponse.response?.statusCode == 200) {
      Provider.of<ProfileController>(Get.context!, listen: false).updateWalletAmount(balance);
      Provider.of<ShopController>(Get.context!, listen: false).getShopInfo();
    }
    _isLoading = false;
    notifyListeners();
    return apiResponse;
  }

  void showToast({Color backGroundColor = Colors.red, required String message}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backGroundColor,
      textColor: Colors.white,
      fontSize: Dimensions.fontSizeDefault
    );
  }

}