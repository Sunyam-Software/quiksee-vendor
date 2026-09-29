import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/features/order/domain/models/order_model.dart';
import 'package:quiksee_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class FoodPickupOtpVerifyWidget extends StatefulWidget {
  final Order? orderModel;
  const FoodPickupOtpVerifyWidget({super.key, this.orderModel});

  @override
  State<FoodPickupOtpVerifyWidget> createState() =>
      _FoodPickupOtpVerifyWidgetState();
}

class _FoodPickupOtpVerifyWidgetState extends State<FoodPickupOtpVerifyWidget> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  bool _isVerified(Order? order) {
    if (order == null) return false;
    return order.pickupVerificationStatus == 1 || order.pickupOtpVerified == 1;
  }

  bool _needsVerify(Order? order) {
    if (order == null || order.id == null) return false;
    if (_isVerified(order)) return false;
    final type = (order.orderType ?? '').toLowerCase();
    if (type == 'pos') return false;
    final status = (order.orderStatus ?? '').toLowerCase();
    if (const {
      'delivered',
      'out_for_delivery',
      'canceled',
      'cancelled',
      'returned',
      'failed',
    }.contains(status)) {
      return false;
    }
    if (order.pickupFromAdminHub == 1 || order.scheduledAdminHold == 1) {
      return false;
    }
    if (order.pickupOtpRequired != 1 && order.foodPickupOtpEnabled != 1) {
      return false;
    }
    return status == 'reached_restaurant' || status == 'processing';
  }

  String _label(BuildContext context, String key, String fallback) {
    final t = getTranslated(key, context);
    if (t == null || t.isEmpty || t == key) return fallback;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderDetailsController>(
      builder: (context, orderDetails, _) {

        final order = orderDetails.orderDetails?.isNotEmpty == true
            ? (orderDetails.orderDetails!.first.order ?? widget.orderModel)
            : widget.orderModel;
        if (order == null) return const SizedBox.shrink();

        if (_isVerified(order) || !_needsVerify(order)) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            0,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _label(context, 'food_pickup_otp', 'Food Pickup OTP'),
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _label(
                  context,
                  'enter_pickup_otp_from_rider',
                  'Ask the rider for Pickup OTP and enter it to confirm food handover.',
                ),
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: _label(context, 'enter_otp', 'Enter OTP'),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeSmall),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              QuikseeButtonWidget(
                btnTxt: _label(context, 'verify_pickup_otp', 'Verify Pickup OTP'),
                isLoading: orderDetails.isLoading,
                onTap: () async {
                  final otp = _otpController.text.trim();
                  if (otp.length < 4 || order.id == null) return;
                  final ok = await orderDetails.verifyPickupOtp(
                    orderId: order.id!,
                    otp: otp,
                    context: context,
                  );
                  if (ok && mounted) {
                    _otpController.clear();
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
