import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_body.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';

class BankEditingScreen extends StatefulWidget {
  final ProfileInfoModel? sellerModel;
  const BankEditingScreen({super.key, required this.sellerModel});

  @override
  BankEditingScreenState createState() => BankEditingScreenState();
}

class BankEditingScreenState extends State<BankEditingScreen> {
  TextEditingController? _bankNameController;
  TextEditingController? _branchController;
  TextEditingController? _branchAddressController;
  TextEditingController? _holderNameController;
  TextEditingController? _ifscController;
  TextEditingController? _accountController;
  TextEditingController? _confirmAccountController;

  final FocusNode _bankNameNode = FocusNode();
  final FocusNode _branchNode = FocusNode();
  final FocusNode _branchAddressNode = FocusNode();
  final FocusNode _holderNameNode = FocusNode();
  final FocusNode _ifscNode = FocusNode();
  final FocusNode _accountNode = FocusNode();
  final FocusNode _confirmAccountNode = FocusNode();

  GlobalKey<FormState>? _formKeyLogin;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _accountType = 'saving';

  String _normalizeAccountType(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized == 'current') {
      return 'current';
    }
    return 'saving';
  }

  bool _isUnchanged(ProfileInfoModel current) {
    return current.bankName?.trim() == _bankNameController!.text.trim() &&
        current.branch?.trim() == _branchController!.text.trim() &&
        (current.branchAddress ?? '').trim() == _branchAddressController!.text.trim() &&
        current.holderName?.trim() == _holderNameController!.text.trim() &&
        (current.ifscCode ?? '').trim().toUpperCase() == _ifscController!.text.trim().toUpperCase() &&
        current.accountNo?.trim() == _accountController!.text.trim() &&
        _normalizeAccountType(current.accountType) == _accountType;
  }

  void _showError(String messageKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getTranslated(messageKey, context)!),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _updateUserAccount() async {
    final bankName = _bankNameController!.text.trim();
    final branchName = _branchController!.text.trim();
    final branchAddress = _branchAddressController!.text.trim();
    final holderName = _holderNameController!.text.trim();
    final ifscCode = _ifscController!.text.trim().toUpperCase();
    final account = _accountController!.text.trim();
    final confirmAccount = _confirmAccountController!.text.trim();
    final current = Provider.of<BankInfoController>(context, listen: false).bankInfo!;

    if (_isUnchanged(current)) {
      _showError('change_something');
      return;
    }
    if (bankName.isEmpty) {
      _showError('enter_bank_name');
      return;
    }
    if (branchName.isEmpty) {
      _showError('enter_branch_name');
      return;
    }
    if (holderName.isEmpty) {
      _showError('enter_holder_name');
      return;
    }
    if (ifscCode.isEmpty) {
      _showError('enter_ifsc_code');
      return;
    }
    if (account.isEmpty) {
      _showError('enter_account');
      return;
    }
    if (confirmAccount.isEmpty) {
      _showError('enter_confirm_account_no');
      return;
    }
    if (account != confirmAccount) {
      _showError('account_number_does_not_match');
      return;
    }
    if (_accountType.isEmpty) {
      _showError('select_account_type');
      return;
    }

    final updateUserInfoModel = current;
    updateUserInfoModel.bankName = bankName;
    updateUserInfoModel.branch = branchName;
    updateUserInfoModel.branchAddress = branchAddress;
    updateUserInfoModel.holderName = holderName;
    updateUserInfoModel.ifscCode = ifscCode;
    updateUserInfoModel.accountNo = account;
    updateUserInfoModel.accountType = _accountType;

    final userInfo = Provider.of<ProfileController>(context, listen: false).userInfoModel!;
    final sellerBody = ProfileBody(
      sMethod: '_put',
      fName: userInfo.fName,
      lName: userInfo.lName,
      image: userInfo.image,
      bankName: bankName,
      branch: branchName,
      branchAddress: branchAddress,
      holderName: holderName,
      accountNo: account,
      ifscCode: ifscCode,
      accountType: _accountType,
    );

    updateUserInfoModel.phone = userInfo.phone;
    updateUserInfoModel.fName = userInfo.fName;
    updateUserInfoModel.lName = userInfo.lName;

    final response = await Provider.of<BankInfoController>(context, listen: false).updateBankInfo(
      context,
      updateUserInfoModel,
      sellerBody,
      Provider.of<AuthController>(context, listen: false).getUserToken(),
    );
    if (!mounted || response == null) return;
    if (response.isSuccess) {
      Navigator.pop(context);
      showQuikseeSnackBarWidget(
        getTranslated('bank_info_updated_successfully', context),
        context,
        isToaster: true,
        isError: false,
      );
      return;
    }
    final errorText = (response.message ?? '').trim();
    showQuikseeSnackBarWidget(
      errorText.isNotEmpty
          ? errorText
          : (getTranslated('something_went_wrong', context) ?? 'Update failed'),
      context,
      sanckBarType: SnackBarType.warning,
    );
  }

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();
    _bankNameController = TextEditingController();
    _branchController = TextEditingController();
    _branchAddressController = TextEditingController();
    _holderNameController = TextEditingController();
    _ifscController = TextEditingController();
    _accountController = TextEditingController();
    _confirmAccountController = TextEditingController();

    _bankNameController!.text = widget.sellerModel!.bankName ?? '';
    _branchController!.text = widget.sellerModel!.branch ?? '';
    _branchAddressController!.text = widget.sellerModel!.branchAddress ?? '';
    _holderNameController!.text = widget.sellerModel!.holderName ?? '';
    _ifscController!.text = widget.sellerModel!.ifscCode ?? '';
    _accountController!.text = widget.sellerModel!.accountNo ?? '';
    _confirmAccountController!.text = widget.sellerModel!.accountNo ?? '';
    _accountType = _normalizeAccountType(widget.sellerModel!.accountType);
  }

  @override
  void dispose() {
    _bankNameController!.dispose();
    _branchController!.dispose();
    _branchAddressController!.dispose();
    _holderNameController!.dispose();
    _ifscController!.dispose();
    _accountController!.dispose();
    _confirmAccountController!.dispose();
    super.dispose();
  }

  Widget _fieldLabel(String key) {
    return Text(
      getTranslated(key, context)!,
      style: titilliumRegular.copyWith(
        fontSize: Dimensions.fontSizeDefault,
        color: Theme.of(context).hintColor,
      ),
    );
  }

  Widget _accountTypeOption(String value, String labelKey) {
    return InkWell(
      onTap: () => setState(() => _accountType = value),
      child: Row(
        children: [
          SizedBox(
            height: Dimensions.paddingSizeDefault,
            width: Dimensions.paddingSizeDefault,
            child: Radio<String>(
              value: value,
              groupValue: _accountType,
              onChanged: (selected) => setState(() => _accountType = selected ?? 'saving'),
            ),
          ),
          Text(
            getTranslated(labelKey, context)!,
            style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: QuikseeBrandColors.forestGreen,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: QuikseeAppBarWidget(
          title: getTranslated('bank_info', context),
          isBackButtonExist: true,
          useQuikseeBrandedHeader: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Consumer<AuthController>(
            builder: (context, authProvider, child) => Form(
              key: _formKeyLogin,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _fieldLabel('bank_name'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    border: true,
                    hintText: getTranslated('bank_name_hint', context),
                    focusNode: _bankNameNode,
                    nextNode: _branchNode,
                    controller: _bankNameController,
                    textInputType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _fieldLabel('branch_name'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    border: true,
                    hintText: getTranslated('branch_name_hint', context),
                    focusNode: _branchNode,
                    nextNode: _branchAddressNode,
                    controller: _branchController,
                    textInputType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _fieldLabel('branch_address'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    border: true,
                    hintText: getTranslated('branch_address_hint', context),
                    focusNode: _branchAddressNode,
                    nextNode: _holderNameNode,
                    controller: _branchAddressController,
                    maxLine: 3,
                    isDescription: true,
                    textInputType: TextInputType.multiline,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _fieldLabel('holder_name'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    border: true,
                    hintText: getTranslated('holder_name_hint', context),
                    controller: _holderNameController,
                    focusNode: _holderNameNode,
                    nextNode: _ifscNode,
                    textInputAction: TextInputAction.next,
                    textInputType: TextInputType.text,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _fieldLabel('ifsc_code'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    border: true,
                    hintText: getTranslated('ifsc_code_hint', context),
                    controller: _ifscController,
                    focusNode: _ifscNode,
                    nextNode: _accountNode,
                    textInputAction: TextInputAction.next,
                    textInputType: TextInputType.text,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _fieldLabel('account_no'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    border: true,
                    hintText: getTranslated('account_no_hint', context),
                    controller: _accountController,
                    focusNode: _accountNode,
                    nextNode: _confirmAccountNode,
                    textInputAction: TextInputAction.next,
                    textInputType: TextInputType.number,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _fieldLabel('confirm_account_no'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  QuikseeTextFieldWidget(
                    border: true,
                    hintText: getTranslated('confirm_account_no_hint', context),
                    controller: _confirmAccountController,
                    focusNode: _confirmAccountNode,
                    textInputAction: TextInputAction.done,
                    textInputType: TextInputType.number,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  _fieldLabel('account_type'),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  _accountTypeOption('saving', 'account_type_saving'),
                  _accountTypeOption('current', 'account_type_current'),
                  const SizedBox(height: Dimensions.paddingSizeButton),

                  Container(
                    margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                    child: !Provider.of<BankInfoController>(context).isLoading
                        ? QuikseeButtonWidget(
                            onTap: _updateUserAccount,
                            btnTxt: getTranslated('save', context),
                          )
                        : Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
