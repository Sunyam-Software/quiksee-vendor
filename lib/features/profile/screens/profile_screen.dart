import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/auth/widgets/code_picker_widget.dart';
import 'package:quiksee_vendor_app/features/auth/widgets/pass_view.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_body.dart';
import 'package:quiksee_vendor_app/features/profile/domain/models/profile_info.dart';
import 'package:quiksee_vendor_app/helper/country_code_helper.dart';
import 'package:quiksee_vendor_app/helper/image_size_checker.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/bank_info/controllers/bank_info_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final FocusNode _fNameFocus = FocusNode();
  final FocusNode _lNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _countryDialCode = '+91';

  File? file;
  final picker = ImagePicker();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  bool _fieldsPopulated = false;

  void _choose() async {
    final pickedFile = await ImageValidationHelper.validateAndPickImage(
      source: ImageSource.gallery,
      context: context
    );

    if(pickedFile != null) {
      setState(() {
        file = File(pickedFile.path);
      });
    }
  }

  void _populateFieldsFromProfile(ProfileController profile) {
    if (_fieldsPopulated) return;
    final user = profile.userInfoModel;
    if (user == null) return;

    _firstNameController.text = user.fName ?? '';
    _lastNameController.text = user.lName ?? '';
    final String phone = user.phone ?? '';
    if (phone.isNotEmpty) {
      final String? countryCode =
          CountryCodeHelper.getCountryCode(phone) ?? profile.countryDialCode ?? '+91';
      _countryDialCode = countryCode;
      profile.setCountryDialCode(_countryDialCode);
      _phoneController.text = CountryCodeHelper.extractPhoneNumber(countryCode!, phone);
    } else {
      _countryDialCode = profile.countryDialCode ?? '+91';
      profile.setCountryDialCode(_countryDialCode);
    }
    _fieldsPopulated = true;
  }

  Future<void> _updateUserAccount() async {
    final profileController = Provider.of<ProfileController>(context, listen: false);
    final userInfo = profileController.userInfoModel;
    if (userInfo == null) {
      showQuikseeSnackBarWidget(
        getTranslated('something_went_wrong', context) ?? 'Profile not loaded',
        context,
        sanckBarType: SnackBarType.error,
      );
      return;
    }
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String phoneNumber = _phoneController.text.trim();
    final String fullPhone = '${_countryDialCode ?? profileController.countryDialCode ?? ''}$phoneNumber';
    String password0 = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if ((userInfo.fName ?? '') == firstName
        && (userInfo.lName ?? '') == lastName
        && (userInfo.phone ?? '') == fullPhone
        && file == null
        && password0.isEmpty
        && confirmPassword.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('change_something_to_update', context), context, sanckBarType: SnackBarType.warning);

    }else if (firstName.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('enter_first_name', context), context, sanckBarType: SnackBarType.warning);

    }else if (lastName.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('enter_first_name', context), context, sanckBarType: SnackBarType.warning);

    }else if (phoneNumber.isEmpty) {
      showQuikseeSnackBarWidget(getTranslated('enter_phone_number', context), context, sanckBarType: SnackBarType.warning);
    }

    else if((password0.isNotEmpty && password0.length < 6)
        || (confirmPassword.isNotEmpty && confirmPassword.length < 6)) {
      showQuikseeSnackBarWidget(getTranslated('password_be_at_least', context), context, sanckBarType: SnackBarType.warning);
    }

    else if(password0 != confirmPassword) {
      showQuikseeSnackBarWidget(getTranslated('password_did_not_match', context), context, sanckBarType: SnackBarType.warning);

    }
    else if(password0.isNotEmpty && !Provider.of<AuthController>(context, listen: false).isPasswordValid()) {
      showQuikseeSnackBarWidget(getTranslated('enter_valid_password', context), context, sanckBarType: SnackBarType.warning);
    }

    else {
      final ProfileInfoModel updateUserInfoModel = userInfo;
      updateUserInfoModel.fName = firstName;
      updateUserInfoModel.lName = lastName;
      updateUserInfoModel.phone = fullPhone;
      String password = _passwordController.text;

      final ProfileInfoModel? bank = Provider.of<BankInfoController>(context, listen: false).bankInfo;
      ProfileBody sellerBody = ProfileBody(
          sMethod: '_put', fName: firstName, lName: lastName,
        image: updateUserInfoModel.image,
          bankName: bank?.bankName ?? userInfo.bankName ?? '',
          branch: bank?.branch ?? userInfo.branch ?? '',
          holderName: bank?.holderName ?? userInfo.holderName ?? '',
          accountNo: bank?.accountNo ?? userInfo.accountNo ?? '',
      );

      final bool success = await profileController.updateUserInfo(
        updateUserInfoModel, sellerBody, file, Provider.of<AuthController>(context, listen: false).getUserToken(), password);
      if (success && mounted) {
        setState(() {
          file = null;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Provider.of<AuthController>(context, listen: false).validPassCheck('', isUpdate: false);
    final profileController = Provider.of<ProfileController>(context, listen: false);
    if (profileController.userInfoModel == null) {
      profileController.getSellerInfo().then((_) {
        if (mounted) setState(() => _populateFieldsFromProfile(profileController));
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: QuikseeAppBarWidget(isBackButtonExist: true, title: getTranslated('edit_profile', context)),
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          return Consumer<ProfileController>(
            builder: (context, profile, child) {
              final user = profile.userInfoModel;
              if (user == null) {
                return const Center(child: CircularProgressIndicator());
              }
              _populateFieldsFromProfile(profile);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: Dimensions.paddingSizeExtraLarge),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).highlightColor,
                        border: Border.all(color: Colors.white, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: file == null ?
                            QuikseeImageWidget(width: 100,height: 100,fit: BoxFit.cover,
                                image: user.imageFullUrl?.path ?? '')
                                : Image.file(file!, width: 100, height: 100, fit: BoxFit.fill),),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _choose,
                              child: Container(width: 30,height: 30,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
                                  border: Border.all(color: Theme.of(context).cardColor)
                                ),

                                child: IconButton(
                                  onPressed: _choose,
                                  padding: const EdgeInsets.all(0),
                                  icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: Dimensions.iconSizeDefault,),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.only(
                          top: Dimensions.paddingSizeDefault,
                          left: Dimensions.paddingSizeDefault,
                          right: Dimensions.paddingSizeDefault),
                      child: Column(
                        children: [

                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          QuikseeTextFieldWidget(
                            formProduct: true,
                            labelText: getTranslated('first_name', context),
                            border: true,
                            textInputType: TextInputType.name,
                            focusNode: _fNameFocus,
                            nextNode: _lNameFocus,
                            hintText: user.fName ?? '',
                            controller: _firstNameController,
                          ),

                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          QuikseeTextFieldWidget(
                            border: true,
                            formProduct: true,
                            labelText: getTranslated('last_name', context),
                            textInputType: TextInputType.name,
                            focusNode: _lNameFocus,
                            nextNode: _phoneFocus,
                            hintText: user.lName ?? '',
                            controller: _lastNameController,
                          ),

                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          QuikseeTextFieldWidget(
                            idDate: true,
                            hintText: user.email ?? "",
                            border: true,

                          ),

                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          Row(
                            children: [
                              CodePickerWidget(
                                onChanged: (CountryCode countryCode) {
                                  _countryDialCode = countryCode.dialCode;
                                  profile.setCountryDialCode(_countryDialCode);
                                },
                                initialSelection: profile.countryDialCode,
                                favorite: [profile.countryDialCode!],
                                showDropDownButton: true,
                                padding: EdgeInsets.zero,
                                showFlagMain: true,
                                textStyle: TextStyle(color: Theme.of(context).textTheme.displayLarge!.color),
                              ),

                              Expanded(
                                child: QuikseeTextFieldWidget(
                                  border: true,
                                  textInputType: TextInputType.phone,
                                  focusNode: _phoneFocus,
                                  nextNode: _passwordFocus,
                                  hintText: user.phone ?? "",
                                  controller: _phoneController,
                                  isPhoneNumber: true,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          QuikseeTextFieldWidget(
                            border: true,
                            hintText: getTranslated('password', context),
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            isPassword: true,
                            nextNode: _confirmPasswordFocus,
                            textInputAction: TextInputAction.next,
                            onChanged: (value){
                              if(value.isNotEmpty){
                                if(!authController.showPassView) {
                                  authController.showHidePass();
                                }
                                authController.validPassCheck(value);
                              }else{
                                if(authController.showPassView){
                                  authController.showHidePass();
                                }
                              }
                            }
                          ),

                          authController.showPassView ? const PassView() : const SizedBox(),

                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          QuikseeTextFieldWidget(
                            border: true,
                            hintText: getTranslated('confirm_password', context),
                            isPassword: true,
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                        ],
                      ),
                    ),

                  ],
                ),
              );
            },
          );
        }
      ),
      bottomNavigationBar: Consumer<ProfileController>(
        builder: (context, profile, child) {
          return Container(height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha:.125),
                    spreadRadius: 2, blurRadius: 5, offset: Offset.fromDirection(1,2))],
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeMedium),
            width: MediaQuery.of(context).size.width,
            child: !profile.isLoading
                ? QuikseeButtonWidget(
              borderRadius: 10,
                backgroundColor: Theme.of(context).primaryColor, onTap: _updateUserAccount,
                btnTxt: getTranslated('update_profile', context))
                : Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor))),
          );
        }
      ),
    );
  }
}
