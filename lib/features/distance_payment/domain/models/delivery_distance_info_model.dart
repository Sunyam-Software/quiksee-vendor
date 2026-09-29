class DeliveryDistanceInfo {
  bool? isDistanceBasedDelivery;
  double? distanceKm;
  double? deliveryDistanceKm;
  double? actualDistanceKm;
  double? deliveryActualDistanceKm;
  double? baseKm;
  double? extraKm;
  double? deliveryExtraKm;
  double? perKmRate;
  double? baseDeliveryManPay;
  double? extraKmEarning;
  double? deliveryManEarning;
  double? customerPaidShipping;
  double? adminMargin;
  String? shippingCity;
  String? earningFormula;
  String? paymentStatus;
  int? orderId;
  String? orderStatus;
  bool? isDelivered;
  double? estimatedEarning;
  String? willCreditOn;
  String? note;
  double? deliveryManTip;
  double? deliveryManTotalEarning;
  double? deliverymanCharge;
  double? extraIncentiveRiderShare;
  String? extraIncentiveLabel;
  List<Map<String, dynamic>>? extraIncentiveItems;

  DeliveryDistanceInfo({
    this.isDistanceBasedDelivery,
    this.distanceKm,
    this.deliveryDistanceKm,
    this.actualDistanceKm,
    this.deliveryActualDistanceKm,
    this.baseKm,
    this.extraKm,
    this.deliveryExtraKm,
    this.perKmRate,
    this.baseDeliveryManPay,
    this.extraKmEarning,
    this.deliveryManEarning,
    this.customerPaidShipping,
    this.adminMargin,
    this.shippingCity,
    this.earningFormula,
    this.paymentStatus,
    this.orderId,
    this.orderStatus,
    this.isDelivered,
    this.estimatedEarning,
    this.willCreditOn,
    this.note,
    this.deliveryManTip,
    this.deliveryManTotalEarning,
    this.deliverymanCharge,
    this.extraIncentiveRiderShare,
    this.extraIncentiveLabel,
    this.extraIncentiveItems,
  });

  /// Planned store → customer distance (not rider → store).
  double get displayDistance =>
      deliveryDistanceKm ?? distanceKm ?? 0;

  /// Actual driven for store → customer only (never full trip via store).
  double? get displayActualDistance {
    if (deliveryActualDistanceKm != null && deliveryActualDistanceKm! > 0) {
      return deliveryActualDistanceKm;
    }
    // Prefer store→customer planned distance over total-trip actual_distance_km
    // (actual_distance_km often includes rider → store as well).
    if (deliveryDistanceKm != null && deliveryDistanceKm! > 0) {
      return deliveryDistanceKm;
    }
    if (distanceKm != null && distanceKm! > 0) {
      return distanceKm;
    }
    return null;
  }

  double get displayExtraKm => extraKm ?? deliveryExtraKm ?? 0;

  double get displayDistancePay {
    final saved = deliveryManEarning ?? deliverymanCharge ?? 0;
    if (saved > 0) return saved;
    final base = baseDeliveryManPay ?? 0;
    if (base > 0) {
      return base + displayExtraKm * (perKmRate ?? 0);
    }
    return 0;
  }

  /// Full rider earning: distance + tip + extra incentive rider share.
  double get displayEarning {
    final tip = deliveryManTip ?? 0;
    final incentive = extraIncentiveRiderShare ?? 0;
    final distance = displayDistancePay;
    final composed = _roundMoney(distance + tip + incentive);

    final total = deliveryManTotalEarning ?? 0;
    if (total > 0) {
      // Prefer API total, but never drop tip/incentive if composed is higher.
      return total >= composed - 0.009 ? _roundMoney(total) : composed;
    }

    final estimated = estimatedEarning ?? 0;
    if (estimated > 0) {
      return estimated >= composed - 0.009 ? _roundMoney(estimated) : composed;
    }

    return composed;
  }

  static double _roundMoney(double value) =>
      ((value * 100).round()) / 100.0;

  bool get hasDistanceEarning => displayEarning > 0;

  bool get shouldShowDistanceBreakdown =>
      isDistanceBasedDelivery == true ||
      displayDistance > 0 ||
      (displayActualDistance ?? 0) > 0;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    try {
      return value.toDouble();
    } catch (_) {
      return double.tryParse(value.toString());
    }
  }

  factory DeliveryDistanceInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryDistanceInfo(
      isDistanceBasedDelivery: json['is_distance_based_delivery'] == true,
      distanceKm: _toDouble(json['distance_km']) ??
          _toDouble(json['store_to_customer_km']) ??
          _toDouble(json['store_to_delivery_km']),
      deliveryDistanceKm: _toDouble(json['delivery_distance_km']) ??
          _toDouble(json['delivery_leg_distance_km']),
      actualDistanceKm: _toDouble(json['actual_distance_km']),
      deliveryActualDistanceKm: _toDouble(json['delivery_actual_distance_km']) ??
          _toDouble(json['store_to_customer_actual_km']) ??
          _toDouble(json['delivery_leg_actual_km']),
      baseKm: _toDouble(json['base_km']),
      extraKm: _toDouble(json['extra_km']),
      deliveryExtraKm: _toDouble(json['delivery_extra_km']),
      perKmRate: _toDouble(json['per_km_rate']),
      baseDeliveryManPay: _toDouble(json['base_delivery_man_pay']),
      extraKmEarning: _toDouble(json['extra_km_earning']),
      deliveryManEarning: _toDouble(json['delivery_man_earning']) ??
          _toDouble(json['estimated_delivery_man_earning']),
      customerPaidShipping: _toDouble(json['customer_paid_shipping']),
      adminMargin: _toDouble(json['admin_margin']),
      shippingCity: json['shipping_city']?.toString(),
      earningFormula: json['earning_formula']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      orderId: int.tryParse('${json['order_id']}'),
      orderStatus: json['order_status']?.toString(),
      isDelivered: json['is_delivered'] == true,
      estimatedEarning: _toDouble(json['estimated_earning'] ??
          json['estimated_delivery_man_earning']),
      willCreditOn: json['will_credit_on']?.toString(),
      note: json['note']?.toString(),
      deliveryManTip: _toDouble(json['delivery_man_tip']),
      deliveryManTotalEarning: _toDouble(json['delivery_man_total_earning']),
      deliverymanCharge: _toDouble(json['deliveryman_charge']),
      extraIncentiveRiderShare: _toDouble(json['extra_incentive_rider_share']),
      extraIncentiveLabel: json['extra_incentive_label']?.toString(),
      extraIncentiveItems: json['extra_incentive_items'] is List
          ? (json['extra_incentive_items'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : null,
    );
  }
}
