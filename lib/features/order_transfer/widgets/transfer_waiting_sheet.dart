import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/features/order_transfer/domain/models/transfer_offer_model.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_binding.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// OLD rider waiting for NEW to accept/reject.
class TransferWaitingSheet extends StatefulWidget {
  final TransferOfferModel offer;
  final Future<void> Function() onCancel;

  const TransferWaitingSheet({
    super.key,
    required this.offer,
    required this.onCancel,
  });

  @override
  State<TransferWaitingSheet> createState() => _TransferWaitingSheetState();
}

class _TransferWaitingSheetState extends State<TransferWaitingSheet> {
  Timer? _tick;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    final bound = OrderTransferBinding.ensure();
    _seconds = widget.offer.expiresIn ??
        (bound
            ? Get.find<OrderTransferController>().offerTimeoutSeconds
            : 40);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!OrderTransferBinding.ensure()) return;
      final live = Get.find<OrderTransferController>()
          .pendingOutgoingOffer
          ?.expiresIn;
      setState(() {
        if (live != null && live >= 0) {
          _seconds = live;
        } else if (_seconds > 0) {
          _seconds -= 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!OrderTransferBinding.ensure()) {
      return const SizedBox.shrink();
    }
    return GetBuilder<OrderTransferController>(builder: (controller) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeLarge,
          Dimensions.paddingSizeLarge + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'waiting_for_rider_response'.tr,
              style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'transfer_wait_hint'.tr,
              textAlign: TextAlign.center,
              style: rubikRegular.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
            SizedBox(height: Dimensions.paddingSizeLarge),
            Text(
              '${_seconds}s',
              style: rubikBold.copyWith(
                fontSize: 40,
                color: _seconds <= 10
                    ? Colors.red
                    : Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: Dimensions.paddingSizeLarge),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: controller.cancelling
                    ? null
                    : () async {
                        await widget.onCancel();
                      },
                child: controller.cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('cancel_transfer'.tr),
              ),
            ),
          ],
        ),
      );
    });
  }
}
