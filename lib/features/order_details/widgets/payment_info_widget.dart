import 'package:flutter/material.dart';
import 'package:quiksee/features/order_details/widgets/payment_status_widget.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/features/order/widgets/order_item_info_widget.dart';
import 'package:get/get.dart';

class PaymentInfoWidget extends StatelessWidget {
  final double? itemsPrice;
  final double? discount;
  final double? tax;
  final double? subTotal;
  final double? deliveryCharge;
  final double? totalPrice;
  final double? referAndEarnDiscount;
  final double? couponDiscount;
  final double? extraDiscount;
  final double? platformFee;
  final String? platformFeeLabel;
  final double? tip;
  final double? scheduledDeliveryFee;
  final double? extraIncentiveFee;
  final String? extraIncentiveLabel;
  final List<Map<String, dynamic>>? extraIncentiveItems;
  final List<Map<String, dynamic>>? manualExtraCharges;
  final double? paidAmount;
  final double? dueAmount;
  final String paymentStatus;

  const PaymentInfoWidget({
    super.key,
    this.itemsPrice,
    this.discount,
    this.tax,
    this.subTotal,
    this.deliveryCharge,
    this.totalPrice,
    this.paymentStatus = '',
    this.referAndEarnDiscount,
    this.couponDiscount,
    this.extraDiscount,
    this.platformFee,
    this.platformFeeLabel,
    this.tip,
    this.scheduledDeliveryFee,
    this.extraIncentiveFee,
    this.extraIncentiveLabel,
    this.extraIncentiveItems,
    this.manualExtraCharges,
    this.paidAmount,
    this.dueAmount,
  });

  /// Same 2-decimal money the user sees on each row.
  static double _money(double? value) {
    final v = value ?? 0;
    return (v * 100).round() / 100.0;
  }

  /// Exact Total = sum of every Payment Info line shown on screen.
  double get _exactTotalFromRows {
    final product = _money(itemsPrice);
    final disc = _money(discount);
    final coupon = _money(couponDiscount);
    final extra = _money(extraDiscount);
    final refer = _money(referAndEarnDiscount);
    final taxAmt = _money(tax);
    final delivery = _money(deliveryCharge);
    final platform = _money(platformFee);
    final scheduled = _money(scheduledDeliveryFee);
    final tipAmt = _money(tip);

    // Prefer sum of visible dynamic lines; fall back to fee total.
    var incentive = 0.0;
    final items = extraIncentiveItems ?? const <Map<String, dynamic>>[];
    if (items.isNotEmpty) {
      for (final row in items) {
        incentive += _money(double.tryParse(
            '${row['customer_charge'] ?? row['amount'] ?? 0}'));
      }
    }
    if (incentive <= 0) {
      incentive = _money(extraIncentiveFee);
    }

    var manual = 0.0;
    for (final row in manualExtraCharges ?? const <Map<String, dynamic>>[]) {
      manual += _money(double.tryParse('${row['amount'] ?? 0}'));
    }

    var total = product - disc + taxAmt + delivery;
    if (coupon > 0) total -= coupon;
    if (extra > 0) total -= extra;
    if (refer > 0) total -= refer;
    if (platform > 0) total += platform;
    if (scheduled > 0) total += scheduled;
    if (tipAmt > 0) total += tipAmt;
    if (incentive > 0) total += incentive;
    if (manual > 0) total += manual;

    final fromRows = _money(total);
    final passed = _money(totalPrice);
    if (passed > fromRows) return passed;
    return fromRows;
  }

  @override
  Widget build(BuildContext context) {
    final exactTotal = _exactTotalFromRows;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeMin,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Get.find<ThemeController>().darkTheme
                ? Colors.black.withValues(alpha: 0.10)
                : Colors.grey[100]!,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            SizedBox(width: 20, child: Image.asset(Images.orderInfo)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeDefault,
              ),
              child: Text(
                'payment_info'.tr,
                style: rubikMedium.copyWith(
                  color: Get.isDarkMode
                      ? Theme.of(context).hintColor.withValues(alpha: .5)
                      : Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            ),
          ]),
          PaymentStatusWidget(isPaid: paymentStatus),
        ]),
        Column(children: [
          OrderItemInfoWidget(
            title: 'product_price',
            info: _money(itemsPrice).toStringAsFixed(2),
            isPrice: true,
            isCount: false,
          ),
          OrderItemInfoWidget(
            title: 'discount',
            info: _money(discount).toStringAsFixed(2),
            isPrice: true,
          ),
          if ((couponDiscount ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'coupon_discount',
              info: _money(couponDiscount).toStringAsFixed(2),
              isPrice: true,
            ),
          if ((extraDiscount ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'extra_discount',
              info: _money(extraDiscount).toStringAsFixed(2),
              isPrice: true,
            ),
          if ((referAndEarnDiscount ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'referral_discount',
              info: _money(referAndEarnDiscount).toStringAsFixed(2),
              isPrice: true,
            ),
          OrderItemInfoWidget(
            title: 'tax',
            info: _money(tax).toStringAsFixed(2),
            isPrice: true,
          ),
          OrderItemInfoWidget(
            title: 'delivery_cost',
            info: _money(deliveryCharge).toStringAsFixed(2),
            isPrice: true,
          ),
          if ((platformFee ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'platform_fee',
              info: _money(platformFee).toStringAsFixed(2),
              isPrice: true,
            ),
          if ((scheduledDeliveryFee ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'scheduled_delivery_fee',
              info: _money(scheduledDeliveryFee).toStringAsFixed(2),
              isPrice: true,
            ),
          if ((tip ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'customer_tip',
              info: _money(tip).toStringAsFixed(2),
              isPrice: true,
            ),
          ...((extraIncentiveItems ?? const <Map<String, dynamic>>[])
              .where((row) {
                final amt = _money(double.tryParse(
                    '${row['customer_charge'] ?? row['amount'] ?? 0}'));
                return amt > 0;
              })
              .map((row) => OrderItemInfoWidget(
                    title: (row['label']?.toString().trim().isNotEmpty ?? false)
                        ? row['label'].toString().trim()
                        : 'extra_incentive',
                    info: _money(double.tryParse(
                            '${row['customer_charge'] ?? row['amount'] ?? 0}'))
                        .toStringAsFixed(2),
                    isPrice: true,
                  ))),
          if ((extraIncentiveItems == null || extraIncentiveItems!.isEmpty) &&
              (extraIncentiveFee ?? 0) > 0)
            OrderItemInfoWidget(
              title: (extraIncentiveLabel != null &&
                      extraIncentiveLabel!.trim().isNotEmpty)
                  ? extraIncentiveLabel!.trim()
                  : 'extra_incentive',
              info: _money(extraIncentiveFee).toStringAsFixed(2),
              isPrice: true,
            ),
          ...((manualExtraCharges ?? const <Map<String, dynamic>>[])
              .where((row) =>
                  _money(double.tryParse('${row['amount'] ?? 0}')) > 0)
              .map((row) => OrderItemInfoWidget(
                    title: (row['label']?.toString().trim().isNotEmpty ?? false)
                        ? row['label'].toString().trim()
                        : 'extra_charge',
                    info: _money(double.tryParse('${row['amount'] ?? 0}'))
                        .toStringAsFixed(2),
                    isPrice: true,
                  ))),
          Divider(
            height: .0725,
            color: Theme.of(context).hintColor.withValues(alpha: .5),
          ),
          OrderItemInfoWidget(
            title: 'total',
            titleTextStyle: rubikRegular.copyWith(
              color: Get.isDarkMode
                  ? Theme.of(context).hintColor
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: Dimensions.fontSizeDefault,
            ),
            textStyle: rubikBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            info: exactTotal.toStringAsFixed(2),
            isPrice: true,
          ),
          if ((dueAmount ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'paid_amount',
              titleTextStyle: rubikRegular.copyWith(
                color: Get.isDarkMode
                    ? Theme.of(context).hintColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: Dimensions.fontSizeDefault,
              ),
              textStyle: rubikRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              info: _money(paidAmount).toStringAsFixed(2),
              isPrice: true,
            ),
          if ((dueAmount ?? 0) > 0)
            OrderItemInfoWidget(
              title: 'due_amount',
              titleTextStyle: rubikBold.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontSize: Dimensions.fontSizeDefault,
              ),
              textStyle: rubikBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).colorScheme.error,
              ),
              info: _money(dueAmount).toStringAsFixed(2),
              isPrice: true,
            ),
        ]),
        if (paymentStatus == 'partially_paid' || paymentStatus == 'unpaid')
          Container(
            width: MediaQuery.sizeOf(context).width,
            padding: EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeMin,
              vertical: Dimensions.paddingSizeChat,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeMin),
            ),
            child: Text(
              'make_sure_to_collect_cash_before_handover_the_product'.tr,
              style: rubikRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withValues(alpha: 0.80),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        SizedBox(height: Dimensions.paddingSizeChat),
      ]),
    );
  }
}
