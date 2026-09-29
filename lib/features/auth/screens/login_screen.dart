import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/textfeild/quiksee_text_feild_widget.dart';
import 'package:quiksee_vendor_app/features/more/screens/html_view_screen.dart';
import 'package:quiksee_vendor_app/features/splash/domain/models/business_pages_model.dart';
import 'package:quiksee_vendor_app/helper/email_checker.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/features/auth/screens/registration_screen.dart';
import 'package:quiksee_vendor_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee_vendor_app/features/auth/screens/forget_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  TextEditingController? _emailController;
  TextEditingController? _passwordController;
  GlobalKey<FormState>? _formKeyLogin;

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();

    if(_emailController == null) {
      _emailController = TextEditingController();
      _passwordController = TextEditingController();
    }

    if(!Provider.of<AuthController>(context, listen: false).isUnAuthorize) {
      _emailController!.text = (Provider.of<AuthController>(context, listen: false).getUserEmail());
      _passwordController!.text = (Provider.of<AuthController>(context, listen: false).getUserPassword());
      Provider.of<AuthController>(Get.context!,listen: false).setUnAuthorize(true, update: false);
    }
  }

  @override
  void dispose() {
    _emailController!.dispose();
    _passwordController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Provider.of<AuthController>(context, listen: false).isActiveRememberMe;

    final fieldBorder = QuikseeBrandColors.seeTextGreen.withValues(alpha: 0.35);

    return Consumer<AuthController>(
      builder: (context, authProvider, child) => Form(
        key: _formKeyLogin,
        child: Column(
          children: [
            QuikseeTextFieldWidget(
              border: true,
              required: true,
              formProduct: true,
              fillColor: Colors.white,
              borderColor: fieldBorder,
              prefixIconImage: Images.emailIcon,
              labelText: getTranslated('enter_email_address', context),
              hintText: getTranslated('enter_email_address', context),
              focusNode: _emailFocus,
              nextNode: _passwordFocus,
              textInputType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            QuikseeTextFieldWidget(
              border: true,
              required: true,
              formProduct: true,
              fillColor: Colors.white,
              borderColor: fieldBorder,
              isPassword: true,
              prefixIconImage: Images.lock,
              labelText: getTranslated('password', context),
              hintText: getTranslated('password_hint', context),
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              controller: _passwordController,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () => authProvider.toggleRememberMe(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: QuikseeBrandColors.seeTextGreen),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: authProvider.isActiveRememberMe
                            ? Icon(Icons.done, color: QuikseeBrandColors.seeTextGreen, size: 14)
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(
                        getTranslated('remember_me', context) ?? 'Remember me',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: QuikseeBrandColors.seeTextGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: Text(
                    getTranslated('forget_password', context) ?? 'Forgot password',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: QuikseeBrandColors.seeTextGreen,
                      decoration: TextDecoration.underline,
                      decorationColor: QuikseeBrandColors.seeTextGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            !authProvider.isLoading
                ? QuikseeButtonWidget(
                    borderRadius: 8,
                    buttonHeight: 48,
                    backgroundColor: QuikseeBrandColors.seeTextGreen,
                    fontColor: QuikseeBrandColors.gold,
                    btnTxt: getTranslated('login', context),
                    onTap: () async {
                      String email = _emailController!.text.trim();
                      String password = _passwordController!.text.trim();
                      if (email.isEmpty) {
                        showQuikseeSnackBarWidget(getTranslated('enter_email_address', context), context,  sanckBarType: SnackBarType.warning);
                      }else if (EmailChecker.isNotValid(email)) {
                        showQuikseeSnackBarWidget(getTranslated('enter_valid_email', context), context,  sanckBarType: SnackBarType.warning);
                      }else if (password.isEmpty) {
                        showQuikseeSnackBarWidget(getTranslated('enter_password', context), context,  sanckBarType: SnackBarType.warning);
                      }else if (password.length < 6) {
                        showQuikseeSnackBarWidget(getTranslated('password_should_be', context), context,  sanckBarType: SnackBarType.warning);
                      }else {authProvider.login(context, emailAddress: email, password: password).then((status) async {
                          final loggedIn = authProvider.getUserToken().isNotEmpty;
                          if (status.response?.statusCode == 200 && loggedIn) {
                            if (authProvider.isActiveRememberMe) {
                              authProvider.saveUserNumberAndPassword(email, password);
                            } else {
                              authProvider.clearUserEmailAndPassword();
                            }
                            Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(builder: (_) => const DashboardScreen()), (route) => false);
                          }
                        });
                      }
                  },
                )
                : Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(QuikseeBrandColors.seeTextGreen),
                    ),
                  ),
            Consumer<SplashController>(
              builder: (context, splashController, _) {
                final showRegistration =
                    splashController.configModel?.sellerRegistration == '1';

                return Column(
                  children: [
                    if (showRegistration)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getTranslated('dont_have_an_account', context) ?? "Don't have an account",
                                style: robotoRegular.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeSmall),
                              Text(
                                getTranslated('registration_here', context) ?? 'Register here',
                                style: robotoTitleRegular.copyWith(
                                  color: QuikseeBrandColors.seeTextGreen,
                                  decoration: TextDecoration.underline,
                                  decorationColor: QuikseeBrandColors.seeTextGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeBottomSpace),
                      child: InkWell(
                        onTap: () {
                          final page = getPageBySlug(
                            'terms-and-conditions',
                            splashController.defaultBusinessPages,
                          );
                          if (page == null) {
                            showQuikseeSnackBarWidget(
                              getTranslated('terms_and_condition', context) ??
                                  'Terms & conditions',
                              context,
                              sanckBarType: SnackBarType.warning,
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HtmlViewScreen(page: page),
                            ),
                          );
                        },
                        child: Text(
                          getTranslated('terms_and_condition', context) ?? 'Terms & conditions',
                          style: robotoMedium.copyWith(
                            color: QuikseeBrandColors.seeTextGreen,
                            decoration: TextDecoration.underline,
                            decorationColor: QuikseeBrandColors.seeTextGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  BusinessPageModel? getPageBySlug(String slug, List<BusinessPageModel>? pagesList) {
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
