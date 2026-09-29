import 'package:quiksee/features/distance_payment/domain/models/delivery_distance_info_model.dart';

class TipItemModel {
  int? orderId;
  String? orderStatus;
  String? customerName;
  double? deliveryManTip;
  String? deliveryManTipFormatted;
  double? deliverymanCharge;
  String? deliverymanChargeFormatted;
  double? deliveryManTotalEarning;
  String? deliveryManTotalEarningFormatted;
  String? tipStatus;
  bool? tipCredited;
  String? tipCreditedAt;
  String? orderCreatedAt;
  DeliveryDistanceInfo? deliveryDistanceInfo;
  String? paymentStatus;
  String? paymentMethod;
  double? orderAmount;
  String? orderAmountFormatted;
  String? storeName;
  String? deliveryAddress;
  String? note;

  TipItemModel({
    this.orderId,
    this.orderStatus,
    this.customerName,
    this.deliveryManTip,
    this.deliveryManTipFormatted,
    this.deliverymanCharge,
    this.deliverymanChargeFormatted,
    this.deliveryManTotalEarning,
    this.deliveryManTotalEarningFormatted,
    this.tipStatus,
    this.tipCredited,
    this.tipCreditedAt,
    this.orderCreatedAt,
    this.deliveryDistanceInfo,
    this.paymentStatus,
    this.paymentMethod,
    this.orderAmount,
    this.orderAmountFormatted,
    this.storeName,
    this.deliveryAddress,
    this.note,
  });

  bool get hasTip => (deliveryManTip ?? 0) > 0;
  bool get isPending => tipStatus == 'pending';
  bool get isEarned => tipStatus == 'earned';

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    try {
      return value.toDouble();
    } catch (_) {
      return double.tryParse(value.toString());
    }
  }

  factory TipItemModel.fromJson(Map<String, dynamic> json) {
    return TipItemModel(
      orderId: int.tryParse('${json['order_id'] ?? json['id']}'),
      orderStatus: json['order_status']?.toString(),
      customerName: json['customer_name']?.toString(),
      deliveryManTip: _toDouble(json['delivery_man_tip']),
      deliveryManTipFormatted: json['delivery_man_tip_formatted']?.toString(),
      deliverymanCharge: _toDouble(json['deliveryman_charge']),
      deliverymanChargeFormatted:
          json['deliveryman_charge_formatted']?.toString(),
      deliveryManTotalEarning: _toDouble(json['delivery_man_total_earning']),
      deliveryManTotalEarningFormatted:
          json['delivery_man_total_earning_formatted']?.toString(),
      tipStatus: json['tip_status']?.toString(),
      tipCredited: json['tip_credited'] == true,
      tipCreditedAt: json['tip_credited_at']?.toString(),
      orderCreatedAt: json['order_created_at']?.toString(),
      deliveryDistanceInfo: json['delivery_distance_info'] != null
          ? DeliveryDistanceInfo.fromJson(json['delivery_distance_info'])
          : null,
      paymentStatus: json['payment_status']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      orderAmount: _toDouble(json['order_amount']),
      orderAmountFormatted: json['order_amount_formatted']?.toString(),
      storeName: json['store_name']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      note: json['note']?.toString(),
    );
  }
}

class TipListModel {
  bool? supported;
  bool? tipSystemEnabled;
  int? totalSize;
  int? limit;
  int? offset;
  double? totalTipInPage;
  double? totalEarningInPage;
  List<TipItemModel>? tips;

  TipListModel({
    this.supported,
    this.tipSystemEnabled,
    this.totalSize,
    this.limit,
    this.offset,
    this.totalTipInPage,
    this.totalEarningInPage,
    this.tips,
  });

  bool get isEnabled => supported == true && tipSystemEnabled == true;

  factory TipListModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      try {
        return value.toDouble();
      } catch (_) {
        return double.tryParse(value.toString());
      }
    }

    final summary = json['summary'];
    return TipListModel(
      supported: json['supported'] == true,
      tipSystemEnabled: json['tip_system_enabled'] == true,
      totalSize: int.tryParse('${json['total_size']}'),
      limit: int.tryParse('${json['limit']}'),
      offset: int.tryParse('${json['offset']}'),
      totalTipInPage: summary != null
          ? toDouble(summary['total_tip_in_page'])
          : null,
      totalEarningInPage: summary != null
          ? toDouble(summary['total_earning_in_page'])
          : null,
      tips: json['tips'] != null
          ? (json['tips'] as List)
              .map((v) => TipItemModel.fromJson(v))
              .toList()
          : null,
    );
  }
}
