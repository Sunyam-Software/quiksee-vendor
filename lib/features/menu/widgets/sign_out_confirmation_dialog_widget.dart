import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/product/controllers/product_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/theme/controllers/theme_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/features/auth/screens/auth_screen.dart';

import 'delete_account_warning_dialog.dart';

class SignOutConfirmationDialogWidget extends StatefulWidget {
  final bool isDelete;
  const SignOutConfirmationDialogWidget({super.key, this.isDelete = false});

  @override
  State<SignOutConfirmationDialogWidget> createState() =>
      _SignOutConfirmationDialogWidgetState();
}

class _SignOutConfirmationDialogWidgetState
    extends State<SignOutConfirmationDialogWidget> {
  bool _isSigningOut = false;

  Future<void> _completeLogout() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    final navContext = Get.context;
    if (navContext == null) return;

    Provider.of<ProductController>(context, listen: false).clearSessionData(notify: false);
    await Provider.of<AuthController>(navContext, listen: false).clearSharedData();

    if (!mounted) return;
    Navigator.of(context).pop();

    if (!navContext.mounted) return;
    Navigator.of(navContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Provider.of<ThemeController>(context).darkTheme ? Theme.of(context).cardColor : Theme.of(context).highlightColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Column(mainAxisSize: MainAxisSize.min, children: [

                const SizedBox(height: 30),
                widget.isDelete
                    ? SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.asset(Images.accountDeleteIcon),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: QuikseeBrandColors.forestGreen,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Image.asset(
                          Images.logout,
                          color: QuikseeBrandColors.gold,
                          fit: BoxFit.contain,
                        ),
                      ),

                Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.isDelete ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge, 13,
                    widget.isDelete ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge, 0
                  ),
                  child: Text(widget.isDelete? getTranslated('want_to_delete_account', context)!:
                  getTranslated('want_to_sign_out', context)!,
                    style: titilliumSemiBold.copyWith(fontSize: widget.isDelete ? Dimensions.fontSizeDefault : Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge?.color),
                    textAlign: TextAlign.center),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, 13, Dimensions.paddingSizeLarge,0),
                  child: Text(widget.isDelete ? getTranslated('if_once_you_delete_your', context)!: getTranslated('need_to_sign_in_again', context)!,
                    style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color),
                    textAlign: TextAlign.center
                  ),
                ),

                SizedBox(height: 80,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,24,Dimensions.paddingSizeDefault,Dimensions.paddingSizeDefault),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(children: [
                        Expanded(
                          child: QuikseeButtonWidget(borderRadius: 15,
                            btnTxt: getTranslated('yes', context),
                            backgroundColor: widget.isDelete
                                ? Theme.of(context).colorScheme.error
                                : QuikseeBrandColors.forestGreen,
                            fontColor: Colors.white,
                            isColor: true,
                            isLoading: _isSigningOut,
                            onTap: _isSigningOut
                                ? null
                                : () async {
                              if(widget.isDelete){
                                setState(() => _isSigningOut = true);
                                Provider.of<ProfileController>(context, listen: false).deleteCustomerAccount(context).then((condition) async {
                                  if(condition.response?.statusCode == null){
                                    if (mounted) setState(() => _isSigningOut = false);
                                    Navigator.of(Get.context!).pop();
                                    showDialog(context: Get.context!, builder: (_) => const DeleteAccountWarningDialogWidget());
                                  }else if(condition.response!.statusCode == 200){
                                    final navContext = Get.context!;
                                    Navigator.pop(navContext);
                                    await Provider.of<AuthController>(navContext,listen: false).clearSharedData();
                                    if (!navContext.mounted) return;
                                    Navigator.of(navContext).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
                                  } else if (mounted) {
                                    setState(() => _isSigningOut = false);
                                  }
                                });
                              }
                              else{
                                await _completeLogout();
                              }

                            },
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: QuikseeButtonWidget(borderRadius: 15,
                            btnTxt: getTranslated('no', context),
                            isColor: true,
                            fontColor: widget.isDelete
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : QuikseeBrandColors.forestGreen,
                            backgroundColor: widget.isDelete
                                ? Theme.of(context).hintColor.withValues(alpha: .25)
                                : QuikseeBrandColors.gold,
                            onTap: _isSigningOut ? null : () => Navigator.pop(context),
                          ),
                        ),

                      ]),
                    ),
                  ),
                ),
              ]),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _isSigningOut ? null : () => Navigator.pop(context),
                  child: Container(margin: const EdgeInsets.all(Dimensions.paddingSeven),
                    decoration: BoxDecoration(color: Theme.of(context).hintColor.withValues(alpha: 0.30), shape: BoxShape.circle),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: SizedBox(width: Dimensions.iconSizeExtraSmall,
                      child: Image.asset(Images.cross, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
