import 'dart:convert';

class TransferOfferIncentiveItem {
  final String label;
  final double riderShare;

  TransferOfferIncentiveItem({required this.label, required this.riderShare});
}

class TransferOfferModel {
  int? offerId;
  int? orderId;
  String? status;
  int? expiresIn;
  String? expiresAt;
  int? fromDeliveryManId;
  int? toDeliveryManId;
  double tipAmount;
  double deliverymanCharge;
  double expectedIncentive;
  double? expectedTotalOverride;
  String? incentiveLabel;
  List<TransferOfferIncentiveItem> incentiveItems;
  String? storeName;
  String? fromRiderName;

  TransferOfferModel({
    this.offerId,
    this.orderId,
    this.status,
    this.expiresIn,
    this.expiresAt,
    this.fromDeliveryManId,
    this.toDeliveryManId,
    this.tipAmount = 0,
    this.deliverymanCharge = 0,
    this.expectedIncentive = 0,
    this.expectedTotalOverride,
    this.incentiveLabel,
    this.incentiveItems = const [],
    this.storeName,
    this.fromRiderName,
  });

  factory TransferOfferModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = Map<String, dynamic>.from(json);
    final nested = json['offer'];
    if (nested is Map) {
      data = {...data, ...Map<String, dynamic>.from(nested)};
    }
    double d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    final charge = d(
      data['deliveryman_charge_snapshot'] ??
          data['expected_deliveryman_charge'] ??
          data['deliveryman_charge'],
    );
    final tip = d(data['tip_amount_snapshot'] ?? data['expected_tip']);
    final incentive = d(
      data['incentive_snapshot'] ??
          data['expected_incentive'] ??
          data['extra_incentive_rider_share'],
    );
    final serverTotal =
        d(data['expected_total'] ?? data['delivery_man_total_earning']);
    final label = (data['extra_incentive_label'] ?? data['incentive_label'])
        ?.toString()
        .trim();
    return TransferOfferModel(
      offerId: int.tryParse('${data['offer_id'] ?? ''}'),
      orderId: int.tryParse('${data['order_id'] ?? ''}'),
      status: data['status']?.toString(),
      expiresIn:
          int.tryParse('${data['expires_in'] ?? data['timeout_seconds'] ?? ''}'),
      expiresAt: data['expires_at']?.toString(),
      fromDeliveryManId:
          int.tryParse('${data['from_delivery_man_id'] ?? ''}'),
      toDeliveryManId: int.tryParse('${data['to_delivery_man_id'] ?? ''}'),
      tipAmount: tip,
      deliverymanCharge: charge,
      expectedIncentive: incentive,
      expectedTotalOverride: serverTotal > 0 ? serverTotal : null,
      incentiveLabel: (label != null && label.isNotEmpty) ? label : null,
      incentiveItems: _parseIncentiveItems(data['extra_incentive_items']),
      storeName: data['store_name']?.toString(),
      fromRiderName: data['from_rider_name']?.toString(),
    );
  }

  factory TransferOfferModel.fromPushData(Map<String, dynamic> data) {
    return TransferOfferModel.fromJson(data);
  }

  static List<TransferOfferIncentiveItem> _parseIncentiveItems(dynamic raw) {
    dynamic parsed = raw;
    if (parsed is String && parsed.trim().isNotEmpty) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {
        parsed = [];
      }
    }
    if (parsed is! List) return const [];
    final out = <TransferOfferIncentiveItem>[];
    for (final row in parsed) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final share = double.tryParse(
            '${map['rider_share'] ?? map['delivery_man_share'] ?? map['dm_share'] ?? 0}',
          ) ??
          0;
      if (share <= 0) continue;
      var label = (map['label'] ?? map['name'] ?? '').toString().trim();
      if (label.isEmpty) label = 'extra_incentive';
      out.add(TransferOfferIncentiveItem(label: label, riderShare: share));
    }
    return out;
  }

  /// Charge + tip + late fee / extra incentive (same as after-accept earning).
  double get expectedTotal {
    final itemsSum = incentiveItems.fold<double>(
      0,
      (sum, item) => sum + item.riderShare,
    );
    final incentive =
        itemsSum > expectedIncentive ? itemsSum : expectedIncentive;
    final composed = tipAmount + deliverymanCharge + incentive;
    if (expectedTotalOverride != null &&
        expectedTotalOverride! >= composed - 0.009) {
      return expectedTotalOverride!;
    }
    return composed;
  }
}
