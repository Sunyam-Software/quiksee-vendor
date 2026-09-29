import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_details/screens/order_delivered_screen.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';

class VerifyDeliverySheetWidget extends StatefulWidget {
  final OrderModel? orderModel;
  final double? totalPrice;
  final bool? editOrderPayment;
  const VerifyDeliverySheetWidget({
    super.key,
    this.orderModel,
    this.totalPrice,
    this.editOrderPayment,
  });
  @override
  State<VerifyDeliverySheetWidget> createState() =>
      _VerifyDeliverySheetWidgetState();
}

class _VerifyDeliverySheetWidgetState extends State<VerifyDeliverySheetWidget> {
  String otp = '';
  bool invalidOtp = false;
  bool _submitting = false;
  bool _completingDelivery = false;

  bool get _busy => _submitting || _completingDelivery;

  Future<void> _submitOtp() async {
    if (_busy) return;
    if (otp.length != 6) {
      showQuikseeSnackBarWidget('input_valid_otp'.tr);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final orderController = Get.find<OrderDetailsController>();
    setState(() {
      _submitting = true;
      invalidOtp = false;
    });

    try {
      final response = await orderController.otpVerificationForOrderVerification(
        orderId: widget.orderModel!.id,
        otp: otp,
        notifyUi: false,
      );
      if (!mounted) return;

      if (response?.statusCode == 200) {
        await _afterOtpVerified(orderController);
      } else if (context.mounted) {
        setState(() {
          invalidOtp = true;
          _submitting = false;
        });
      }
    } catch (_) {
      if (context.mounted) {
        setState(() {
          invalidOtp = true;
          _submitting = false;
        });
      }
    }
  }

  Future<void> _afterOtpVerified(OrderDetailsController orderController) async {
    final paymentConfirmed = orderController.isDeliveryPaymentConfirmed(
      widget.orderModel,
      editOrderPaymentDue: widget.editOrderPayment == true,
    );

    if (!paymentConfirmed || widget.editOrderPayment == true) {
      orderController.toggleProceedToNext();
      if (context.mounted) setState(() => _submitting = false);
      return;
    }

    if (context.mounted) {
      setState(() {
        _submitting = false;
        _completingDelivery = true;
      });
    }

    final delivered = await orderController.updateOrderStatus(
      orderId: widget.orderModel!.id,
      context: context,
      status: 'delivered',
      releaseSliderEarly: true,
    );
    if (!context.mounted) return;

    if (!delivered) {
      if (context.mounted) {
        setState(() => _completingDelivery = false);
      }
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final navigator = Navigator.of(context);
    final order = widget.orderModel;
    navigator.pop();
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderDeliveredScreen(
          orderID: order!.id.toString(),
          orderModel: order,
        ),
      ),
    );
  }

  Future<void> _confirmCollectedAndDeliver(
    OrderDetailsController orderController,
  ) async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);

    try {
      final paymentResponse = await orderController.updatePaymentStatus(
        orderId: widget.orderModel!.id,
        status: 'paid',
      );
      if (!mounted) return;
      if (paymentResponse?.statusCode != 200) {
        setState(() => _submitting = false);
        return;
      }

      setState(() {
        _submitting = false;
        _completingDelivery = true;
      });

      final delivered = await orderController.updateOrderStatus(
        orderId: widget.orderModel!.id,
        context: context,
        status: 'delivered',
        releaseSliderEarly: true,
      );
      if (!context.mounted) return;
      if (!delivered) {
        if (context.mounted) {
          setState(() => _completingDelivery = false);
        }
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();
      final navigator = Navigator.of(context);
      final order = widget.orderModel;
      navigator.pop();
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDeliveredScreen(
            orderID: order!.id.toString(),
            orderModel: order,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _completingDelivery = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: GetBuilder<OrderDetailsController>(builder: (orderController) {
        final showSpinner = _busy;

        return Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                ),
              ),
              orderController.otpVerified
                  ? Padding(
                      padding: EdgeInsets.only(
                        bottom: Dimensions.paddingSizeOverLarge,
                        top: 50,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'collect_money_from_customer'.tr,
                            style: rubikBold,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: Dimensions.paddingSizeLarge),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${'order_amount'.tr}:  ',
                                style: rubikRegular.copyWith(),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                PriceConverter.convertPrice(widget.totalPrice),
                                style: rubikBold.copyWith(
                                  color: Get.isDarkMode
                                      ? Theme.of(context).primaryColorLight
                                      : Theme.of(context).primaryColor,
                                  fontSize: Dimensions.fontSizeLarge,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          SizedBox(height: Dimensions.paddingSizeLarge),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(height: Dimensions.paddingSizeLarge),
                        Text(
                          'otp_verification'.tr,
                          style: rubikBold,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Dimensions.paddingSizeLarge),
                        Text(
                          'enter_otp_number'.tr,
                          style: rubikRegular.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: Dimensions.paddingSizeLarge),
                        SizedBox(
                          width: 260,
                          child: PinCodeTextField(
                            length: 6,
                            appContext: context,
                            autoFocus: true,
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.underline,
                              fieldHeight: 30,
                              fieldWidth: 30,
                              borderWidth: 2,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusSmall),
                              selectedColor: invalidOtp
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).primaryColor,
                              selectedFillColor: Colors.white,
                              inactiveFillColor: Theme.of(context).cardColor,
                              inactiveColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.2),
                              activeColor: invalidOtp
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.7),
                              errorBorderColor:
                                  Theme.of(context).colorScheme.error,
                              activeFillColor: Theme.of(context).cardColor,
                            ),
                            animationDuration:
                                const Duration(milliseconds: 150),
                            backgroundColor: Colors.transparent,
                            enableActiveFill: true,
                            onChanged: (String text) {
                              setState(() {
                                otp = text;
                                if (otp.length < 6) {
                                  invalidOtp = false;
                                }
                              });
                            },
                            onCompleted: (text) {
                              otp = text;
                              unawaited(_submitOtp());
                            },
                            beforeTextPaste: (text) => true,
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        if (_completingDelivery)
                          Text(
                            'Completing delivery…',
                            style: rubikRegular.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else if (invalidOtp)
                          Text(
                            'wrong_otp'.tr,
                            style: rubikRegular.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else if (_submitting)
                          Text(
                            'Verifying OTP…',
                            style: rubikRegular.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            'collect_otp_from_customer'.tr,
                            style: rubikRegular,
                            textAlign: TextAlign.center,
                          ),
                        SizedBox(height: Dimensions.paddingSizeLarge),
                      ],
                    ),
              if (showSpinner)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )
              else
                QuikseeButtonWidget(
                  btnTxt: orderController.otpVerified ? 'ok'.tr : 'submit'.tr,
                  onTap: () {
                    if (orderController.otpVerified) {
                      unawaited(_confirmCollectedAndDeliver(orderController));
                    } else {
                      unawaited(_submitOtp());
                    }
                  },
                ),
              if (!orderController.otpVerified)
                Padding(
                  padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'did_not_get_any_OTP'.tr,
                        style: rubikRegular.copyWith(
                          color: Theme.of(context).hintColor,
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      InkWell(
                        onTap: _busy
                            ? null
                            : () => orderController
                                .resendOtpForOrderVerification(
                                  orderId: widget.orderModel!.id,
                                ),
                        child: Text(
                          'resend_it'.tr,
                          style: rubikMedium.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: Dimensions.paddingSizeSmall),
            ],
          ),
        );
      }),
    );
  }
}
