import 'package:quiksee/features/assignment/domain/models/assignment_settings_model.dart';
import 'package:quiksee/features/distance_payment/domain/models/delivery_distance_info_model.dart';
import 'package:quiksee/features/order/domain/models/scheduled_delivery_info.dart';
import 'package:get/get.dart';

class AssignmentOfferModel {
  int? offerId;
  int? orderId;
  int? attemptNumber;
  double? distanceToStoreKm;
  int? secondsRemaining;
  double? orderAmount;
  String? paymentStatus;
  String? orderStatus;
  String? storeName;
  String? storeAddress;
  String? customerName;
  String? customerPhone;
  String? deliveryAddress;
  String? deliveryCity;
  String? deliveryArea;
  String? deliveryZip;
  String? deliveryLatitude;
  String? deliveryLongitude;
  DeliveryDistanceInfo? deliveryDistanceInfo;
  bool isScheduledOrder;
  ScheduledDeliveryInfo? scheduledDelivery;
  bool isCombinedCheckout;
  String? combinedLabel;
  List<int>? combinedOrderIds;
  String? combinedOrderIdsLabel;
  List<String>? combinedStoreNames;
  double? combinedTotalAmount;
  String? etaLabel;
  int? etaMinutes;
  String? etaBreakdown;
  double? pendingExtraAmount;

  AssignmentOfferModel({
    this.offerId,
    this.orderId,
    this.attemptNumber,
    this.distanceToStoreKm,
    this.secondsRemaining,
    this.orderAmount,
    this.paymentStatus,
    this.orderStatus,
    this.storeName,
    this.storeAddress,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryArea,
    this.deliveryZip,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryDistanceInfo,
    this.isScheduledOrder = false,
    this.scheduledDelivery,
    this.isCombinedCheckout = false,
    this.combinedLabel,
    this.combinedOrderIds,
    this.combinedOrderIdsLabel,
    this.combinedStoreNames,
    this.combinedTotalAmount,
    this.etaLabel,
    this.etaMinutes,
    this.etaBreakdown,
    this.pendingExtraAmount,
  });

  bool get isScheduled =>
      isScheduledOrder || (scheduledDelivery?.isScheduledDelivery ?? false);

  String get displayOrderTitle {
    if (isCombinedCheckout) {
      final label = combinedOrderIdsLabel?.trim();
      if (label != null && label.isNotEmpty) {
        if (label.startsWith('#')) {
          return '${'order'.tr} $label';
        }
        return '${'order'.tr} #$label';
      }
      if (combinedOrderIds != null && combinedOrderIds!.isNotEmpty) {
        return '${'order'.tr} ${combinedOrderIds!.map((id) => '#$id').join(', ')}';
      }
    }
    return '${'order'.tr} #${orderId ?? '--'}';
  }

  String? get displayStoreName {
    if (isCombinedCheckout && (combinedStoreNames?.isNotEmpty ?? false)) {
      return combinedStoreNames!.join(' + ');
    }
    return storeName;
  }

  double get extraOnOffer {
    return pendingExtraAmount ?? 0;
  }

  double get displayEarning {
    final infoEarning = deliveryDistanceInfo?.displayEarning ?? 0;
    final pending = pendingExtraAmount ?? 0;
    final infoExtra = deliveryDistanceInfo?.extraIncentiveRiderShare ?? 0;
    if (pending > 0 && infoExtra + 0.009 < pending) {
      return infoEarning + pending;
    }
    if (infoEarning > 0) return infoEarning;
    return pending;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    try {
      return value.toDouble();
    } catch (_) {
      return double.tryParse(value.toString());
    }
  }

  static int? _parseSecondsRemaining(dynamic value) {
    if (value == null) return null;
    if (value is int) return value > 0 ? value : null;
    final parsed =
        value is double ? value : double.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed.ceil();
  }

  static String? _nonEmpty(dynamic value) {
    if (value == null) return null;
    if (value is Map) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _readStoreAddress(Map<String, dynamic> json) {
    final direct = _nonEmpty(json['store_address']) ??
        _nonEmpty(json['shop_address']) ??
        _nonEmpty(json['seller_address']);
    if (direct != null) return direct;

    final shop = _asMap(json['shop']) ??
        _asMap(json['store']) ??
        _asMap(json['seller_shop']) ??
        _asMap(_asMap(json['seller'])?['shop']);
    return _nonEmpty(shop?['address']) ?? _nonEmpty(shop?['shop_address']);
  }

  static String? _readStoreName(Map<String, dynamic> json) {
    final direct = _nonEmpty(json['store_name']) ?? _nonEmpty(json['shop_name']);
    if (direct != null) return direct;
    final shop = _asMap(json['shop']) ??
        _asMap(json['store']) ??
        _asMap(json['seller_shop']);
    return _nonEmpty(shop?['name']);
  }

  static String? _readDeliveryAddress(Map<String, dynamic> json) {
    final shipping = _asMap(json['shipping_address']) ??
        _asMap(json['delivery_address']) ??
        _asMap(json['customer_address']);

    final fromShipping = _nonEmpty(shipping?['address']);
    final direct = _nonEmpty(json['delivery_address']) ??
        _nonEmpty(json['customer_address']) ??
        _nonEmpty(json['shipping_address_text']) ??
        _nonEmpty(json['receiver_address']);

    final store = _readStoreAddress(json);
    if (fromShipping != null &&
        (store == null ||
            fromShipping.toLowerCase() != store.toLowerCase())) {
      return fromShipping;
    }
    if (direct != null &&
        (store == null || direct.toLowerCase() != store.toLowerCase())) {
      return direct;
    }
    return fromShipping;
  }

  static String? _readCustomerName(Map<String, dynamic> json) {
    final direct = _nonEmpty(json['customer_name']) ??
        _nonEmpty(json['receiver_name']);
    if (direct != null) return direct;
    final shipping = _asMap(json['shipping_address']);
    return _nonEmpty(shipping?['contact_person_name']);
  }

  static String? _readCustomerPhone(Map<String, dynamic> json) {
    final direct = _nonEmpty(json['customer_phone']);
    if (direct != null) return direct;
    final shipping = _asMap(json['shipping_address']);
    return _nonEmpty(shipping?['phone']);
  }

  factory AssignmentOfferModel.fromJson(Map<String, dynamic> json) {
    final storeAddress = _readStoreAddress(json);
    var deliveryAddress = _readDeliveryAddress(json);
    // Guard: backend sometimes copies store into delivery_address.
    if (deliveryAddress != null &&
        storeAddress != null &&
        deliveryAddress.toLowerCase() == storeAddress.toLowerCase()) {
      deliveryAddress = null;
    }

    return AssignmentOfferModel(
      offerId: int.tryParse('${json['offer_id']}'),
      orderId: int.tryParse('${json['order_id']}'),
      attemptNumber: int.tryParse('${json['attempt_number']}'),
      distanceToStoreKm: _toDouble(json['distance_to_store_km']),
      secondsRemaining: _parseSecondsRemaining(json['seconds_remaining']),
      orderAmount: _toDouble(json['order_amount']),
      paymentStatus: json['payment_status']?.toString(),
      orderStatus: json['order_status']?.toString(),
      storeName: _readStoreName(json),
      storeAddress: storeAddress,
      customerName: _readCustomerName(json),
      customerPhone: _readCustomerPhone(json),
      deliveryAddress: deliveryAddress,
      deliveryCity: _nonEmpty(json['delivery_city']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['city']),
      deliveryArea: _nonEmpty(json['delivery_area']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['area']),
      deliveryZip: _nonEmpty(json['delivery_zip']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['zip']),
      deliveryLatitude: _nonEmpty(json['delivery_latitude']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['latitude']),
      deliveryLongitude: _nonEmpty(json['delivery_longitude']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['longitude']),
      deliveryDistanceInfo: json['delivery_distance_info'] is Map
          ? DeliveryDistanceInfo.fromJson(
              Map<String, dynamic>.from(json['delivery_distance_info']))
          : null,
      isScheduledOrder: json['is_scheduled_order'] == true ||
          json['is_scheduled_order']?.toString() == '1' ||
          json['is_scheduled_order']?.toString().toLowerCase() == 'true',
      scheduledDelivery: json['scheduled_delivery'] is Map
          ? ScheduledDeliveryInfo.fromJson(
              Map<String, dynamic>.from(json['scheduled_delivery']))
          : null,
      isCombinedCheckout: json['is_combined_checkout'] == true ||
          json['is_combined_checkout']?.toString() == '1' ||
          json['is_combined_checkout']?.toString().toLowerCase() == 'true',
      combinedLabel: json['combined_label']?.toString(),
      combinedOrderIds: (json['combined_order_ids'] as List?)
          ?.map((value) => int.tryParse('$value'))
          .whereType<int>()
          .toList(),
      combinedOrderIdsLabel: json['combined_order_ids_label']?.toString(),
      combinedStoreNames: (json['combined_store_names'] as List?)
          ?.map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      combinedTotalAmount: _toDouble(json['combined_total_amount']),
      etaLabel: json['eta_label']?.toString(),
      etaMinutes: int.tryParse('${json['eta_minutes'] ?? ''}'),
      etaBreakdown: json['eta_breakdown']?.toString(),
      pendingExtraAmount: _toDouble(
        json['pending_extra_amount'] ?? json['extra_amount'],
      ),
    );
  }

  /// Build a usable offer instantly from FCM push data (before pending-offers API).
  factory AssignmentOfferModel.fromPushData(Map<String, dynamic> data) {
    Map<String, dynamic> json = Map<String, dynamic>.from(data);
    final nested = data['offer'];
    if (nested is Map) {
      json = {...json, ...Map<String, dynamic>.from(nested)};
    }

    DeliveryDistanceInfo? distanceInfo;
    final extra = _toDouble(
          json['pending_extra_amount'] ?? json['extra_amount'],
        ) ??
        0;
    if (json['delivery_distance_info'] is Map) {
      distanceInfo = DeliveryDistanceInfo.fromJson(
        Map<String, dynamic>.from(json['delivery_distance_info']),
      );
    } else {
      final earning = _toDouble(
            json['delivery_man_total_earning'] ??
                json['earning'] ??
                json['delivery_man_earning'] ??
                json['your_earning'],
          ) ??
          0;
      final distance = _toDouble(
            json['delivery_distance_km'] ??
                json['distance_km'] ??
                json['distance'],
          ) ??
          0;
      if (earning > 0 || distance > 0 || extra > 0) {
        distanceInfo = DeliveryDistanceInfo(
          distanceKm: distance > 0 ? distance : null,
          deliveryDistanceKm: distance > 0 ? distance : null,
          deliveryManEarning: earning > 0 ? earning : null,
          deliveryManTotalEarning: (earning + extra) > 0 ? earning + extra : null,
          estimatedEarning: (earning + extra) > 0 ? earning + extra : null,
          extraIncentiveRiderShare: extra > 0 ? extra : null,
          extraIncentiveLabel: extra > 0 ? 'Manual extra' : null,
        );
      }
    }

    final timeout = _parseSecondsRemaining(
          json['timeout_seconds'] ?? json['seconds_remaining'],
        ) ??
        30;

    final storeAddress = _readStoreAddress(json);
    var deliveryAddress = _readDeliveryAddress(json);
    if (deliveryAddress != null &&
        storeAddress != null &&
        deliveryAddress.toLowerCase() == storeAddress.toLowerCase()) {
      deliveryAddress = null;
    }

    return AssignmentOfferModel(
      offerId: int.tryParse('${json['offer_id']}'),
      orderId: int.tryParse('${json['order_id']}'),
      attemptNumber: int.tryParse('${json['attempt_number']}'),
      distanceToStoreKm: _toDouble(json['distance_to_store_km']),
      secondsRemaining: timeout,
      orderAmount: _toDouble(json['order_amount']),
      paymentStatus: json['payment_status']?.toString(),
      orderStatus: json['order_status']?.toString(),
      storeName: _readStoreName(json),
      storeAddress: storeAddress,
      customerName: _readCustomerName(json),
      customerPhone: _readCustomerPhone(json),
      deliveryAddress: deliveryAddress,
      deliveryCity: _nonEmpty(json['delivery_city']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['city']),
      deliveryArea: _nonEmpty(json['delivery_area']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['area']),
      deliveryZip: _nonEmpty(json['delivery_zip']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['zip']),
      deliveryLatitude: _nonEmpty(json['delivery_latitude']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['latitude']),
      deliveryLongitude: _nonEmpty(json['delivery_longitude']) ??
          _nonEmpty(_asMap(json['shipping_address'])?['longitude']),
      deliveryDistanceInfo: distanceInfo,
      isScheduledOrder: json['is_scheduled_order'] == true ||
          json['is_scheduled_order']?.toString() == '1' ||
          json['is_scheduled_order']?.toString().toLowerCase() == 'true' ||
          json['order_type']?.toString() == 'scheduled',
      isCombinedCheckout: json['is_combined_checkout'] == true ||
          json['is_combined_checkout']?.toString() == '1' ||
          json['is_combined_checkout']?.toString().toLowerCase() == 'true' ||
          json['is_combined_checkout']?.toString().toLowerCase() == 'yes',
      combinedLabel: json['combined_label']?.toString(),
      combinedOrderIds: (json['combined_order_ids'] as List?)
          ?.map((value) => int.tryParse('$value'))
          .whereType<int>()
          .toList(),
      combinedOrderIdsLabel: json['combined_order_ids_label']?.toString(),
      combinedStoreNames: (json['combined_store_names'] as List?)
          ?.map((value) => value.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      combinedTotalAmount: _toDouble(json['combined_total_amount']),
      etaLabel: json['eta_label']?.toString(),
      etaMinutes: int.tryParse('${json['eta_minutes'] ?? ''}'),
      etaBreakdown: json['eta_breakdown']?.toString(),
      pendingExtraAmount: extra > 0 ? extra : _toDouble(json['pending_extra_amount']),
    );
  }

  /// Copy richer API fields onto this (provisional) offer in-place.
  void mergeFrom(AssignmentOfferModel richer) {
    offerId ??= richer.offerId;
    orderId ??= richer.orderId;
    attemptNumber ??= richer.attemptNumber;
    distanceToStoreKm ??= richer.distanceToStoreKm;
    // Don't yank a live countdown down after the sheet already opened from FCM.
    if (richer.secondsRemaining != null) {
      if (secondsRemaining == null ||
          richer.secondsRemaining! > secondsRemaining!) {
        secondsRemaining = richer.secondsRemaining;
      }
    }
    orderAmount ??= richer.orderAmount;
    paymentStatus ??= richer.paymentStatus;
    orderStatus ??= richer.orderStatus;
    if (richer.storeName != null && richer.storeName!.trim().isNotEmpty) {
      storeName = richer.storeName;
    }
    if (richer.storeAddress != null && richer.storeAddress!.trim().isNotEmpty) {
      storeAddress = richer.storeAddress;
    }
    if (richer.customerName != null && richer.customerName!.trim().isNotEmpty) {
      customerName = richer.customerName;
    }
    customerPhone ??= richer.customerPhone;
    if (richer.deliveryAddress != null &&
        richer.deliveryAddress!.trim().isNotEmpty) {
      deliveryAddress = richer.deliveryAddress;
    }
    deliveryCity ??= richer.deliveryCity;
    deliveryArea ??= richer.deliveryArea;
    deliveryZip ??= richer.deliveryZip;
    deliveryLatitude ??= richer.deliveryLatitude;
    deliveryLongitude ??= richer.deliveryLongitude;
    if (richer.pendingExtraAmount != null &&
        (pendingExtraAmount == null ||
            richer.pendingExtraAmount! > pendingExtraAmount!)) {
      pendingExtraAmount = richer.pendingExtraAmount;
    }
    if (richer.deliveryDistanceInfo != null) {
      final richerEarn = richer.deliveryDistanceInfo!.displayEarning;
      final currentEarn = deliveryDistanceInfo?.displayEarning ?? 0;
      final richerExtra =
          richer.deliveryDistanceInfo!.extraIncentiveRiderShare ?? 0;
      final currentExtra =
          deliveryDistanceInfo?.extraIncentiveRiderShare ?? 0;
      if (deliveryDistanceInfo == null ||
          richerEarn >= currentEarn - 0.009 ||
          richerExtra > currentExtra + 0.009) {
        deliveryDistanceInfo = richer.deliveryDistanceInfo;
      }
    }
    if (richer.isScheduledOrder) isScheduledOrder = true;
    scheduledDelivery ??= richer.scheduledDelivery;
    if (richer.isCombinedCheckout) isCombinedCheckout = true;
    combinedLabel ??= richer.combinedLabel;
    combinedOrderIds ??= richer.combinedOrderIds;
    combinedOrderIdsLabel ??= richer.combinedOrderIdsLabel;
    combinedStoreNames ??= richer.combinedStoreNames;
    combinedTotalAmount ??= richer.combinedTotalAmount;
    etaLabel ??= richer.etaLabel;
    etaMinutes ??= richer.etaMinutes;
    etaBreakdown ??= richer.etaBreakdown;
  }
}

class PendingOffersResponse {
  int? offersCount;
  List<AssignmentOfferModel>? offers;
  AssignmentSettingsModel? settings;
  bool driverBusy;
  int? activeOrderId;
  bool keepCurrentOffer;
  Map<String, dynamic>? assignmentRecovery;

  PendingOffersResponse({
    this.offersCount,
    this.offers,
    this.settings,
    this.driverBusy = false,
    this.activeOrderId,
    this.keepCurrentOffer = false,
    this.assignmentRecovery,
  });

  factory PendingOffersResponse.fromJson(Map<String, dynamic> json) {
    final offersRaw = json['offers'];
    List<AssignmentOfferModel>? offers;
    if (offersRaw is List) {
      offers = offersRaw
          .whereType<Map>()
          .map((e) => AssignmentOfferModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }

    AssignmentSettingsModel? settings;
    if (json['settings'] != null) {
      settings = AssignmentSettingsModel.fromJson(json['settings']);
    } else if (json['auto_assign'] is Map) {
      final autoAssign = Map<String, dynamic>.from(json['auto_assign']);
      if (autoAssign['settings'] != null) {
        settings = AssignmentSettingsModel.fromJson(
          Map<String, dynamic>.from(autoAssign['settings']),
        );
      }
    }

    Map<String, dynamic>? recovery;
    if (json['assignment_recovery'] is Map) {
      recovery = Map<String, dynamic>.from(json['assignment_recovery'] as Map);
    }

    return PendingOffersResponse(
      offersCount: int.tryParse('${json['offers_count'] ?? offers?.length ?? 0}'),
      offers: offers,
      settings: settings,
      driverBusy: json['driver_busy'] == true ||
          json['driver_busy'] == 1 ||
          json['driver_busy'] == '1',
      activeOrderId: int.tryParse('${json['active_order_id'] ?? ''}'),
      keepCurrentOffer: json['keep_current_offer'] == true ||
          json['keep_current_offer'] == 1 ||
          json['keep_current_offer'] == '1',
      assignmentRecovery: recovery,
    );
  }
}
