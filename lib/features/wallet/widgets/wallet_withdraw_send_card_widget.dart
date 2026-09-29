import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/features/withdraw/screens/withdraw_request_screen.dart';

class WalletSendWithdrawCardWidget extends StatelessWidget {
  const WalletSendWithdrawCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final double widthSize = MediaQuery.of(context).size.width;
    
    return Container(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeDefault),
      color: Get.isDarkMode ? Theme.of(context).canvasColor : Theme.of(context).cardColor, alignment:   Alignment.center,
      child:GetBuilder<ProfileController>(
        builder: (profileController) {
          return Stack(children: [

            Container(height: widthSize / 2,
              width: widthSize,
              padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              margin:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(Dimensions.paddingSizeChat),
                boxShadow: [BoxShadow(
                  color: Colors.grey[Get.isDarkMode ? 900 : 200]!,
                  spreadRadius: 0.5,
                  blurRadius: 0.3,
                )],
              ),
            ),

            Padding(
              padding: EdgeInsets.only(left: Dimensions.paddingSizeSmall),
              child: Container(width: widthSize - 100, height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha:.10),
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(widthSize / 2.5), topLeft: const Radius.circular(10), bottomLeft: const Radius.circular(10)),
                ),
              ),
            ),

            Container(
              height: widthSize / 2.5,
              width: widthSize,
              padding:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              margin:  EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center, children: [

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  SizedBox (width: Dimensions.iconSizeExtraLarge, height: Dimensions.iconSizeExtraLarge,
                      child: Image.asset(Images.cardWhite,)),

                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                    SizedBox(height: Dimensions.paddingSizeDefault),

                    Text('balance_withdraw'.tr, style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white)),
                    SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Text(
                      PriceConverter.convertPrice(profileController.profileModel?.withdrawableBalance ?? 0),
                      style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeHeadingLarge, color:Get.isDarkMode ?
                      Theme.of(context).hintColor : Theme.of(context).cardColor),
                    ),
                  ]),
                  const SizedBox(width: Dimensions.logoHeight),
                ]),

                SizedBox(height: Dimensions.paddingSizeLarge,),
                InkWell(
                  onTap: (){
                    final withdrawable =
                        profileController.profileModel?.withdrawableBalance ?? 0;
                    final cashInHand =
                        profileController.profileModel?.cashInHand ?? 0;
                    if (withdrawable > 0) {
                      Get.to(const BalanceWithdrawScreen());
                    } else if (cashInHand > 0) {
                      showQuikseeSnackBarWidget(
                        'deposit_cash_with_admin_before_withdraw'.tr,
                      );
                    } else {
                      showQuikseeSnackBarWidget(
                        'you_do_not_have_sufficient_balance_to_withdraw'.tr,
                      );
                    }
                  },
                  child: Container(height: 45, width: 220,
                    decoration: BoxDecoration(
                      color:Get.isDarkMode ?
                      Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraLarge),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                      Text('send_withdraw_request'.tr, style:
                        rubikMedium.copyWith(color: Get.isDarkMode ? Theme.of(context).hintColor.withValues(alpha:1) : Theme.of(context).primaryColor,
                        fontSize: Dimensions.fontSizeLarge)),
                    ]),
                  ),
                ),
              ]),
            )
          ]);
        }
      ),
    );
  }
}
