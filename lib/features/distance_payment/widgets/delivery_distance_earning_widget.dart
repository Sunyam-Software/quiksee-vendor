import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/distance_payment/domain/models/delivery_distance_info_model.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/features/tip/widgets/order_tip_badge_widget.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class DeliveryDistanceEarningWidget extends StatelessWidget {
  final OrderModel? order;
  final DeliveryDistanceInfo? info;
  final bool compact;
  final bool showTitle;

  const DeliveryDistanceEarningWidget({
    super.key,
    this.order,
    this.info,
    this.compact = false,
    this.showTitle = true,
  });

  String _paymentStatusLabel(String? status) {
    switch (status) {
      case 'pending_delivery':
        return 'distance_payment_pending'.tr;
      case 'credited':
        return 'distance_payment_credited'.tr;
      case 'cancelled':
        return 'distance_payment_cancelled'.tr;
      case 'not_applicable':
        return 'distance_payment_not_applicable'.tr;
      default:
        return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceController = Get.find<DistancePaymentController>();
    final data = info ??
        distanceController.resolveEarningInfo(order) ??
        order?.deliveryDistanceInfo;

    if (!distanceController.isDistanceShippingEnabled ||
        data?.isDistanceBasedDelivery != true) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fixedChargeCard(
            context,
            order?.hasTip == true
                ? distanceController.resolveDeliveryCharge(order)
                : distanceController.resolveDisplayEarning(order),
            compact: compact,
          ),
          if (order?.hasTip == true)
            Padding(
              padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              child: OrderTipBadgeWidget(order: order, compact: true),
            ),
        ],
      );
    }

    final distanceData = data;
    if (distanceData == null) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _compactRow(context, distanceData),
          if (order?.hasTip == true)
            Padding(
              padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              child: OrderTipBadgeWidget(order: order, compact: true),
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _breakdownCard(context, distanceData, order?.orderStatus == 'delivered'),
        if (order?.hasTip == true)
          Padding(
            padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            child: OrderTipBadgeWidget(order: order, compact: false),
          ),
      ],
    );
  }

  Widget _fixedChargeCard(BuildContext context, double amount,
      {bool compact = false}) {
    if (compact) {
      return Padding(
        padding:
            EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          ),
          child: Row(
            children: [
              Icon(Icons.payments,
                  size: Dimensions.iconSizeDefault,
                  color: Theme.of(context).primaryColor),
              SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  'your_earning'.tr,
                  style:
                      rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
              ),
              Text(
                PriceConverter.convertPrice(amount),
                style: rubikMedium.copyWith(
                    color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        color: Theme.of(context).cardColor,
      ),
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'additional_delivery_charge_by_admin'.tr,
              style: rubikRegular.copyWith(
                color: Get.isDarkMode ? Theme.of(context).hintColor : Colors.black,
              ),
            ),
          ),
          Text(
            PriceConverter.convertPrice(amount),
            style: rubikMedium.copyWith(
              color: Get.isDarkMode
                  ? Theme.of(context).hintColor
                  : Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactRow(BuildContext context, DeliveryDistanceInfo data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.route,
                size: Dimensions.iconSizeDefault,
                color: Theme.of(context).primaryColor),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text(
                '${data.displayDistance.toStringAsFixed(1)} ${'km'.tr} • ${'your_earning'.tr}',
                style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
            Text(
              PriceConverter.convertPrice(data.displayEarning),
              style: rubikMedium.copyWith(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdownCard(
      BuildContext context, DeliveryDistanceInfo data, bool isDelivered) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        color: Theme.of(context).cardColor,
      ),
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Text(
              'distance_based_earning'.tr,
              style: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).primaryColor,
              ),
            ),
          if (showTitle) SizedBox(height: Dimensions.paddingSizeSmall),
          _line(
            context,
            'delivery_distance'.tr,
            '${data.displayDistance.toStringAsFixed(2)} ${'km'.tr}',
          ),
          if (data.baseKm != null && data.baseDeliveryManPay != null)
            _line(
              context,
              'base_pay'.tr,
              '${PriceConverter.convertPrice(data.baseDeliveryManPay)} (${'up_to'.tr} ${data.baseKm!.toStringAsFixed(2)} ${'km'.tr})',
            ),
          if (data.displayExtraKm > 0 &&
              data.perKmRate != null &&
              data.extraKmEarning != null)
            _line(
              context,
              'extra_distance_pay'.tr,
              '${data.displayExtraKm.toStringAsFixed(2)} ${'km'.tr} × ${PriceConverter.convertPrice(data.perKmRate)} = ${PriceConverter.convertPrice(data.extraKmEarning)}',
            ),
          if ((data.deliveryManTip ?? 0) > 0)
            _line(
              context,
              'customer_tip'.tr,
              PriceConverter.convertPrice(data.deliveryManTip),
            ),
          ...((data.extraIncentiveItems ?? const <Map<String, dynamic>>[])
              .where((row) =>
                  (double.tryParse('${row['rider_share'] ?? 0}') ?? 0) > 0)
              .map((row) => _line(
                    context,
                    (row['label']?.toString().trim().isNotEmpty ?? false)
                        ? row['label'].toString().trim()
                        : 'extra_incentive'.tr,
                    PriceConverter.convertPrice(
                      double.tryParse('${row['rider_share'] ?? 0}'),
                    ),
                  ))),
          if ((data.extraIncentiveItems == null ||
                  data.extraIncentiveItems!.isEmpty) &&
              (data.extraIncentiveRiderShare ?? 0) > 0)
            _line(
              context,
              (data.extraIncentiveLabel != null &&
                      data.extraIncentiveLabel!.trim().isNotEmpty)
                  ? data.extraIncentiveLabel!.trim()
                  : 'extra_incentive'.tr,
              PriceConverter.convertPrice(data.extraIncentiveRiderShare),
            ),
          Divider(height: Dimensions.paddingSizeLarge),
          _line(
            context,
            'your_earning'.tr,
            PriceConverter.convertPrice(data.displayEarning),
            isBold: true,
          ),
          if (data.paymentStatus != null)
            Padding(
              padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              child: Row(
                children: [
                  Icon(
                    data.paymentStatus == 'credited'
                        ? Icons.check_circle
                        : Icons.schedule,
                    size: Dimensions.iconSizeSmall,
                    color: data.paymentStatus == 'credited'
                        ? Colors.green
                        : Theme.of(context).hintColor,
                  ),
                  SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(
                    child: Text(
                      _paymentStatusLabel(data.paymentStatus),
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (data.note != null && !isDelivered)
            Padding(
              padding: EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
              child: Text(
                data.note!,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value,
      {bool isBold = false}) {
    final style = isBold ? rubikMedium : rubikRegular;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
