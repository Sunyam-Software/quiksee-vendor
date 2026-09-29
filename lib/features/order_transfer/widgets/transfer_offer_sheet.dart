import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/features/order_transfer/domain/models/transfer_offer_model.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_binding.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// NEW rider: accept/reject directed transfer offer.
class TransferOfferSheet extends StatelessWidget {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _accent = Color(0xFF00C853);
  static const Color _muted = Color(0xFFB0B0B0);

  final TransferOfferModel offer;

  const TransferOfferSheet({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.92;
    if (!OrderTransferBinding.ensure()) {
      return const SizedBox.shrink();
    }

    return GetBuilder<OrderTransferController>(builder: (controller) {
      final live = controller.activeIncomingOffer;
      final o = (live?.offerId != null &&
              offer.offerId != null &&
              live!.offerId == offer.offerId)
          ? live
          : offer;
      final seconds = o.expiresIn ?? 0;
      final busy = controller.responding;
      final earning = o.expectedTotal;

      return Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.paddingSizeDefault),
                Row(
                  children: [
                    if (seconds > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                          vertical: Dimensions.paddingSizeExtraSmall,
                        ),
                        decoration: BoxDecoration(
                          color: seconds <= 10
                              ? Colors.red.withValues(alpha: .2)
                              : _accent.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${seconds}s',
                          style: rubikMedium.copyWith(
                            color: seconds <= 10 ? Colors.redAccent : _accent,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'order_transfer_request'.tr,
                      style: rubikMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  '${'order'.tr} #${o.orderId ?? '--'}',
                  style: rubikBold.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
                if ((o.storeName ?? '').isNotEmpty) ...[
                  SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    o.storeName!,
                    style: rubikMedium.copyWith(color: Colors.white),
                  ),
                ],
                if ((o.fromRiderName ?? '').isNotEmpty) ...[
                  SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    '${'from_rider'.tr}: ${o.fromRiderName}',
                    style: rubikRegular.copyWith(color: _muted),
                  ),
                ],
                SizedBox(height: Dimensions.paddingSizeDefault),
                Text(
                  'transfer_offer_hint'.tr,
                  style: rubikRegular.copyWith(color: _muted),
                ),
                SizedBox(height: Dimensions.paddingSizeLarge),
                Container(
                  padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'expected_earning'.tr,
                        style: rubikRegular.copyWith(color: _muted),
                      ),
                      SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        PriceConverter.convertPrice(earning),
                        style: rubikBold.copyWith(
                          color: _accent,
                          fontSize: 28,
                        ),
                      ),
                      SizedBox(height: Dimensions.paddingSizeSmall),
                      _earningLine(
                        'delivery_charge'.tr,
                        o.deliverymanCharge,
                      ),
                      if (o.tipAmount > 0) _earningLine('tip'.tr, o.tipAmount),
                      if (o.incentiveItems.isNotEmpty) ...[
                        ...o.incentiveItems.map(
                          (item) => _earningLine(
                            item.label == 'extra_incentive'
                                ? 'extra_incentive'.tr
                                : item.label,
                            item.riderShare,
                          ),
                        ),
                        if (_incentiveRemainder(o) > 0.009)
                          _earningLine(
                            (o.incentiveLabel != null &&
                                    o.incentiveLabel!.trim().isNotEmpty)
                                ? o.incentiveLabel!
                                : 'extra_incentive'.tr,
                            _incentiveRemainder(o),
                          ),
                      ] else if (o.expectedIncentive > 0)
                        _earningLine(
                          (o.incentiveLabel != null &&
                                  o.incentiveLabel!.trim().isNotEmpty)
                              ? o.incentiveLabel!
                              : 'extra_incentive'.tr,
                          o.expectedIncentive,
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => controller.respondIncoming('reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('deny'.tr),
                      ),
                    ),
                    SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: busy
                            ? null
                            : () => controller.respondIncoming('accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black54,
                                ),
                              )
                            : Text('accept'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  double _incentiveRemainder(TransferOfferModel o) {
    final itemsSum = o.incentiveItems.fold<double>(
      0,
      (sum, item) => sum + item.riderShare,
    );
    final leftover = o.expectedIncentive - itemsSum;
    return leftover > 0 ? leftover : 0;
  }

  Widget _earningLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: rubikRegular.copyWith(
              color: _muted,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
          Text(
            PriceConverter.convertPrice(amount),
            style: rubikMedium.copyWith(
              color: Colors.white70,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}
