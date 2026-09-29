import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/calculation_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_image_widget.dart';
import 'package:quiksee/features/wallet/screens/wallet_screen.dart';

class EarnStatementWidget extends StatelessWidget {
  const EarnStatementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[

        GetBuilder<ProfileController>(
          builder: (profileController) {
            return Container(
              decoration: BoxDecoration(color: Get.find<ThemeController>().darkTheme ? Theme.of(context).hintColor.withValues(alpha:.15) : Theme.of(context).primaryColor.withValues(alpha:.91),
                  borderRadius:  BorderRadius.only(bottomLeft:Radius.circular(Dimensions.paddingSizeOverLarge),
                      bottomRight:Radius.circular(Dimensions.paddingSizeOverLarge))),

              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha:.8),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(Dimensions.paddingSizeOverLarge), bottomRight: Radius.circular(Dimensions.paddingSizeOverLarge),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge, left: Dimensions.fontSizeHeading, right: Dimensions.rememberMeSizeDefault, bottom: Dimensions.paddingSizeSmall),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,children: [
                      Container(decoration: BoxDecoration(
                          color: Theme.of(context).primaryColorLight.withValues(alpha:.25),
                          border: Border.all(color: Theme.of(context).primaryColorLight),
                          borderRadius: BorderRadius.circular(50)),

                          child: ClipRRect(borderRadius: BorderRadius.circular(50),
                              child: QuikseeImageWidget(image: '${Get.find<ProfileController>().profileImage}',
                                  height: 40, width: 40, fit: BoxFit.cover))),


                      Expanded(child: Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, Dimensions.paddingSizeChat,0,0),
                          child: Get.find<ProfileController>().profileModel !=null?
                          Text('${'hi'.tr}, ${Get.find<ProfileController>().profileModel!.fName??''} ${Get.find<ProfileController>().profileModel!.lName}',
                            overflow: TextOverflow.ellipsis, maxLines: 1,
                            style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white,fontSize: Dimensions.fontSizeHeading),):const SizedBox()),
                      ),

                      Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.start, children: [
                        if(Get.find<ProfileController>().profileModel!= null)
                          Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall,0,0,0),
                              child: Text(' ${PriceConverter.convertPrice(Get.find<ProfileController>().profileModel!.currentBalance)}',
                                style: rubikMedium.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white, fontSize: Dimensions.fontSizeOverLarge), overflow: TextOverflow.ellipsis,)),
                        Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeSmall, 0, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault),
                            child: Text('current_balance'.tr,
                              style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white, fontSize: Dimensions.fontSizeSmall),)),
                      ]),
                    ]),
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeDefault),


                Padding(
                  padding: EdgeInsets.only(left: Dimensions.rememberMeSizeDefault),
                  child: SizedBox(height : 100,
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(
                          flex:1,
                          child: CalculationWidget(title: 'cash_in_hand'.tr,
                              amount: profileController.profileModel?.cashInHand ?? 0, isTotalAmount: true),
                        ),

                        Expanded(
                          flex:1,
                          child: CalculationWidget(title: 'pending_withdraw'.tr,
                              amount: profileController.profileModel?.pendingWithdraw ?? 0),
                        ),

                        Expanded(
                          flex:1,
                          child: CalculationWidget(title: 'withdrawn'.tr,
                              amount: profileController.profileModel?.totalWithdraw ?? 0),
                        ),
                      ],),
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeDefault),

                Padding(
                  padding: EdgeInsets.only(left: Dimensions.fontSizeHeading, right: Dimensions.fontSizeHeading),
                  child: Row(
                    children: [
                      Column(mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${Get.find<SplashController>().myCurrency?.symbol ?? ''} ${NumberFormat.compact().format(double.tryParse(PriceConverter.convertPriceWithoutSymbol(context, profileController.profileModel?.withdrawableBalance??0)) ?? 0)}',style:
                          rubikBold.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white,
                              fontSize: Dimensions.fontSizeHeading)),
                          // SizedBox(height: Dimensions.paddingSizeSmall),

                          Text('withdrawable_balance'.tr, maxLines : 2,textAlign: TextAlign.center,
                            style: rubikRegular.copyWith(color: Get.isDarkMode ? Theme.of(context).primaryColorLight :Colors.white,
                                fontSize: Dimensions.fontSizeSmall),),

                        ],),

                      const Expanded(child: SizedBox()),

                    InkWell(
                      onTap: () => Get.to(const WalletScreen(fromNotification: false))
                          ?.then((_) {
                        Get.find<ProfileController>().syncDashboardWalletOnReturn();
                      }),
                      child: SizedBox(
                          height: 40,
                          width: 40,
                          child: Image.asset(Images.arrowRightSquare)
                      ),
                    ),
                    ],
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeOverLarge),

              ],
              ),

            );
          }
        ),
      ]
    );
  }
}

