import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee_vendor_app/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee_vendor_app/features/order_details/domain/models/order_setup_model.dart';
import 'package:quiksee_vendor_app/features/order_details/screens/order_details_screen.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class VendorNewOrderSheet extends StatefulWidget {
  final int orderId;
  final String? currentStatus;
  final String? paymentStatus;
  final String? etaLabel;
  final String? etaBreakdown;
  final String? customerEtaLabel;
  final int? prepMinutes;
  final double? orderAmount;

  const VendorNewOrderSheet({
    super.key,
    required this.orderId,
    this.currentStatus,
    this.paymentStatus,
    this.etaLabel,
    this.etaBreakdown,
    this.customerEtaLabel,
    this.prepMinutes,
    this.orderAmount,
  });

  @override
  State<VendorNewOrderSheet> createState() => _VendorNewOrderSheetState();
}

class _VendorNewOrderSheetState extends State<VendorNewOrderSheet> {
  bool _accepting = false;
  bool _cancelling = false;

  bool get _isBusy => _accepting || _cancelling;

  String get _paymentStatus {
    final payment = (widget.paymentStatus ?? '').trim().toLowerCase();
    return payment == 'paid' || payment == 'unpaid' ? payment : 'unpaid';
  }

  Future<void> _acceptOrder() async {
    if (_isBusy) return;
    setState(() => _accepting = true);

    final controller =
        Provider.of<OrderDetailsController>(context, listen: false);
    final setup = OrderSetupModel(
      orderId: widget.orderId,
      orderStatus: 'confirmed',
      paymentStatus: _paymentStatus,
    );

    if (!mounted) return;
    Navigator.pop(context);

    unawaited(controller.setUpOrder(
      orderSetupModel: setup,
      showLoading: false,
      showSuccessSnackBar: false,
      showErrorSnackBar: false,
    ).then((ok) async {
      final BuildContext? ctx = Get.context;
      if (ctx == null || !ctx.mounted) return;
      if (ok) {
        showQuikseeSnackBarWidget(
          getTranslated('order_accepted', ctx) ??
              'Order accepted — start preparing',
          ctx,
          isError: false,
          isToaster: true,
          sanckBarType: SnackBarType.success,
        );
        return;
      }
      showQuikseeSnackBarWidget(
        getTranslated('something_went_wrong', ctx) ??
            'Accept failed — open the order and try again',
        ctx,
        isError: true,
        isToaster: true,
        sanckBarType: SnackBarType.error,
      );
    }));
  }

  Future<void> _cancelOrder() async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          getTranslated('are_you_sure', dialogContext) ?? 'Are you sure?',
        ),
        content: Text(
          getTranslated('are_you_sure_to_cancel', dialogContext) ??
              'Are you sure you want to cancel this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(getTranslated('no', dialogContext) ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              getTranslated('yes', dialogContext) ?? 'Yes',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);

    final controller =
        Provider.of<OrderDetailsController>(context, listen: false);
    final ok = await controller.setUpOrder(
      orderSetupModel: OrderSetupModel(
        orderId: widget.orderId,
        orderStatus: 'canceled',
        paymentStatus: _paymentStatus,
      ),
      context: context,
    );

    if (!mounted) return;
    setState(() => _cancelling = false);

    if (ok) {
      Navigator.pop(context);
      showQuikseeSnackBarWidget(
        getTranslated('cancelled', context) ?? 'Order cancelled',
        context,
        isError: false,
        isToaster: true,
        sanckBarType: SnackBarType.success,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.currentStatus ?? 'pending').toLowerCase();

    final canAccept = status == 'pending' || status.isEmpty;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
                Icons.notifications_active_rounded,
                size: 56,
                color: QuikseeBrandColors.gold),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              getTranslated('new_order', context) ?? 'New Order',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              '#${widget.orderId}',
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeExtraLarge,
                color: QuikseeBrandColors.seeTextGreen,
              ),
            ),
            if (widget.etaLabel != null && widget.etaLabel!.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                widget.etaLabel!,
                textAlign: TextAlign.center,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
            if (widget.etaBreakdown != null &&
                widget.etaBreakdown!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.etaBreakdown!,
                textAlign: TextAlign.center,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ] else if (widget.customerEtaLabel != null &&
                widget.customerEtaLabel!.isNotEmpty &&
                widget.customerEtaLabel != widget.etaLabel) ...[
              const SizedBox(height: 4),
              Text(
                widget.customerEtaLabel!,
                textAlign: TextAlign.center,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              getTranslated('new_order_added_successfully', context) ??
                  'You have received a new order',
              textAlign: TextAlign.center,
              style: robotoRegular.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            if (canAccept) ...[
              Row(
                children: [
                  Expanded(
                    child: QuikseeButtonWidget(
                      isLoading: _cancelling,
                      btnTxt: getTranslated('cancel_order', context) ??
                          'Cancel order',
                      backgroundColor: Colors.red.shade600,
                      onTap: _isBusy ? null : _cancelOrder,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: QuikseeButtonWidget(
                      isLoading: _accepting,
                      btnTxt: getTranslated('accept_order', context) ??
                          'Accept order',
                      backgroundColor: QuikseeBrandColors.seeTextGreen,
                      onTap: _isBusy ? null : _acceptOrder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                getTranslated('accept_sends_to_delivery_man', context) ??
                    'Riders already get the offer on place — Accept = start preparing',
                textAlign: TextAlign.center,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
            ],
            QuikseeButtonWidget(
              btnTxt: getTranslated('view_details', context) ?? 'View Details',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(orderId: widget.orderId),
                  ),
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            TextButton(
              onPressed: () {
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(
                getTranslated('close', context) ?? 'Close',
                style: robotoMedium.copyWith(color: Theme.of(context).hintColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
