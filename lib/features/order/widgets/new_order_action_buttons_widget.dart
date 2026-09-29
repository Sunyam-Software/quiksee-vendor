import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/utill/dimensions.dart';

class NewOrderActionButtonsWidget extends StatelessWidget {
  static const Color _brandGreen = Color(0xFF0F6B2D);

  final int orderId;
  final VoidCallback? onSuccess;

  const NewOrderActionButtonsWidget({
    super.key,
    required this.orderId,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      final bool loading = orderController.isActionLoading;
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              ),
              onPressed: loading
                  ? null
                  : () => orderController.acceptOrder(orderId),
              child: loading && orderController.actionType == 'accept'
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('accept_order'.tr),
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              ),
              onPressed: loading
                  ? null
                  : () => orderController.cancelAssignedOrder(
                        orderId,
                        reason: 'Driver declined',
                      ),
              child: loading && orderController.actionType == 'cancel'
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red.shade300,
                      ),
                    )
                  : Text('cancel_order'.tr),
            ),
          ),
        ],
      );
    });
  }
}
