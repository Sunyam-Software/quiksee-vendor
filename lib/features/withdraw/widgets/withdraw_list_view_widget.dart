import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/wallet/widgets/withdraw_card_shimmer_widget.dart';
import 'package:quiksee/features/withdraw/controllers/withdraw_controller.dart';
import 'package:quiksee/features/withdraw/widgets/withdraw_card_widget.dart';

class WithdrawListViewWidget extends StatelessWidget {
  const WithdrawListViewWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<WithdrawController>(
        builder: (withdrawController) {
          return !withdrawController.isLoading? withdrawController.withdrawList.isNotEmpty?
          ListView.builder(
              itemCount: withdrawController.withdrawList.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (withdrawContext, withdrawIndex){
                return WithdrawCardWidget(withdraws: withdrawController.withdrawList[withdrawIndex], index: withdrawIndex, length: withdrawController.withdrawList.length,);
              }):const NoDataScreenWidget() : const WithdrawCardShimmerWidget();
        }
    );
  }
}
