import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/features/order_transaction/controllers/order_transaction_controller.dart';
import 'package:quiksee_vendor_app/features/order_transaction/widgets/order_transaction_card_widget.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';

class WalletOrderTransactionListWidget extends StatelessWidget {
  final int limit;
  const WalletOrderTransactionListWidget({super.key, this.limit = 10});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderTransactionController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.report == null) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          );
        }

        final items = controller.report?.transactions ?? [];
        if (items.isEmpty) {
          return const NoDataScreen();
        }

        final count = items.length.clamp(0, limit);
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          itemBuilder: (context, index) => OrderTransactionCardWidget(row: items[index]),
        );
      },
    );
  }
}
