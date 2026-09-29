import 'package:quiksee/features/distance_payment/domain/models/delivery_distance_info_model.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_group_helper.dart';
import 'package:quiksee/features/order_details/domain/models/order_details_model.dart';

class OrderCollectAmountHelper {
  OrderCollectAmountHelper._();

  static String? _taxModel(OrderModel? order, List<OrderDetailsModel>? lineItems) {
    return order?.taxModel ??
        (lineItems?.isNotEmpty == true
            ? lineItems!.first.orderModel?.taxModel
            : null);
  }

  /// Tax line for UI. Include-model tax is already in product price.
  static double displayTaxAmount(
    OrderModel? order, [
    List<OrderDetailsModel>? lineItems,
  ]) {
    if ((_taxModel(order, lineItems) ?? '').toLowerCase() == 'include') {
      return 0;
    }

    final fromOrder = order?.totalTaxAmount ??
        (lineItems?.isNotEmpty == true
            ? lineItems!.first.orderModel?.totalTaxAmount
            : null);
    if (fromOrder != null && fromOrder > 0) {
      return _roundMoney(fromOrder);
    }

    if (lineItems != null && lineItems.isNotEmpty) {
      double lineTax = 0;
      for (final line in lineItems) {
        lineTax += (line.totalTaxAmount ?? 0) > 0
            ? (line.totalTaxAmount ?? 0)
            : (line.tax ?? 0);
      }
      if (lineTax > 0) return _roundMoney(lineTax);
    }

    return 0;
  }

  static double platformFeeOf(OrderModel? order) =>
      _roundMoney(order?.platformFee ?? 0);

  static double tipOf(OrderModel? order, [DeliveryDistanceInfo? distanceInfo]) =>
      _roundMoney(order?.deliveryManTip ?? distanceInfo?.deliveryManTip ?? 0);

  static double scheduledDeliveryFeeOf(OrderModel? order) {
    final direct = order?.scheduledDeliveryCharge ?? 0;
    if (direct > 0) return _roundMoney(direct);
    return _roundMoney(order?.scheduledDelivery?.extraCharge ?? 0);
  }

  static double extraIncentiveFeeOf(OrderModel? order) {
    final direct = order?.extraIncentiveCharge ?? 0;

    // Always sum customer-facing dynamic lines (latefee etc.).
    var fromItems = 0.0;
    for (final row in order?.extraIncentiveItems ?? const <Map<String, dynamic>>[]) {
      fromItems += double.tryParse('${row['customer_charge'] ?? row['amount'] ?? 0}') ?? 0;
    }
    fromItems = _roundMoney(fromItems);

    if (direct > 0 && fromItems > 0) {
      return direct >= fromItems ? _roundMoney(direct) : fromItems;
    }
    if (direct > 0) return _roundMoney(direct);
    if (fromItems > 0) return fromItems;
    return 0;
  }

  static List<Map<String, dynamic>> manualExtraChargesOf(OrderModel? order) =>
      order?.manualExtraCharges ?? const <Map<String, dynamic>>[];

  static double manualExtraChargesTotalOf(OrderModel? order) {
    var total = 0.0;
    for (final row in manualExtraChargesOf(order)) {
      total += double.tryParse('${row['amount'] ?? 0}') ?? 0;
    }
    return _roundMoney(total);
  }

  /// Product / item discount (admin "Item discount").
  static double itemDiscountOf(
    OrderModel? order, [
    List<OrderDetailsModel>? lineItems,
  ]) {
    if ((order?.itemDiscount ?? 0) > 0) {
      return _roundMoney(order!.itemDiscount!);
    }
    double lineDiscount = 0;
    if (lineItems != null) {
      for (final line in lineItems) {
        lineDiscount += line.discount ?? 0;
      }
    }
    return _roundMoney(lineDiscount);
  }

  /// Checkout coupon (admin "Coupon discount").
  static double couponDiscountOf(OrderModel? order) {
    if ((order?.couponDiscount ?? 0) > 0) {
      return _roundMoney(order!.couponDiscount!);
    }
    return 0;
  }

  /// Extra / vendor discount.
  static double extraDiscountOf(OrderModel? order) {
    if ((order?.extraDiscount ?? 0) > 0) {
      return _roundMoney(order!.extraDiscount!);
    }
    return 0;
  }

  static double referDiscountOf(
    OrderModel? order, [
    List<OrderDetailsModel>? lineItems,
  ]) {
    final fromOrder = order?.referAndEarnDiscount ??
        (lineItems?.isNotEmpty == true
            ? lineItems!.first.orderModel?.referAndEarnDiscount
            : null) ??
        0;
    return _roundMoney(fromOrder);
  }

  /// What customer paid for shipping at checkout (`shipping_cost`).
  static double customerShippingOf(
    OrderModel? order, [
    DeliveryDistanceInfo? distanceInfo,
  ]) {
    if (order?.isShippingFree == true) return 0;
    final checkoutShipping = order?.shippingCost ?? 0;
    if (checkoutShipping > 0) return _roundMoney(checkoutShipping);
    return _roundMoney(
      distanceInfo?.customerPaidShipping ??
          order?.deliveryDistanceInfo?.customerPaidShipping ??
          0,
    );
  }

  /// Server COD amount (exact). Prefer this over client re-sum.
  static double serverCollectAmount(OrderModel? order) {
    final amount = order?.orderAmount ?? 0;
    return amount > 0 ? _roundMoney(amount) : 0;
  }

  /// Same math as customer checkout / Payment Info rows.
  static double fromBreakdown({
    required OrderModel? order,
    List<OrderDetailsModel>? lineItems,
    DeliveryDistanceInfo? distanceInfo,
    double? editDueAmount,
  }) {
    if (editDueAmount != null && editDueAmount > 0) {
      return _roundMoney(editDueAmount);
    }

    double itemsPrice = 0;
    if (lineItems != null) {
      for (final line in lineItems) {
        itemsPrice += (line.price ?? 0) * (line.qty ?? 0);
      }
    }

    final itemDisc = itemDiscountOf(order, lineItems);
    final coupon = couponDiscountOf(order);
    final extra = extraDiscountOf(order);
    final refer = referDiscountOf(order, lineItems);
    final tax = displayTaxAmount(order, lineItems);
    final shipping = customerShippingOf(order, distanceInfo);

    // If coupon/extra not parsed but order.discount_amount still has remainder.
    final orderDisc = order?.discountAmount ?? 0;
    final knownDiscounts = itemDisc + coupon + extra + refer;
    final leftover = orderDisc > knownDiscounts + 0.009
        ? _roundMoney(orderDisc - knownDiscounts)
        : 0.0;

    return _roundMoney(
      itemsPrice +
          tax -
          itemDisc -
          coupon -
          extra -
          refer -
          leftover +
          shipping +
          platformFeeOf(order) +
          tipOf(order, distanceInfo) +
          scheduledDeliveryFeeOf(order) +
          extraIncentiveFeeOf(order) +
          manualExtraChargesTotalOf(order),
    );
  }

  /// Exact sum of the Payment Info rows shown on screen.
  static double fromDisplayedRows({
    required double itemsPrice,
    required double discount,
    required double tax,
    required double deliveryCharge,
    double referAndEarnDiscount = 0,
    double couponDiscount = 0,
    double extraDiscount = 0,
    double platformFee = 0,
    double tip = 0,
    double scheduledDeliveryFee = 0,
    double extraIncentiveFee = 0,
    double manualExtraChargesTotal = 0,
  }) {
    return _roundMoney(
      itemsPrice -
          discount -
          couponDiscount -
          extraDiscount -
          referAndEarnDiscount +
          tax +
          deliveryCharge +
          platformFee +
          tip +
          scheduledDeliveryFee +
          extraIncentiveFee +
          manualExtraChargesTotal,
    );
  }

  static double resolve({
    required OrderModel? order,
    List<OrderDetailsModel>? lineItems,
    DeliveryDistanceInfo? distanceInfo,
    double? editDueAmount,
    List<OrderModel>? currentOrders,
  }) {
    if (editDueAmount != null && editDueAmount > 0) {
      return _roundMoney(editDueAmount);
    }

    if (order != null &&
        currentOrders != null &&
        OrderGroupHelper.isCombinedCheckout(order) &&
        OrderGroupHelper.combinedOrderCount(order, currentOrders) > 1) {
      final combined =
          OrderGroupHelper.combinedCodAmount(order, currentOrders);
      if (combined > 0) return _roundMoney(combined);
    }

    final breakdown = (lineItems != null && lineItems.isNotEmpty)
        ? fromBreakdown(
            order: order,
            lineItems: lineItems,
            distanceInfo: distanceInfo,
          )
        : 0.0;
    final server = serverCollectAmount(order);

    // Server order_amount is admin truth (includes dynamic fees). Prefer it so
    if (server > 0 && breakdown > 0) {
      if ((breakdown - server).abs() <= 0.02) {
        return server;
      }
      return server >= breakdown ? server : breakdown;
    }
    if (server > 0) return server;
    if (breakdown > 0) return breakdown;

    return fromBreakdown(
      order: order,
      lineItems: lineItems,
      distanceInfo: distanceInfo,
      editDueAmount: editDueAmount,
    );
  }

  /// Prefer positive money from either side when merging order models.
  static double? preferPositiveMoney(double? primary, double? fallback) {
    if (primary != null && primary > 0) return primary;
    if (fallback != null && fallback > 0) return fallback;
    return primary ?? fallback;
  }

  static double? preferMaxMoney(double? primary, double? fallback) {
    final a = (primary != null && primary > 0) ? primary : null;
    final b = (fallback != null && fallback > 0) ? fallback : null;
    if (a != null && b != null) return a >= b ? a : b;
    return a ?? b ?? primary ?? fallback;
  }

  static double _roundMoney(double value) {
    final cents = (value * 100).round();
    return cents / 100.0;
  }
}
