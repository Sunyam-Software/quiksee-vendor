class AssignmentSettingsModel {
  String? mode;
  int? autoAssignTimeoutSeconds;
  double? autoAssignMaxStoreDistanceKm;
  double? autoAssignInstantDistanceKm;
  bool? autoAssignRequireOnline;
  bool? autoAssignRequireAreaMatch;
  bool? autoAssignRequireDriverNearStore;
  int? pollOffersIntervalSeconds;
  int? sendIdleLocationIntervalSeconds;
  bool? autoAssignUseOfferFlow;
  // Directed area transfer (additive; default OFF from backend).
  bool? orderTransferEnabled;
  int? orderTransferTimeoutSeconds;
  String? orderTransferUnlockMode;
  int? orderTransferAfterReachSeconds;
  bool? orderTransferOnlyAfterReachStore;
  bool? orderTransferOnlyAfterPrepOverdue;
  bool? orderTransferBlockAfterPackaging;
  bool? orderTransferBlockAfterPickup;
  bool? orderTransferBlockOutForDelivery;
  int? orderTransferMaxAttempts;

  AssignmentSettingsModel({
    this.mode,
    this.autoAssignTimeoutSeconds,
    this.autoAssignMaxStoreDistanceKm,
    this.autoAssignInstantDistanceKm,
    this.autoAssignRequireOnline,
    this.autoAssignRequireAreaMatch,
    this.autoAssignRequireDriverNearStore,
    this.pollOffersIntervalSeconds,
    this.sendIdleLocationIntervalSeconds,
    this.autoAssignUseOfferFlow,
    this.orderTransferEnabled,
    this.orderTransferTimeoutSeconds,
    this.orderTransferUnlockMode,
    this.orderTransferAfterReachSeconds,
    this.orderTransferOnlyAfterReachStore,
    this.orderTransferOnlyAfterPrepOverdue,
    this.orderTransferBlockAfterPackaging,
    this.orderTransferBlockAfterPickup,
    this.orderTransferBlockOutForDelivery,
    this.orderTransferMaxAttempts,
  });

  bool get isManualMode => mode == 'manual';
  bool get isAutoMode => mode == 'auto' || mode == 'hybrid';

  /// Driver must accept offer/sheet before order appears in active list.
  bool get requiresDriverAcceptance =>
      isManualMode || autoAssignUseOfferFlow == true;

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value == true || value == 1 || value == '1') return true;
    if (value == false || value == 0 || value == '0') return false;
    return fallback;
  }

  factory AssignmentSettingsModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      try {
        return value.toDouble();
      } catch (_) {
        return double.tryParse(value.toString());
      }
    }

    return AssignmentSettingsModel(
      mode: json['mode']?.toString(),
      autoAssignTimeoutSeconds:
          int.tryParse('${json['auto_assign_timeout_seconds']}'),
      autoAssignMaxStoreDistanceKm:
          toDouble(json['auto_assign_max_store_distance_km']),
      autoAssignInstantDistanceKm:
          toDouble(json['auto_assign_instant_distance_km']),
      autoAssignRequireOnline: json['auto_assign_require_online'] == true,
      autoAssignRequireAreaMatch:
          json['auto_assign_require_area_match'] == true,
      autoAssignRequireDriverNearStore:
          json['auto_assign_require_driver_near_store'] == true,
      pollOffersIntervalSeconds:
          int.tryParse('${json['poll_offers_interval_seconds']}') ?? 15,
      sendIdleLocationIntervalSeconds:
          int.tryParse('${json['send_idle_location_interval_seconds']}') ?? 30,
      autoAssignUseOfferFlow: json['auto_assign_use_offer_flow'] == true,
      orderTransferEnabled: _asBool(json['order_transfer_enabled']),
      orderTransferTimeoutSeconds:
          int.tryParse('${json['order_transfer_timeout_seconds']}') ?? 40,
      orderTransferUnlockMode:
          json['order_transfer_unlock_mode']?.toString() ?? 'after_reach_seconds',
      orderTransferAfterReachSeconds:
          int.tryParse('${json['order_transfer_after_reach_seconds']}') ?? 40,
      orderTransferOnlyAfterReachStore:
          _asBool(json['order_transfer_only_after_reach_store'], fallback: true),
      orderTransferOnlyAfterPrepOverdue: _asBool(
          json['order_transfer_only_after_prep_overdue'],
          fallback: false),
      orderTransferBlockAfterPackaging: _asBool(
          json['order_transfer_block_after_packaging'],
          fallback: true),
      orderTransferBlockAfterPickup: _asBool(
          json['order_transfer_block_after_pickup'],
          fallback: true),
      orderTransferBlockOutForDelivery: _asBool(
          json['order_transfer_block_out_for_delivery'],
          fallback: true),
      orderTransferMaxAttempts:
          int.tryParse('${json['order_transfer_max_attempts']}') ?? 3,
    );
  }
}

class DeliveryAreasSummary {
  int? zoneCount;
  int? areaRowCount;
  bool? hasAssignmentCircle;
  bool? servesAllAreas;

  DeliveryAreasSummary({
    this.zoneCount,
    this.areaRowCount,
    this.hasAssignmentCircle,
    this.servesAllAreas,
  });

  factory DeliveryAreasSummary.fromJson(Map<String, dynamic> json) {
    return DeliveryAreasSummary(
      zoneCount: int.tryParse('${json['zone_count']}'),
      areaRowCount: int.tryParse('${json['area_row_count']}'),
      hasAssignmentCircle: json['has_assignment_circle'] == true,
      servesAllAreas: json['serves_all_areas'] == true,
    );
  }
}
