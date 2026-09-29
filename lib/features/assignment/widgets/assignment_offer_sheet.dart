import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/assignment/domain/models/assignment_offer_model.dart';
import 'package:quiksee/features/order_details/widgets/slider_button_widget.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class AssignmentOfferSheet extends StatelessWidget {
  static const Color _bg = Color(0xFF0A0A0A);
  static const Color _accent = Color(0xFF00C853);
  static const Color _muted = Color(0xFFB0B0B0);
  static const Color _line = Color(0xFF2A2A2A);

  final AssignmentOfferModel offer;

  const AssignmentOfferSheet({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = media.size.height * 0.92;

    return GetBuilder<AssignmentController>(
      builder: (controller) {
        final live = controller.activeOffer;
        final o = (live?.offerId != null &&
                offer.offerId != null &&
                live!.offerId == offer.offerId)
            ? live
            : offer;
        final seconds = o.secondsRemaining ?? 0;
        final earning = o.displayEarning;
        final pickupKm = o.distanceToStoreKm;
        final dropKm = o.deliveryDistanceInfo?.displayDistance;
        final busy = controller.isAccepting || controller.isRejecting;

        return Container(
          height: sheetHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeDefault,
                    0,
                  ),
                  child: Row(
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
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final id = o.offerId;
                                if (id == null) return;
                                await controller.rejectOffer(id);
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white54,
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: Dimensions.paddingSizeExtraSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: controller.isRejecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black54,
                                ),
                              )
                            : Text(
                                'deny'.tr,
                                style: rubikMedium.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: Dimensions.paddingSizeLarge),
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeExtraSmall,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _accent, width: 1.4),
                            ),
                            child: Text(
                              o.isScheduled
                                  ? 'scheduled_delivery'.tr
                                  : 'new_order'.tr,
                              style: rubikMedium.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingSizeExtraLarge),
                        Text(
                          'estimated_earnings'.tr,
                          textAlign: TextAlign.center,
                          style: rubikRegular.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Text(
                          earning > 0
                              ? PriceConverter.convertPrice(earning)
                              : '—',
                          textAlign: TextAlign.center,
                          style: rubikBold.copyWith(
                            color: Colors.white,
                            fontSize: 40,
                            height: 1.1,
                          ),
                        ),
                        if (o.extraOnOffer > 0) ...[
                          SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            '${'extra_incentive'.tr} ${PriceConverter.convertPrice(o.extraOnOffer)}',
                            textAlign: TextAlign.center,
                            style: rubikMedium.copyWith(
                              color: _accent,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ],
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          _distanceLine(pickupKm, dropKm),
                          textAlign: TextAlign.center,
                          style: rubikRegular.copyWith(
                            color: _muted,
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                        if (o.isCombinedCheckout) ...[
                          SizedBox(height: Dimensions.paddingSizeSmall),
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeSmall,
                                vertical: Dimensions.paddingSizeExtraSmall,
                              ),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _accent),
                              ),
                              child: Text(
                                (o.combinedLabel?.trim().isNotEmpty == true)
                                    ? o.combinedLabel!.trim()
                                    : 'combine'.tr,
                                style: rubikBold.copyWith(
                                  color: _accent,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (o.scheduledDelivery?.label?.isNotEmpty == true) ...[
                          SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            o.scheduledDelivery!.label!,
                            textAlign: TextAlign.center,
                            style: rubikRegular.copyWith(color: _muted),
                          ),
                        ],
                        SizedBox(height: Dimensions.paddingSizeExtraLarge),
                        const Divider(color: _line, height: 1),
                        SizedBox(height: Dimensions.paddingSizeLarge),
                        _sectionBadge('pick_up'.tr),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          o.displayStoreName?.trim().isNotEmpty == true
                              ? o.displayStoreName!
                              : 'Shop',
                          style: rubikBold.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeExtraLarge,
                          ),
                        ),
                        if (o.storeAddress?.trim().isNotEmpty == true) ...[
                          SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            o.storeAddress!,
                            style: rubikRegular.copyWith(
                              color: _muted,
                              fontSize: Dimensions.fontSizeDefault,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (o.etaLabel != null && o.etaLabel!.trim().isNotEmpty) ...[
                          SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            o.etaLabel!,
                            style: rubikMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                          ),
                          if (o.etaBreakdown != null &&
                              o.etaBreakdown!.trim().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                o.etaBreakdown!,
                                style: rubikRegular.copyWith(
                                  color: _muted,
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                              ),
                            ),
                        ],
                        if (pickupKm != null && pickupKm > 0) ...[
                          SizedBox(height: Dimensions.paddingSizeSmall),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: _muted,
                              ),
                              SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Text(
                                '${_etaMinutes(pickupKm)} mins away',
                                style: rubikRegular.copyWith(
                                  color: _muted,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: Dimensions.paddingSizeLarge),
                        const Divider(color: _line, height: 1),
                        SizedBox(height: Dimensions.paddingSizeLarge),
                        _sectionBadge('delivery'.tr),
                        SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          o.customerName?.trim().isNotEmpty == true
                              ? o.customerName!
                              : 'customer'.tr,
                          style: rubikBold.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeExtraLarge,
                          ),
                        ),
                        if (o.deliveryAddress?.trim().isNotEmpty == true) ...[
                          SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            o.deliveryAddress!,
                            style: rubikRegular.copyWith(
                              color: _muted,
                              fontSize: Dimensions.fontSizeDefault,
                              height: 1.35,
                            ),
                          ),
                        ],
                        if (dropKm != null && dropKm > 0) ...[
                          SizedBox(height: Dimensions.paddingSizeSmall),
                          Row(
                            children: [
                              const Icon(
                                Icons.route,
                                size: 16,
                                color: _muted,
                              ),
                              SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Text(
                                '${dropKm.toStringAsFixed(2)} km',
                                style: rubikRegular.copyWith(
                                  color: _muted,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: Dimensions.paddingSizeExtraLarge),
                        Text(
                          o.displayOrderTitle,
                          textAlign: TextAlign.center,
                          style: rubikRegular.copyWith(
                            color: _muted.withValues(alpha: .7),
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                        SizedBox(height: Dimensions.paddingSizeDefault),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeDefault,
                  ),
                  child: busy && controller.isAccepting
                      ? Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: .4),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : SliderButtonWidget(
                          disable: busy,
                          dismissible: false,
                          dismissThresholds: 0.55,
                          height: 56,
                          buttonSize: 48,
                          width: media.size.width -
                              (Dimensions.paddingSizeDefault * 2),
                          radius: 100,
                          backgroundColor: _accent,
                          buttonColor: Colors.black,
                          baseColor: Colors.white,
                          highlightedColor: Colors.white70,
                          boxShadow: const BoxShadow(blurRadius: 0),
                          alignLabel: Alignment.center,
                          icon: const Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                            size: 22,
                          ),
                          label: Text(
                            'accept_order_swipe'.tr,
                            style: rubikBold.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                          ),
                          action: () async {
                            final id = o.offerId;
                            if (id == null || busy) return false;
                            return controller.acceptOffer(id);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _sectionBadge(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: rubikMedium.copyWith(
            color: Colors.black,
            fontSize: Dimensions.fontSizeSmall,
          ),
        ),
      ),
    );
  }

  static String _distanceLine(double? pickupKm, double? dropKm) {
    final parts = <String>[];
    if (pickupKm != null && pickupKm > 0) {
      parts.add('Pickup: ${pickupKm.toStringAsFixed(2)} kms');
    }
    if (dropKm != null && dropKm > 0) {
      parts.add('Drop: ${dropKm.toStringAsFixed(2)} kms');
    }
    if (parts.isEmpty) return 'Pickup & Drop details loading…';
    return parts.join('  |  ');
  }

  static int _etaMinutes(double km) {
    // ~20 km/h city heuristic, min 1.
    return (km * 3).ceil().clamp(1, 99);
  }
}
