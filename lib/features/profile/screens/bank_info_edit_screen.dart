import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/profile/domain/models/userinfo_model.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_text_field_widget.dart';

class BankInfoEditScreen extends StatefulWidget {
  const BankInfoEditScreen({super.key});

  @override
  State<BankInfoEditScreen> createState() => _BankInfoEditScreenState();
}

class _BankInfoEditScreenState extends State<BankInfoEditScreen> {
  bool _loadingBankInfo = true;

  final FocusNode _accountNameFocus = FocusNode();
  final FocusNode _bankNameFocus = FocusNode();
  final FocusNode _branchNameFocus = FocusNode();
  final FocusNode _branchAddressFocus = FocusNode();
  final FocusNode _ifscFocus = FocusNode();
  final FocusNode _accountNumberFocus = FocusNode();
  final FocusNode _confirmAccountFocus = FocusNode();

  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _branchAddressController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _confirmAccountController = TextEditingController();

  static final RegExp _ifscPattern = RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$');

  @override
  void initState() {
    super.initState();
    _loadBankInfo();
  }

  Future<void> _loadBankInfo() async {
    final controller = Get.find<ProfileController>();
    await controller.getProfile(isUpdate: false, skipSideEffects: true);
    if (!mounted) return;
    _populateFields(controller.profileModel);
    if (mounted) {
      setState(() => _loadingBankInfo = false);
    }
  }

  void _populateFields(UserInfoModel? profile) {
    if (profile == null) return;
    _accountNameController.text = profile.holderName ?? '';
    _bankNameController.text = profile.bankName ?? '';
    _branchNameController.text = profile.branch ?? '';
    _branchAddressController.text = profile.branchAddress ?? '';
    _ifscController.text = profile.ifscCode ?? '';
    _accountNumberController.text = profile.accountNo ?? '';
    _confirmAccountController.text = profile.accountNo ?? '';
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _branchAddressController.dispose();
    _ifscController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _accountNameFocus.dispose();
    _bankNameFocus.dispose();
    _branchNameFocus.dispose();
    _branchAddressFocus.dispose();
    _ifscFocus.dispose();
    _accountNumberFocus.dispose();
    _confirmAccountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'bank_info'.tr, isBack: true),
      body: _loadingBankInfo
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('account_holder_name'.tr, style: rubikRegular),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        QuikseeTextFieldWidget(
                          isShowBorder: true,
                          inputType: TextInputType.name,
                          focusNode: _accountNameFocus,
                          nextFocus: _bankNameFocus,
                          hintText: 'enter_account_name'.tr,
                          controller: _accountNameController,
                          noBg: true,
                          prefixIconUrl: Images.userIcon,
                          inputAction: TextInputAction.next,
                        ),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('bank_name'.tr, style: rubikRegular),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        QuikseeTextFieldWidget(
                          isShowBorder: true,
                          inputType: TextInputType.name,
                          focusNode: _bankNameFocus,
                          nextFocus: _branchNameFocus,
                          hintText: 'enter_bank_name'.tr,
                          controller: _bankNameController,
                          noBg: true,
                          prefixIconUrl: Images.bankIcon,
                          inputAction: TextInputAction.next,
                        ),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('branch_name'.tr, style: rubikRegular),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        QuikseeTextFieldWidget(
                          isShowBorder: true,
                          inputType: TextInputType.name,
                          focusNode: _branchNameFocus,
                          nextFocus: _branchAddressFocus,
                          hintText: 'enter_branch_name'.tr,
                          controller: _branchNameController,
                          noBg: true,
                          prefixIconUrl: Images.branchNameIcon,
                          inputAction: TextInputAction.next,
                        ),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('branch_address'.tr, style: rubikRegular),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        QuikseeTextFieldWidget(
                          isShowBorder: true,
                          inputType: TextInputType.multiline,
                          focusNode: _branchAddressFocus,
                          nextFocus: _ifscFocus,
                          hintText: 'enter_branch_address'.tr,
                          controller: _branchAddressController,
                          maxLines: 3,
                          noBg: true,
                          prefixIconUrl: Images.branchNameIcon,
                          inputAction: TextInputAction.next,
                        ),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('ifsc_code'.tr, style: rubikRegular),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        QuikseeTextFieldWidget(
                          isShowBorder: true,
                          inputType: TextInputType.text,
                          focusNode: _ifscFocus,
                          nextFocus: _accountNumberFocus,
                          hintText: 'enter_ifsc_code'.tr,
                          controller: _ifscController,
                          noBg: true,
                          prefixIconUrl: Images.bankIcon,
                          inputAction: TextInputAction.next,
                        ),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('account_no'.tr, style: rubikRegular),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        QuikseeTextFieldWidget(
                          isShowBorder: true,
                          inputType: TextInputType.text,
                          focusNode: _accountNumberFocus,
                          nextFocus: _confirmAccountFocus,
                          hintText: 'enter_acc_number'.tr,
                          noBg: true,
                          prefixIconUrl: Images.accNumberIcon,
                          controller: _accountNumberController,
                          inputAction: TextInputAction.next,
                        ),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        Text('confirm_account_no'.tr, style: rubikRegular),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        QuikseeTextFieldWidget(
                          isShowBorder: true,
                          inputType: TextInputType.text,
                          focusNode: _confirmAccountFocus,
                          hintText: 'enter_confirm_account_no'.tr,
                          noBg: true,
                          prefixIconUrl: Images.accNumberIcon,
                          controller: _confirmAccountController,
                          inputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Dimensions.paddingSizeDefault),
                ],
              ),
            ),
            GetBuilder<ProfileController>(
              builder: (bankController) {
                return !bankController.isUpdate
                    ? QuikseeButtonWidget(
                        onTap: () {
                          final accountName = _accountNameController.text.trim();
                          final bankName = _bankNameController.text.trim();
                          final branchName = _branchNameController.text.trim();
                          final branchAddress = _branchAddressController.text.trim();
                          final ifscCode = _ifscController.text.trim().toUpperCase();
                          final accountNumber = _accountNumberController.text.trim();
                          final confirmAccountNumber = _confirmAccountController.text.trim();

                          if (accountName.isEmpty) {
                            showQuikseeSnackBarWidget('account_name_is_required'.tr);
                          } else if (bankName.isEmpty) {
                            showQuikseeSnackBarWidget('bank_name_is_required'.tr);
                          } else if (branchName.isEmpty) {
                            showQuikseeSnackBarWidget('branch_name_is_required'.tr);
                          } else if (ifscCode.isEmpty) {
                            showQuikseeSnackBarWidget('ifsc_code_is_required'.tr);
                          } else if (!_ifscPattern.hasMatch(ifscCode)) {
                            showQuikseeSnackBarWidget('invalid_ifsc_code'.tr);
                          } else if (accountNumber.isEmpty) {
                            showQuikseeSnackBarWidget('account_number_is_required'.tr);
                          } else if (confirmAccountNumber.isEmpty) {
                            showQuikseeSnackBarWidget('confirm_account_number_is_required'.tr);
                          } else if (accountNumber != confirmAccountNumber) {
                            showQuikseeSnackBarWidget('account_number_does_not_match'.tr);
                          } else {
                            bankController.updateBankInfo(
                              bankName: bankName,
                              branch: branchName,
                              branchAddress: branchAddress,
                              accountNumber: accountNumber,
                              confirmAccountNumber: confirmAccountNumber,
                              ifscCode: ifscCode,
                              holderName: accountName,
                            );
                          }
                        },
                        btnTxt: 'save'.tr,
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
