import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/features/wallet/screens/wallet_screen.dart';


class BalanceWithdrawWidget extends StatelessWidget {
  final ProfileController? profileController;
  const BalanceWithdrawWidget({super.key, this.profileController});

  @override
  Widget build(BuildContext context) {
    return  Container(padding:  EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          color: Theme.of(context).primaryColor.withValues(alpha:.05)),
      child: Row(children: [
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,children: [
            Text(PriceConverter.convertPrice(profileController?.profileModel?.withdrawableBalance),
                style: rubikMedium.copyWith(color: Theme.of(context).primaryColorLight, fontSize: Dimensions.fontSizeExtraLarge)),
             SizedBox(height: Dimensions.paddingSizeDefault),
            Text('withdrawable_balance'.tr,style: rubikRegular.copyWith(color: Theme.of(context).primaryColorLight))])),
        InkWell(onTap: () => Get.to(const WalletScreen(fromNotification: false))
            ?.then((_) {
          Get.find<ProfileController>().syncDashboardWalletOnReturn();
        }),
          child: Icon(CupertinoIcons.arrow_right, size:Dimensions.iconSizeLarge,
              color: Theme.of(context).cardColor.withValues(alpha:.65)))
      ],),);
  }
}
