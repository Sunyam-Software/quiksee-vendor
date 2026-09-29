import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_text_field_widget.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/common/controllers/localization_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/profile/screens/html_view_screen.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/splash/domain/models/business_pages_model.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee/features/auth/screens/forget_password_screen.dart';
import 'package:quiksee/features/auth/screens/registration_screen.dart';
import 'package:quiksee/features/auth/widgets/code_picker_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _brandGold = Color(0xFFA36A00);

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  TextEditingController? _emailController;
  TextEditingController? _passwordController;
  GlobalKey<FormState>? _formKeyLogin;
  String? _countryDialCode = '880';

  bool isChecked = false;
  bool _isSubmittingLogin = false;

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController!.text = Get.find<AuthController>().getUserEmail();
    _passwordController!.text = Get.find<AuthController>().getUserPassword();
    final savedCountryCode =
        Get.find<AuthController>().getUserCountryCode() ?? '';
    if (savedCountryCode.isNotEmpty) {
      _countryDialCode = savedCountryCode;
    } else {
      final countryCode =
          Get.find<SplashController>().configModel?.countryCode ?? 'IN';
      _countryDialCode =
          CountryCode.fromCountryCode(countryCode).dialCode ?? '+91';
    }
    Get.find<AuthController>().updateCountryDialCode(
      _countryDialCode ?? '+91',
      isUpdate: false,
    );
  }

  @override
  void dispose() {
    _emailController!.dispose();
    _passwordController!.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(AuthController authController) async {
    if (_isSubmittingLogin || authController.loginInProgress) return;

    final countryCode =
        authController.countryCode.replaceAll('+', '');
    final phone = _emailController!.text.trim();
    final password = _passwordController!.text.trim();

    if (phone.isEmpty) {
      showQuikseeSnackBarWidget('enter_phone_number'.tr);
      return;
    }
    if (password.isEmpty) {
      showQuikseeSnackBarWidget('enter_password'.tr);
      return;
    }
    if (password.length < 6) {
      showQuikseeSnackBarWidget('password_should_be'.tr);
      return;
    }

    _isSubmittingLogin = true;
    if (mounted) setState(() {});

    try {
      final status = await authController.login(countryCode, phone, password);
      if (!mounted) return;

      if (status.isSuccess) {
        if (authController.isActiveRememberMe) {
          authController.saveUserCredentials(
              authController.countryCode, phone, password);
        } else {
          await authController.clearUserEmailAndPassword();
        }
        await Get.find<ProfileController>().getProfile();
        if (!mounted) return;

        final profile = Get.find<ProfileController>().profileModel;
        if (profile?.isAccountActive != true) {
          showQuikseeSnackBarWidget('account_not_activated'.tr);
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(pageIndex: 0),
          ),
        );
      } else if (status.message?.isNotEmpty == true) {
        showQuikseeSnackBarWidget(status.message!);
      }
    } finally {
      _isSubmittingLogin = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( backgroundColor: Theme.of(context).canvasColor,
      body: Padding( padding:  EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Form(key: _formKeyLogin,
          child: GetBuilder<AuthController>( builder: (authController){
            return ListView( physics: const BouncingScrollPhysics(), children: [
              SizedBox(height: Dimensions.topSpace),

              Padding(
                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Image.asset(
                  Images.quikseeLogo,
                  height: 86,
                  fit: BoxFit.contain,
                ),
              ),

              Center(
                  child: Column( children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text('${'welcome_to'.tr} ${AppConstants.companyName}',
                          style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge,
                              color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.5) : _brandGold)),
                      SizedBox(width: 40, child: Image.asset(Images.hand))
                    ])])),
              const SizedBox(height: Dimensions.iconSizeExtraLarge),

              Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                Center(
                  child: Text('login'.tr, style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeOverLarge,
                      color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.5) : _brandGold)),
                ),
                SizedBox(height: Dimensions.paddingSizeMin),

                Center(child: Text('to_reach_your_customer_destination'.tr,style: rubikRegular.copyWith(color: Theme.of(context).hintColor)))],),
              SizedBox(height: Dimensions.paddingSizeOverLarge),

              Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor.withValues(alpha:.5)),
                    borderRadius: BorderRadius.circular(Dimensions.topSpace),
                    color: Get.isDarkMode ? Theme.of(context).primaryColor.withValues(alpha:.02) : Theme.of(context).primaryColor.withValues(alpha:.02),
                  ),
                  child: Stack(children: [

                    Container(width:77, height: 53,
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha:.125),
                            borderRadius: Get.find<LocalizationController>().isLtr? BorderRadius.only(
                                topLeft: Radius.circular(Dimensions.topSpace),
                                bottomLeft: Radius.circular(Dimensions.topSpace)) :
                            BorderRadius.only(topRight: Radius.circular(Dimensions.topSpace),
                                bottomRight: Radius.circular(Dimensions.topSpace),
                            ),
                        ),
                    ),

                    Padding(padding: const EdgeInsets.only(top : 4.0),
                        child: Row(children: [
                          SizedBox(width: Dimensions.loginColor,
                              child: CodePickerWidget(
                                  dialogBackgroundColor:  Theme.of(context).cardColor,
                                  onChanged: (countryCode) {
                                    Get.find<AuthController>().updateCountryDialCode(countryCode.dialCode!);
                                  },
                                  initialSelection: _countryDialCode,
                                  favorite: [_countryDialCode!],
                                  showDropDownButton: true,
                                  padding: EdgeInsets.only(right: Dimensions.paddingSizeDefault),
                                  showFlagMain: true,
                                  flagWidth: 30,
                                  textStyle: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).textTheme.displayLarge!.color))),

                          Expanded(child: Container(
                              transform:Get.find<LocalizationController>().isLtr?
                              Matrix4.translationValues(-25, 0, 0): Matrix4.translationValues(25, 0, 0),
                              child: QuikseeTextFieldWidget(
                                  hintText: '',
                                  noPadding: true,
                                  nextFocus: _passwordFocus,
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  inputType: TextInputType.phone,
                                  inputAction: TextInputAction.next))),
                        ]))])),

              SizedBox(height: Dimensions.paddingSizeLarge),
              Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor.withValues(alpha:.5)),
                    borderRadius: BorderRadius.circular(Dimensions.topSpace),
                    color: Get.isDarkMode ? Theme.of(context).primaryColor.withValues(alpha:.02) : Theme.of(context).primaryColor.withValues(alpha:.02),
                  ),
                  child: Stack(children: [
                    Container(width: 77, height: 53, decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha:.125),
                        borderRadius:  Get.find<LocalizationController>().isLtr?
                        BorderRadius.only(topLeft: Radius.circular(Dimensions.topSpace),
                            bottomLeft: Radius.circular(Dimensions.topSpace)):
                        BorderRadius.only(topRight: Radius.circular(Dimensions.topSpace),
                            bottomRight: Radius.circular(Dimensions.topSpace)))),

                    Padding(padding: const EdgeInsets.only(top : 3.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom : 4.0, left: 4),
                            child: SizedBox(
                              width: 59,
                              height: 20,
                              child: Image.asset(
                                Images.lock,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Expanded(child: Padding(
                            padding: EdgeInsets.only( left: Dimensions.paddingSizeLarge),
                            child: QuikseeTextFieldWidget(
                                hintText: 'password_hint'.tr,
                                isPassword: true,
                                isShowSuffixIcon: true,
                                focusNode: _passwordFocus,
                                noPadding: true,
                                controller: _passwordController,
                                inputAction: TextInputAction.done),
                          )),
                        ]))])),

              Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, 0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                      child: InkWell(
                        onTap: () => authController.toggleRememberMe(),
                        ///for making tap transparent
                        highlightColor: Theme.of(context).primaryColor.withValues(alpha:0),
                        splashColor: Theme.of(context).primaryColor.withValues(alpha:0),
                        child: Padding(
                          padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeLarge),
                          child: Row(children: [
                            SizedBox(height: 20, width: 20,
                                child: Checkbox(value: authController.isActiveRememberMe, activeColor: Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor,
                                    onChanged: (bool? value) {
                                  authController.toggleRememberMe();
                                  },
                                ),
                            ),
                            SizedBox(width: Dimensions.paddingSizeMin),

                            Text('remember_me'.tr, style: rubikRegular)]),
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeLarge,
                          horizontal: Dimensions.paddingSizeSmall,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'forget_password'.tr,
                        style: rubikMedium.copyWith(
                          color: _brandGold,
                          decoration: TextDecoration.underline,
                          decorationColor: _brandGold,
                        ),
                      ),
                    ),
                  ]),
              ),

              Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [authController.loginErrorMessage.isNotEmpty ?
                  CircleAvatar(backgroundColor: Colors.red, radius: Dimensions.paddingSizeExtraSmall) :
                  const SizedBox.shrink(),
                    SizedBox(width: Dimensions.paddingSizeSmall),

                    Expanded(child: Text(authController.loginErrorMessage,
                        style: Theme.of(context).textTheme.displayMedium!.copyWith(
                            fontSize: Dimensions.fontSizeSmall, color: Colors.red)))]),

              !authController.isLoading && !_isSubmittingLogin ? QuikseeButtonWidget(
                btnTxt: 'login'.tr,
                onTap: () => _submitLogin(authController),
              ) :
              Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Get.isDarkMode ? Theme.of(context).hintColor : Theme.of(context).primaryColor))),

              SizedBox(height: Dimensions.paddingSizeLarge),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('new_driver_question'.tr,
                      style: rubikRegular.copyWith(
                          color: Theme.of(context).hintColor)),
                  TextButton(
                    onPressed: () => Get.to(() => const RegistrationScreen()),
                    child: Text('register_now'.tr,
                        style: rubikMedium.copyWith(
                          color: _brandGold,
                          decoration: TextDecoration.underline,
                          decorationColor: _brandGold,
                        )),
                  ),
                ],
              ),

              GetBuilder<SplashController>
                (builder: (splashController) {
                  return GestureDetector(onTap: ()=> Get.to(()=> HtmlViewScreen(
                    page: _getPageBySlug('terms-and-conditions', splashController.defaultBusinessPages)
                  )),
                    child: Padding(padding: EdgeInsets.only(top: Dimensions.menuProfileImageSize),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('terms_and_conditions'.tr,
                          style: rubikRegular.copyWith(color: Colors.transparent,
                            shadows: [
                              Shadow(
                                  color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.5) : _brandGold,
                                  offset: const Offset(0, -4)
                              )],
                            decoration: TextDecoration.underline,
                            decorationColor: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:.5) : _brandGold,))])),
                  );
                }
              ),

            ]);
          },
          ),
        ),
      ),
    );
  }

  BusinessPageModel? _getPageBySlug(String slug, List<BusinessPageModel>? pagesList) {
    BusinessPageModel? pageModel;
    if(pagesList != null && pagesList.isNotEmpty){
      for (var page in pagesList) {
        if(page.slug == slug) {
          pageModel = page;
        }
      }
    }
    return pageModel;
  }

}
