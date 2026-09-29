import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/wallet/widgets/deposited_card_widget.dart';
import 'package:quiksee/features/wallet/widgets/withdraw_card_shimmer_widget.dart';


class DepositedListViewWidget extends StatelessWidget {
  const DepositedListViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
        builder: (walletController) {
          return !walletController.isLoading? walletController.depositedList.isNotEmpty?
          ListView.builder(
              itemCount: walletController.depositedList.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) => DepositedCardWidget(deposit: walletController.depositedList[index], index: index, length: walletController.depositedList.length,)):
          const NoDataScreenWidget() : const WithdrawCardShimmerWidget();
        }
    );
  }
}
