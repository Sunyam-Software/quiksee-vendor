import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/earning_statement/widgets/earning_statement_card_widget.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';

import 'earning_statement_shimmer_widget.dart';

class EarningStatementListViewWidget extends StatelessWidget {
  final WalletController? walletController;
  const EarningStatementListViewWidget({super.key, this.walletController});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      !walletController!.isLoading? walletController!.deliveryWiseEarned.isNotEmpty?
      ListView.builder(
          itemCount: walletController!.deliveryWiseEarned.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index)=> EarningStatementCardWidget(ordersWiseEarned: walletController!.deliveryWiseEarned[index])) :
      Padding(
        padding: EdgeInsets.only(top: Dimensions.splashLogoWidth),
        child: NoDataScreenWidget(noDataImage: Images.noTransactionAvailableIcon, noDataMessage: 'no_transaction_available'.tr),
      ) : const EarningStatementShimmerWidget()
    ]);
  }
}
