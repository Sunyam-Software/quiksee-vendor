import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/features/wallet/widgets/transaction_card_widget.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

import 'transaction_card_shimmer_widget.dart';

class TransactionListViewWidget extends StatelessWidget {
  const TransactionListViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      builder: (walletController) {
        final summary = walletController.distanceEarningSummary;
        return !walletController.isLoading? walletController.deliveryWiseEarned.isNotEmpty?
        Column(
          children: [
            if (summary != null && (summary.distanceBasedOrders ?? 0) > 0)
              Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeMin,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeSmall,
                ),
                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('distance_earning_summary'.tr,
                        style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                    SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Text(
                      '${summary.distanceBasedOrders} ${'orders'.tr} • ${(summary.totalDistanceKm ?? 0).toStringAsFixed(1)} ${'km'.tr}',
                      style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                    Text(
                      '${'total_earning'.tr}: ${PriceConverter.convertPrice(summary.totalDeliveryManEarning)}',
                      style: rubikMedium,
                    ),
                  ],
                ),
              ),
            ListView.builder(
              itemCount: walletController.deliveryWiseEarned.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (transactionContext, transactionIndex)=>
                  TransactionCardWidget(
                    orders: walletController.deliveryWiseEarned[transactionIndex],
                    index: transactionIndex,
                    length: walletController.deliveryWiseEarned.length,
                  ),
            ),
          ],
        ):
        const NoDataScreenWidget() : const TransactionCardShimmerWidget();
      }
    );
  }
}
