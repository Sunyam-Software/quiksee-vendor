
import 'package:get/get.dart';
import 'package:quiksee/data/models/image_full_url.dart';
import 'package:quiksee/features/chat/domain/enums/vacation_duration_type.dart';
import 'package:quiksee/features/distance_payment/domain/models/delivery_distance_info_model.dart';
import 'package:quiksee/features/order/domain/models/scheduled_delivery_info.dart';

class OrderModel {
  int? id;
  int? customerId;
  String? customerType;
  String? paymentStatus;
  String? orderStatus;
  String? paymentMethod;
  String? transactionRef;
  double? orderAmount;
  String? createdAt;
  String? updatedAt;
  double? discountAmount;
  String? discountType;
  String? couponCode;
  /// Product/item discount only (payment_info.item_discount).
  double? itemDiscount;
  /// Checkout coupon discount (payment_info.coupon_discount).
  double? couponDiscount;
  /// Extra / vendor discount (payment_info.extra_discount).
  double? extraDiscount;
  int? shippingMethodId;
  double? shippingCost;
  String? orderGroupId;
  String? verificationCode;
  int? sellerId;
  String? sellerIs;
  int? deliveryManId;
  Customer? customer;
  String? orderNote;
  ShippingAddress? billingAddress;
  SellerInfo? sellerInfo;
  String? expectedDate;
  double? deliveryManCharge;
  bool? isPause;
  ShippingAddress? shippingAddress;
  bool? isGuest;
  bool? isShippingFree;
  double? bringChangeAmount;
  String? bringChangeAmountCurrency;
  double? referAndEarnDiscount;
  double? totalTaxAmount;
  String? taxModel;
  String? taxType;
  double? platformFee;
  String? platformFeeFormatted;
  String? platformFeeLabel;
  double? scheduledDeliveryCharge;
  String? scheduledDeliveryChargeFormatted;
  double? extraIncentiveCharge;
  String? extraIncentiveLabel;
  double? extraIncentiveRiderShare;
  List<Map<String, dynamic>>? extraIncentiveItems;
  List<Map<String, dynamic>>? manualExtraCharges;
  DeliveryDistanceInfo? deliveryDistanceInfo;
  double? deliveryManTip;
  String? deliveryManTipFormatted;
  double? deliveryManTotalEarning;
  String? deliveryManTotalEarningFormatted;
  String? tipStatus;
  bool? tipCredited;
  String? tipCreditedAt;
  int? isScheduledDelivery;
  String? scheduledDeliveryDate;
  String? scheduledDeliveryTimeFrom;
  String? scheduledDeliveryTimeTo;
  String? deliveryType;
  ScheduledDeliveryInfo? scheduledDelivery;
  bool isCombinedCheckout = false;
  String? combinedLabel;
  List<int>? combinedOrderIds;
  String? combinedOrderIdsLabel;
  List<String>? combinedStoreNames;
  double? combinedTotalEarning;
  String? combinedTotalEarningFormatted;
  List<OrderModel>? combinedOrders;
  int? pickupSequence;
  String? pickupLabel;
  String? storeName;
  int? pickupSequenceTotal;
  String? dropLabel;
  int? preparationTime;
  String? estimatedReadyAt;
  String? vendorReadyAt;
  int? etaMinutes;
  String? etaLabel;
  String? etaBreakdown;
  int? foodPickupOtpEnabled;
  int? pickupVerificationStatus;
  int? pickupOtpRequired;
  int? canPickup;
  String? pickupVerificationCode;
  String? pickupVerifiedAt;
  int? pickupFromAdminHub;
  String? pickupOtpHint;
  int? storeWaitEnabled;
  int? storeWaitActive;
  String? storeWaitStartedAt;
  String? storeWaitDeadlineAt;
  int? storeWaitRemainingSeconds;
  int? storeWaitOverdue;
  int? storeWaitOverdueSeconds;
  int? storeWaitShowExtra;
  int? storeWaitPacked;
  int? canPoke;
  int? pokeCount;
  int? pokeMax;
  String? nextPokeAt;
  String? storeLastPokeAt;
  int? orderTransferAlreadyDone;
  int? orderTransferLocked;
  int? orderTransferEnabled;
  String? orderTransferUnlockMode;
  int? orderTransferAfterReachSeconds;
  int? orderTransferOnlyAfterPrepOverdue;
  int? orderTransferOnlyAfterReachStore;
  int? orderTransferBlockAfterPackaging;
  int? orderTransferBlockAfterPickup;
  int? orderTransferBlockOutForDelivery;
  int? orderTransferReceived;
  int? orderTransferFromId;
  String? orderTransferFromName;
  int? orderTransferToId;
  String? orderTransferToName;
  String? orderTransferAt;

  OrderModel(
      {this.id,
        this.customerId,
        this.customerType,
        this.paymentStatus,
        this.orderStatus,
        this.paymentMethod,
        this.transactionRef,
        this.orderAmount,
        this.createdAt,
        this.updatedAt,
        this.discountAmount,
        this.discountType,
        this.couponCode,
        this.itemDiscount,
        this.couponDiscount,
        this.extraDiscount,
        this.shippingMethodId,
        this.shippingCost,
        this.orderGroupId,
        this.verificationCode,
        this.sellerId,
        this.sellerIs,
        this.deliveryManId,
        this.customer,
        this.orderNote,
        this.billingAddress,
        this.sellerInfo,
        this.expectedDate,
        this.deliveryManCharge,
        this.isPause,
        this.shippingAddress,
        this.isGuest,
        this.isShippingFree,
        this.bringChangeAmount,
        this.bringChangeAmountCurrency,
        this.referAndEarnDiscount,
        this.totalTaxAmount,
        this.taxModel,
        this.taxType,
        this.platformFee,
        this.platformFeeFormatted,
        this.platformFeeLabel,
        this.scheduledDeliveryCharge,
        this.scheduledDeliveryChargeFormatted,
        this.extraIncentiveCharge,
        this.extraIncentiveLabel,
        this.extraIncentiveRiderShare,
        this.extraIncentiveItems,
        this.manualExtraCharges,
        this.deliveryDistanceInfo,
        this.deliveryManTip,
        this.deliveryManTipFormatted,
        this.deliveryManTotalEarning,
        this.deliveryManTotalEarningFormatted,
        this.tipStatus,
        this.tipCredited,
        this.tipCreditedAt,
        this.isScheduledDelivery,
        this.scheduledDeliveryDate,
        this.scheduledDeliveryTimeFrom,
        this.scheduledDeliveryTimeTo,
        this.deliveryType,
        this.scheduledDelivery,
        this.isCombinedCheckout = false,
        this.combinedLabel,
        this.combinedOrderIds,
        this.combinedOrderIdsLabel,
        this.combinedStoreNames,
        this.combinedTotalEarning,
        this.combinedTotalEarningFormatted,
        this.combinedOrders,
      });

  OrderModel.fromJson(Map<String, dynamic> json) {
    id = int.tryParse('${json['id'] ?? json['order_id'] ?? ''}');
    customerId = int.tryParse('${json['customer_id'] ?? ''}');
    customerType = json['customer_type']?.toString();
    paymentStatus = json['payment_status']?.toString();
    orderStatus = json['order_status']?.toString();
    paymentMethod = json['payment_method']?.toString();
    transactionRef = json['transaction_ref']?.toString();
    orderAmount = _toDouble(json['order_amount']) ?? 0;
    final collectCandidates = <double?>[
      orderAmount,
      _toDouble(json['amount_to_collect']),
      _toDouble(json['cash_to_collect']),
      _toDouble(json['collectable_amount']),
      _toDouble(json['total_amount']),
      _toDouble(json['grand_total']),
    ];
    var bestCollect = 0.0;
    for (final v in collectCandidates) {
      if (v != null && v > bestCollect) bestCollect = v;
    }
    if (bestCollect > 0) {
      orderAmount = bestCollect;
    }
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    discountAmount = _toDouble(json['discount_amount']) ?? 0;
    discountType = json['discount_type']?.toString();
    couponCode = json['coupon_code']?.toString();
    shippingMethodId = int.tryParse('${json['shipping_method_id'] ?? ''}');
    shippingCost = _toDouble(json['shipping_cost']) ?? 0;
    orderGroupId = json['order_group_id']?.toString();
    verificationCode = json['verification_code']?.toString();
    sellerId = int.tryParse('${json['seller_id'] ?? ''}');
    sellerIs = json['seller_is']?.toString();
    deliveryManId = int.tryParse('${json['delivery_man_id'] ?? ''}');
    customer = json['customer'] is Map
        ? Customer.fromJson(Map<String, dynamic>.from(json['customer']))
        : null;

    orderNote = json['order_note']?.toString();
    billingAddress = json['billing_address_data'] is Map
        ? ShippingAddress.fromJson(
            Map<String, dynamic>.from(json['billing_address_data']))
        : null;
    sellerInfo = json['seller'] is Map
        ? SellerInfo.fromJson(Map<String, dynamic>.from(json['seller']))
        : null;
    if (json['expected_delivery_date'] != null) {
      expectedDate = json['expected_delivery_date']?.toString();
    }

    if (json['deliveryman_charge'] != null) {
      deliveryManCharge = _toDouble(json['deliveryman_charge']);
    }
    if(json['is_pause'] != null){
      isPause = json['is_pause'];
    }

    if(json['is_guest'] != null){
      try{
        isGuest = json['is_guest'];
      }catch(e){
        isGuest = json['is_guest']??false;
      }
    }

    shippingAddress = _parseShippingAddress(json['shipping_address']);
    _preferCustomerDeliveryAddress(json);

    isShippingFree = json['is_shipping_free'] ?? false;
    bringChangeAmount = double.tryParse('${json['bring_change_amount']}');
    bringChangeAmountCurrency = json['bring_change_amount_currency'];
    referAndEarnDiscount = double.tryParse(json['refer_and_earn_discount'].toString());
    totalTaxAmount = double.tryParse(json['total_tax_amount'].toString());
    taxModel = json['tax_model']?.toString();
    taxType = json['tax_type']?.toString();
    platformFee = _toDouble(json['platform_fee']);
    platformFeeFormatted = json['platform_fee_formatted']?.toString();
    platformFeeLabel = json['platform_fee_label']?.toString();
    scheduledDeliveryCharge =
        _toDouble(json['scheduled_delivery_charge']);
    scheduledDeliveryChargeFormatted =
        json['scheduled_delivery_charge_formatted']?.toString();
    extraIncentiveCharge = _toDouble(json['extra_incentive_charge']);
    extraIncentiveLabel = json['extra_incentive_label']?.toString();
    extraIncentiveRiderShare = _toDouble(json['extra_incentive_rider_share']);
    if (json['extra_incentive_items'] is List) {
      extraIncentiveItems = (json['extra_incentive_items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (json['manual_extra_charges'] is List) {
      manualExtraCharges = (json['manual_extra_charges'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (json['payment_info'] is Map) {
      final pi = Map<String, dynamic>.from(json['payment_info'] as Map);
      final piCharge = _toDouble(pi['extra_incentive_charge']);
      if (piCharge != null && piCharge > 0) {
        if (extraIncentiveCharge == null || extraIncentiveCharge! < piCharge) {
          extraIncentiveCharge = piCharge;
        }
      }
      extraIncentiveLabel ??= pi['extra_incentive_label']?.toString();
      final piRider = _toDouble(pi['extra_incentive_rider_share']);
      if (piRider != null && piRider > 0) {
        if (extraIncentiveRiderShare == null ||
            extraIncentiveRiderShare! < piRider) {
          extraIncentiveRiderShare = piRider;
        }
      }
      if ((extraIncentiveItems == null || extraIncentiveItems!.isEmpty) &&
          pi['extra_incentive_items'] is List) {
        extraIncentiveItems = (pi['extra_incentive_items'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if ((manualExtraCharges == null || manualExtraCharges!.isEmpty) &&
          pi['manual_extra_charges'] is List) {
        manualExtraCharges = (pi['manual_extra_charges'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    if (json['delivery_distance_info'] is Map) {
      deliveryDistanceInfo = DeliveryDistanceInfo.fromJson(
        Map<String, dynamic>.from(json['delivery_distance_info']),
      );
      extraIncentiveRiderShare ??=
          deliveryDistanceInfo?.extraIncentiveRiderShare;
      extraIncentiveLabel ??= deliveryDistanceInfo?.extraIncentiveLabel;
      deliveryManTotalEarning ??=
          deliveryDistanceInfo?.deliveryManTotalEarning;
    }
    deliveryManTip = _toDouble(json['delivery_man_tip']);
    deliveryManTipFormatted = json['delivery_man_tip_formatted']?.toString();
    deliveryManTotalEarning =
        _toDouble(json['delivery_man_total_earning']) ?? deliveryManTotalEarning;
    deliveryManTotalEarningFormatted =
        json['delivery_man_total_earning_formatted']?.toString() ??
            (deliveryManTotalEarning != null
                ? deliveryManTotalEarning!.toStringAsFixed(2)
                : null);
    tipStatus = json['tip_status']?.toString();
    tipCredited = json['tip_credited'] == true;
    tipCreditedAt = json['tip_credited_at']?.toString();
    isScheduledDelivery = _parseScheduledFlag(json['is_scheduled_delivery']) ??
        _parseScheduledFlag(json['is_scheduled_order']);
    scheduledDeliveryDate = json['scheduled_delivery_date']?.toString();
    scheduledDeliveryTimeFrom =
        json['scheduled_delivery_time_from']?.toString();
    scheduledDeliveryTimeTo = json['scheduled_delivery_time_to']?.toString();
    deliveryType = json['delivery_type']?.toString();
    if (json['scheduled_delivery'] is Map) {
      scheduledDelivery = ScheduledDeliveryInfo.fromJson(
        Map<String, dynamic>.from(json['scheduled_delivery']),
      );
      if (isScheduledDelivery != 1 &&
          (scheduledDelivery?.isScheduledDelivery ?? false)) {
        isScheduledDelivery = 1;
      }
      if ((scheduledDeliveryCharge == null || scheduledDeliveryCharge! <= 0) &&
          (scheduledDelivery?.extraCharge ?? 0) > 0) {
        scheduledDeliveryCharge = scheduledDelivery!.extraCharge;
        scheduledDeliveryChargeFormatted ??=
            scheduledDelivery!.extraChargeFormatted;
      }
    }

    // Top-level coupon / item discount fields (if API sends them).
    itemDiscount = _toDouble(json['item_discount']);
    couponDiscount = _toDouble(json['coupon_discount']);
    extraDiscount = _toDouble(json['extra_discount']);

    // Fill missing fee/tax/total/discounts from payment_info (synced by backend).
    if (json['payment_info'] is Map) {
      final pi = Map<String, dynamic>.from(json['payment_info'] as Map);
      totalTaxAmount ??= _toDouble(pi['tax']);
      platformFee ??= _toDouble(pi['platform_fee']);
      deliveryManTip ??= _toDouble(pi['delivery_man_tip']);
      scheduledDeliveryCharge ??=
          _toDouble(pi['scheduled_delivery_charge']);
      itemDiscount ??= _toDouble(pi['item_discount']);
      couponDiscount ??= _toDouble(pi['coupon_discount']);
      extraDiscount ??= _toDouble(pi['extra_discount']);
      referAndEarnDiscount ??= _toDouble(pi['refer_and_earn_discount']);
      // Prefer full discount breakdown total when present.
      final piDiscount = _toDouble(pi['discount']);
      if (piDiscount != null && piDiscount > 0) {
        discountAmount = piDiscount;
      }
      if ((shippingCost ?? 0) <= 0) {
        shippingCost = _toDouble(pi['delivery_cost']) ?? shippingCost;
      }
      final piTotal = _toDouble(pi['total_amount']) ??
          _toDouble(pi['order_amount']) ??
          _toDouble(pi['collectable_amount']) ??
          _toDouble(pi['amount_to_collect']);
      if (piTotal != null && piTotal > 0 && piTotal >= (orderAmount ?? 0)) {
        orderAmount = piTotal;
      }
      final piTotalStr = pi['total_amount_str']?.toString() ??
          pi['order_amount_str']?.toString() ??
          pi['amount_to_collect_str']?.toString();
      final parsedStr = double.tryParse(piTotalStr ?? '');
      if (parsedStr != null &&
          parsedStr > 0 &&
          parsedStr >= (orderAmount ?? 0)) {
        orderAmount = parsedStr;
      }
    }

    // Raw DB often stores coupon on discount_amount only (item discount is on lines).
    if ((couponDiscount ?? 0) <= 0 && (discountAmount ?? 0) > 0) {
      final item = itemDiscount ?? 0;
      final orderDisc = discountAmount ?? 0;
      final type = (discountType ?? '').toLowerCase();
      if (type == 'coupon_discount' ||
          (couponCode != null && couponCode!.isNotEmpty && couponCode != '0')) {
        if (orderDisc > item + 0.009) {
          couponDiscount = _roundMoney(orderDisc - item);
        } else if (item <= 0) {
          couponDiscount = orderDisc;
        }
      } else if (orderDisc > item + 0.009) {
        couponDiscount = _roundMoney(orderDisc - item);
      }
    }

    isCombinedCheckout = json['is_combined_checkout'] == true ||
        json['is_combined_checkout']?.toString() == '1' ||
        json['is_combined_checkout']?.toString().toLowerCase() == 'true';
    combinedLabel = json['combined_label']?.toString();
    combinedOrderIds = (json['combined_order_ids'] as List?)
        ?.map((value) => int.tryParse('$value'))
        .whereType<int>()
        .toList();
    combinedOrderIdsLabel = json['combined_order_ids_label']?.toString();
    combinedStoreNames = (json['combined_store_names'] as List?)
        ?.map((value) => value.toString())
        .where((value) => value.trim().isNotEmpty)
        .toList();
    combinedTotalEarning = _toDouble(json['combined_total_earning']);
    combinedTotalEarningFormatted =
        json['combined_total_earning_formatted']?.toString();
    if (json['combined_orders'] is List) {
      combinedOrders = (json['combined_orders'] as List)
          .whereType<Map>()
          .map((raw) => OrderModel.fromJson(Map<String, dynamic>.from(raw)))
          .toList();
    }
    pickupSequence = int.tryParse('${json['pickup_sequence'] ?? ''}');
    pickupLabel = json['pickup_label']?.toString();
    storeName = json['store_name']?.toString();
    pickupSequenceTotal = int.tryParse('${json['pickup_sequence_total'] ?? ''}');
    dropLabel = json['drop_label']?.toString();
    preparationTime = int.tryParse('${json['preparation_time'] ?? ''}');
    estimatedReadyAt = json['estimated_ready_at']?.toString();
    vendorReadyAt = json['vendor_ready_at']?.toString();
    etaMinutes = int.tryParse('${json['eta_minutes'] ?? ''}');
    etaLabel = json['eta_label']?.toString();
    etaBreakdown = json['eta_breakdown']?.toString();
    foodPickupOtpEnabled = int.tryParse('${json['food_pickup_otp_enabled'] ?? ''}');
    pickupVerificationStatus =
        int.tryParse('${json['pickup_verification_status'] ?? ''}');
    pickupOtpRequired = int.tryParse('${json['pickup_otp_required'] ?? ''}');
    canPickup = int.tryParse('${json['can_pickup'] ?? ''}');
    final rawCode = json['pickup_verification_code']?.toString();
    pickupVerificationCode =
        (rawCode != null && rawCode.isNotEmpty && rawCode != 'null')
            ? rawCode
            : null;
    pickupVerifiedAt = json['pickup_verified_at']?.toString();
    if (pickupVerifiedAt == 'null') pickupVerifiedAt = null;
    pickupFromAdminHub = int.tryParse('${json['pickup_from_admin_hub'] ?? ''}');
    pickupOtpHint = json['pickup_otp_hint']?.toString();
    if (pickupOtpHint == 'null' || pickupOtpHint == '') pickupOtpHint = null;
    final holdRaw = json['scheduled_admin_hold'];
    if (pickupFromAdminHub != 1 &&
        (holdRaw == true ||
            holdRaw == 1 ||
            holdRaw == '1' ||
            (scheduledDelivery?.scheduledAdminHold ?? false))) {
      pickupFromAdminHub = 1;
    }
    storeWaitEnabled = int.tryParse('${json['store_wait_enabled'] ?? ''}');
    storeWaitActive = int.tryParse('${json['store_wait_active'] ?? ''}');
    storeWaitStartedAt = json['store_wait_started_at']?.toString();
    if (storeWaitStartedAt == 'null') storeWaitStartedAt = null;
    storeWaitDeadlineAt = json['store_wait_deadline_at']?.toString();
    if (storeWaitDeadlineAt == 'null') storeWaitDeadlineAt = null;
    storeWaitRemainingSeconds =
        int.tryParse('${json['store_wait_remaining_seconds'] ?? ''}');
    storeWaitOverdue = int.tryParse('${json['store_wait_overdue'] ?? ''}');
    storeWaitOverdueSeconds =
        int.tryParse('${json['store_wait_overdue_seconds'] ?? ''}');
    storeWaitShowExtra =
        int.tryParse('${json['store_wait_show_extra'] ?? ''}');
    storeWaitPacked = int.tryParse('${json['store_wait_packed'] ?? ''}');
    canPoke = int.tryParse('${json['can_poke'] ?? ''}');
    pokeCount = int.tryParse('${json['poke_count'] ?? ''}');
    pokeMax = int.tryParse('${json['poke_max'] ?? ''}');
    nextPokeAt = json['next_poke_at']?.toString();
    if (nextPokeAt == 'null') nextPokeAt = null;
    storeLastPokeAt = json['store_last_poke_at']?.toString();
    if (storeLastPokeAt == 'null') storeLastPokeAt = null;
    orderTransferAlreadyDone =
        int.tryParse('${json['order_transfer_already_done'] ?? ''}');
    orderTransferLocked =
        int.tryParse('${json['order_transfer_locked'] ?? ''}');
    orderTransferEnabled =
        int.tryParse('${json['order_transfer_enabled'] ?? ''}');
    orderTransferUnlockMode =
        json['order_transfer_unlock_mode']?.toString();
    if (orderTransferUnlockMode == 'null') orderTransferUnlockMode = null;
    orderTransferAfterReachSeconds =
        int.tryParse('${json['order_transfer_after_reach_seconds'] ?? ''}');
    orderTransferOnlyAfterPrepOverdue =
        int.tryParse('${json['order_transfer_only_after_prep_overdue'] ?? ''}');
    orderTransferOnlyAfterReachStore =
        int.tryParse('${json['order_transfer_only_after_reach_store'] ?? ''}');
    orderTransferBlockAfterPackaging =
        int.tryParse('${json['order_transfer_block_after_packaging'] ?? ''}');
    orderTransferBlockAfterPickup =
        int.tryParse('${json['order_transfer_block_after_pickup'] ?? ''}');
    orderTransferBlockOutForDelivery =
        int.tryParse('${json['order_transfer_block_out_for_delivery'] ?? ''}');
    orderTransferReceived =
        int.tryParse('${json['order_transfer_received'] ?? ''}');
    orderTransferFromId =
        int.tryParse('${json['order_transfer_from_id'] ?? ''}');
    orderTransferFromName = json['order_transfer_from_name']?.toString();
    if (orderTransferFromName == 'null') orderTransferFromName = null;
    orderTransferToId = int.tryParse('${json['order_transfer_to_id'] ?? ''}');
    orderTransferToName = json['order_transfer_to_name']?.toString();
    if (orderTransferToName == 'null') orderTransferToName = null;
    orderTransferAt = json['order_transfer_at']?.toString();
    if (orderTransferAt == 'null') orderTransferAt = null;
  }

  static OrderModel mergeCombinedGroup(List<OrderModel> siblings) {
    final sorted = List<OrderModel>.from(siblings)
      ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final lead = sorted.first;

    final storeNames = sorted
        .map((order) => order.sellerInfo?.shop?.name ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();
    final combinedEarning =
        sorted.fold<double>(0, (sum, order) => sum + order.effectiveDeliveryEarning);

    lead.isCombinedCheckout = true;
    lead.combinedLabel = 'Combine';
    lead.combinedOrderIds = sorted.map((order) => order.id).whereType<int>().toList();
    lead.combinedOrderIdsLabel =
        sorted.map((order) => '#${order.id}').join(', ');
    lead.combinedStoreNames = storeNames;
    lead.combinedTotalEarning = combinedEarning;
    lead.combinedTotalEarningFormatted = combinedEarning.toStringAsFixed(2);
    lead.deliveryManTotalEarning = combinedEarning;
    lead.deliveryManTotalEarningFormatted = combinedEarning.toStringAsFixed(2);
    lead.combinedOrders = sorted;
    return lead;
  }

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
    return '${'order'.tr} #${id ?? '--'}';
  }

  String? get displayStoreName {
    if (isCombinedCheckout && (combinedStoreNames?.isNotEmpty ?? false)) {
      return combinedStoreNames!.join(' + ');
    }
    return sellerInfo?.shop?.name;
  }

  String? get storeAddressText {
    final address = sellerInfo?.shop?.address?.trim();
    return (address != null && address.isNotEmpty) ? address : null;
  }

  /// Alias used by GPS reach-restaurant fallback.
  String? get resolvedStoreAddress => storeAddressText;

  String? get customerDeliveryAddressText {
    return resolvedCustomerShipping?.address?.trim().isNotEmpty == true
        ? resolvedCustomerShipping!.address!.trim()
        : null;
  }

  ShippingAddress? get resolvedCustomerShipping {
    final store = storeAddressText;
    final ship = shippingAddress;
    if (ship != null &&
        (ship.address?.trim().isNotEmpty ?? false) &&
        !_isSameAddress(ship.address, store)) {
      return ship;
    }
    final bill = billingAddress;
    if (bill != null &&
        (bill.address?.trim().isNotEmpty ?? false) &&
        !_isSameAddress(bill.address, store)) {
      return bill;
    }
    if (ship != null && _isSameAddress(ship.address, store)) {
      return null;
    }
    return ship;
  }

  static ShippingAddress? _parseShippingAddress(dynamic raw) {
    if (raw is Map) {
      return ShippingAddress.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return ShippingAddress(address: raw.trim());
    }
    return null;
  }

  void _preferCustomerDeliveryAddress(Map<String, dynamic> json) {
    final store = storeAddressText ??
        _nonEmptyString(json['store_address']) ??
        _nonEmptyString(_asMap(json['store'])?['address']) ??
        _nonEmptyString(_asMap(_asMap(json['seller'])?['shop'])?['address']);

    final flatDelivery = _nonEmptyString(json['delivery_address']) ??
        _nonEmptyString(json['customer_address']) ??
        _nonEmptyString(json['receiver_address']) ??
        _nonEmptyString(json['shipping_address_text']);

    final shippingLooksLikeStore =
        _isSameAddress(shippingAddress?.address, store);
    final flatLooksLikeStore = _isSameAddress(flatDelivery, store);

    if (flatDelivery != null &&
        !flatLooksLikeStore &&
        (shippingAddress?.address == null ||
            shippingAddress!.address!.trim().isEmpty ||
            shippingLooksLikeStore)) {
      shippingAddress ??= ShippingAddress(
        contactPersonName: _nonEmptyString(json['customer_name']),
        phone: _nonEmptyString(json['customer_phone']),
      );
      shippingAddress!.address = flatDelivery;
      shippingAddress!.latitude ??=
          _nonEmptyString(json['delivery_latitude'])?.toString();
      shippingAddress!.longitude ??=
          _nonEmptyString(json['delivery_longitude'])?.toString();
      shippingAddress!.city ??= _nonEmptyString(json['delivery_city']);
      shippingAddress!.area ??= _nonEmptyString(json['delivery_area']);
      shippingAddress!.zip ??= _nonEmptyString(json['delivery_zip'])?.toString();
    }

    // Still store-like → try billing (often the real drop-off when shipping is wrong).
    if (_isSameAddress(shippingAddress?.address, store) &&
        billingAddress?.address != null &&
        !_isSameAddress(billingAddress!.address, store)) {
      shippingAddress ??= ShippingAddress();
      shippingAddress!.address = billingAddress!.address;
      shippingAddress!.latitude ??= billingAddress!.latitude;
      shippingAddress!.longitude ??= billingAddress!.longitude;
      shippingAddress!.city ??= billingAddress!.city;
      shippingAddress!.area ??= billingAddress!.area;
      shippingAddress!.zip ??= billingAddress!.zip;
      shippingAddress!.state ??= billingAddress!.state;
      shippingAddress!.contactPersonName ??= billingAddress!.contactPersonName;
      shippingAddress!.phone ??= billingAddress!.phone;
    }
  }

  static bool _isSameAddress(String? a, String? b) {
    final left = _normalizeAddress(a);
    final right = _normalizeAddress(b);
    if (left.isEmpty || right.isEmpty) return false;
    return left == right;
  }

  static String _normalizeAddress(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(',', ' ')
        .trim();
  }

  static String? _nonEmptyString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int? _parseScheduledFlag(dynamic raw) {
    if (raw == true || raw == 1 || raw == '1') return 1;
    if (raw == false || raw == 0 || raw == '0') return 0;
    return int.tryParse('$raw');
  }

  /// Night/admin-hold: pickup is hub staff, not the vendor shop.
  bool get isAdminHubPickup =>
      pickupFromAdminHub == 1 ||
      (scheduledDelivery?.scheduledAdminHold ?? false);

  bool get isAtStoreForPickupOtp {
    final status = (orderStatus ?? '').toLowerCase();
    if (status == 'reached_restaurant' || status == 'processing') {
      return true;
    }
    final started = (storeWaitStartedAt ?? '').trim();
    return started.isNotEmpty &&
        started != 'null' &&
        started != '0000-00-00 00:00:00';
  }

  bool get isScheduledDeliveryOrder =>
      isScheduledDelivery == 1 ||
      deliveryType == 'scheduled' ||
      deliveryType == 'scheduled_delivery' ||
      (scheduledDelivery?.isScheduledDelivery ?? false) ||
      _hasScheduledSlotFields ||
      (scheduledDelivery?.label?.isNotEmpty ?? false);

  bool get _hasScheduledSlotFields =>
      (scheduledDeliveryDate?.isNotEmpty ?? false) &&
      (scheduledDeliveryTimeFrom?.isNotEmpty ?? false);

  String? get scheduledDeliveryDisplayLabel {
    final selection = scheduledDelivery;
    if (selection != null && (selection.label?.isNotEmpty ?? false)) {
      return selection.label;
    }
    if (!isScheduledDeliveryOrder) return null;
    if (scheduledDeliveryDate != null && scheduledDeliveryDate!.isNotEmpty) {
      final from = formatScheduledDeliveryTime(scheduledDeliveryTimeFrom);
      final to = formatScheduledDeliveryTime(scheduledDeliveryTimeTo);
      if (from != null && to != null) {
        return '$scheduledDeliveryDate • $from - $to';
      }
      return expectedDate ?? scheduledDeliveryDate;
    }
    return expectedDate;
  }

  DateTime? get scheduledSlotStartAt {
    final slotRaw = scheduledDelivery?.slotStartsAt;
    if (slotRaw != null && slotRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(slotRaw);
      if (parsed != null) return parsed.toLocal();
    }
    if (scheduledDeliveryDate != null &&
        scheduledDeliveryDate!.isNotEmpty &&
        scheduledDeliveryTimeFrom != null &&
        scheduledDeliveryTimeFrom!.isNotEmpty) {
      final dateParts = scheduledDeliveryDate!.split('-');
      final timeParts = scheduledDeliveryTimeFrom!.split(':');
      if (dateParts.length >= 3 && timeParts.length >= 2) {
        return DateTime(
          int.tryParse(dateParts[0]) ?? 0,
          int.tryParse(dateParts[1]) ?? 0,
          int.tryParse(dateParts[2]) ?? 0,
          int.tryParse(timeParts[0]) ?? 0,
          int.tryParse(timeParts[1]) ?? 0,
          timeParts.length > 2
              ? int.tryParse(timeParts[2].split('.').first) ?? 0
              : 0,
        );
      }
    }
    return null;
  }

  int? get minutesUntilScheduledSlot {
    final start = scheduledSlotStartAt;
    if (start == null) return null;
    return start.difference(DateTime.now()).inMinutes;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    try {
      return value.toDouble();
    } catch (_) {
      return double.tryParse(value.toString());
    }
  }

  static double _roundMoney(double value) =>
      ((value * 100).round()) / 100.0;

  bool get hasTip => (deliveryManTip ?? 0) > 0;
  bool get isTipPending => tipStatus == 'pending';
  bool get isTipEarned => tipStatus == 'earned';

  double get effectiveDeliveryEarning {
    if (isCombinedCheckout && (combinedTotalEarning ?? 0) > 0) {
      return combinedTotalEarning!;
    }
    if ((deliveryManTotalEarning ?? 0) > 0) {
      return deliveryManTotalEarning!;
    }
    final info = deliveryDistanceInfo;
    if (info != null && info.displayEarning > 0) {
      return info.displayEarning;
    }
    final share = extraIncentiveRiderShare ??
        info?.extraIncentiveRiderShare ??
        0;
    if ((deliveryManCharge ?? 0) > 0) {
      return deliveryManCharge! + (deliveryManTip ?? 0) + share;
    }
    return (deliveryManTip ?? 0) + share;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['customer_id'] = customerId;
    data['customer_type'] = customerType;
    data['payment_status'] = paymentStatus;
    data['order_status'] = orderStatus;
    data['payment_method'] = paymentMethod;
    data['transaction_ref'] = transactionRef;
    data['order_amount'] = orderAmount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['discount_amount'] = discountAmount;
    data['discount_type'] = discountType;
    data['coupon_code'] = couponCode;
    data['shipping_method_id'] = shippingMethodId;
    data['shipping_cost'] = shippingCost;
    data['order_group_id'] = orderGroupId;
    data['verification_code'] = verificationCode;
    data['seller_id'] = sellerId;
    data['seller_is'] = sellerIs;
    data['delivery_man_id'] = deliveryManId;
    if (customer != null) {
      data['customer'] = customer!.toJson();
    }
    data['order_note'] = orderNote;
    data['billing_address_data'] = billingAddress;
    data['expected_delivery_date'] = expectedDate;
    data['deliveryman_charge'] = deliveryManCharge;
    data['is_pause'] = isPause;
    if (sellerInfo != null) {
      data['seller'] = sellerInfo!.toJson();
    }
    if (shippingAddress != null) {
      data['shipping_address'] = shippingAddress!.toJson();
    }
    bringChangeAmount = data['bring_change_amount'];
    bringChangeAmountCurrency = data['bring_change_amount_currency'];
    data['refer_and_earn_discount'] = referAndEarnDiscount;
    data['total_tax_amount'] = totalTaxAmount;
    data['tax_model'] = taxModel;
    data['platform_fee'] = platformFee;
    data['platform_fee_label'] = platformFeeLabel;
    data['scheduled_delivery_charge'] = scheduledDeliveryCharge;
    data['delivery_man_tip'] = deliveryManTip;
    data['extra_incentive_charge'] = extraIncentiveCharge;
    data['extra_incentive_label'] = extraIncentiveLabel;
    data['extra_incentive_rider_share'] = extraIncentiveRiderShare;
    data['extra_incentive_items'] = extraIncentiveItems;
    data['manual_extra_charges'] = manualExtraCharges;
    data['item_discount'] = itemDiscount;
    data['coupon_discount'] = couponDiscount;
    data['extra_discount'] = extraDiscount;
    return data;
  }
}

class ShippingAddress {
  int? id;
  String? customerId;
  String? contactPersonName;
  String? addressType;
  String? address;
  String? area;
  String? city;
  String? zip;
  String? phone;
  String? createdAt;
  String? updatedAt;
  String? state;
  String? country;
  String? latitude;
  String? longitude;


  ShippingAddress(
      {this.id,
        this.customerId,
        this.contactPersonName,
        this.addressType,
        this.address,
        this.area,
        this.city,
        this.zip,
        this.phone,
        this.createdAt,
        this.updatedAt,
        this.state,
        this.country,
        this.latitude,
        this.longitude
      });

  ShippingAddress.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id']?.toString();
    contactPersonName = json['contact_person_name'];
    addressType = json['address_type'];
    if(json['address']!=null){
      address = json['address'];
    }
    area = json['area']?.toString();
    city = json['city'];
    zip = json['zip'];
    phone = json['phone'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    state = json['state'];
    country = json['country'];
    latitude = json['latitude']?.toString();
    longitude = json['longitude']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['customer_id'] = customerId;
    data['contact_person_name'] = contactPersonName;
    data['address_type'] = addressType;
    data['address'] = address;
    data['area'] = area;
    data['city'] = city;
    data['zip'] = zip;
    data['phone'] = phone;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['state'] = state;
    data['country'] = country;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }

  @override
  String toString() {
    return 'ShippingAddress{contactPersonName: $contactPersonName, address: $address, city: $city, zip: $zip, phone: $phone, country: $country}';
  }
}

class Customer {
  int? id;
  String? name;
  String? fName;
  String? lName;
  String? phone;
  String? image;
  ImageFullUrl? imageFullUrl;
  String? email;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;
  String? streetAddress;
  String? country;
  String? city;
  String? zip;
  String? houseNo;
  String? apartmentNo;
  String? cmFirebaseToken;
  int? isActive;
  String? loginMedium;
  String? socialId;
  int? isPhoneVerified;
  String? temporaryToken;
  String? paymentCardLastFour;
  String? paymentCardBrand;
  String? paymentCardFawryToken;
  int? isEmailVerified;

  Customer(
      {this.id,
        this.name,
        this.fName,
        this.lName,
        this.phone,
        this.image,
        this.imageFullUrl,
        this.email,
        this.emailVerifiedAt,
        this.createdAt,
        this.updatedAt,
        this.streetAddress,
        this.country,
        this.city,
        this.zip,
        this.houseNo,
        this.apartmentNo,
        this.cmFirebaseToken,
        this.isActive,
        this.loginMedium,
        this.socialId,
        this.isPhoneVerified,
        this.temporaryToken,
        this.paymentCardLastFour,
        this.paymentCardBrand,
        this.paymentCardFawryToken,
        this.isEmailVerified});

  Customer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    if(json['image'] != null){
      image = json['image'];
    }
    email = json['email'];
    emailVerifiedAt = json['email_verified_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    streetAddress = json['street_address'];
    country = json['country'];
    city = json['city'];
    zip = json['zip'];
    houseNo = json['house_no'];
    apartmentNo = json['apartment_no'];
    cmFirebaseToken = json['cm_firebase_token'];
    if(json['is_active'] != null){
      isActive = json['is_active'] ? 1 : 0;
    }
    loginMedium = json['login_medium'];
    socialId = json['social_id'];
    if(json['is_phone_verified'] != null){
      isPhoneVerified = json['is_phone_verified'] ? 1 : 0;
    }
    temporaryToken = json['temporary_token'];
    paymentCardLastFour = json['payment_card_last_four'];
    paymentCardBrand = json['payment_card_brand'];
    paymentCardFawryToken = json['payment_card_fawry_token'];
    if(json['is_email_verified'] != null){
      isEmailVerified = json['is_email_verified'] ? 1 : 0;
    }
    imageFullUrl = json['image_full_url'] != null
      ? ImageFullUrl.fromJson(json['image_full_url'])
      : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['f_name'] = fName;
    data['l_name'] = lName;
    data['phone'] = phone;
    data['image'] = image;
    data['email'] = email;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['street_address'] = streetAddress;
    data['country'] = country;
    data['city'] = city;
    data['zip'] = zip;
    data['house_no'] = houseNo;
    data['apartment_no'] = apartmentNo;
    data['cm_firebase_token'] = cmFirebaseToken;
    data['is_active'] = isActive;
    data['login_medium'] = loginMedium;
    data['social_id'] = socialId;
    data['is_phone_verified'] = isPhoneVerified;
    data['temporary_token'] = temporaryToken;
    data['payment_card_last_four'] = paymentCardLastFour;
    data['payment_card_brand'] = paymentCardBrand;
    data['payment_card_fawry_token'] = paymentCardFawryToken;
    data['is_email_verified'] = isEmailVerified;
    return data;
  }
}


class SellerInfo {
  int? id;
  String? phone;
  String? email;
  Shop? shop;


  SellerInfo(
      {this.id,
        this.shop,
      this.phone,
      this.email});

  SellerInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    phone = json['phone'];
    email = json['email'];
    shop = json['shop'] != null ? Shop.fromJson(json['shop']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['phone'] = phone;
    data['email'] = email;
    if (shop != null) {
      data['shop'] = shop!.toJson();
    }
    return data;
  }
}

class Shop {
  int? id;
  int? sellerId;
  String? name;
  String? address;
  String? contact;
  String? latitude;
  String? longitude;
  String? image;
  ImageFullUrl? imageFullUrl;
  String? bottomBanner;
  String? offerBanner;
  DateTime? vacationStartDate;
  DateTime? vacationEndDate;
  String? vacationNote;
  bool? vacationStatus;
  bool? temporaryClose;
  String? createdAt;
  String? updatedAt;
  String? banner;
  VacationDurationType? vacationDurationType;

  Shop(
      {this.id,
        this.sellerId,
        this.name,
        this.address,
        this.contact,
        this.latitude,
        this.longitude,
        this.image,
        this.imageFullUrl,
        this.bottomBanner,
        this.offerBanner,
        this.vacationStartDate,
        this.vacationEndDate,
        this.vacationNote,
        this.vacationStatus,
        this.temporaryClose,
        this.createdAt,
        this.updatedAt,
        this.banner,
        this.vacationDurationType,
      });

  Shop.fromJson(Map<String, dynamic> json) {
    id = int.tryParse('${json['id'] ?? ''}');
    sellerId = int.tryParse('${json['seller_id'] ?? ''}');
    name = json['name']?.toString();
    address = json['address']?.toString();
    contact = json['contact']?.toString();
    latitude = json['latitude']?.toString() ??
        json['lat']?.toString() ??
        json['shop_lat']?.toString();
    longitude = json['longitude']?.toString() ??
        json['lng']?.toString() ??
        json['long']?.toString() ??
        json['shop_lng']?.toString();
    image = json['image']?.toString();
    if (json['image_full_url'] != null) {
      imageFullUrl = ImageFullUrl.fromJson(json['image_full_url']);
    }
    bottomBanner = json['bottom_banner']?.toString();
    offerBanner = json['offer_banner']?.toString();
    vacationStartDate = DateTime.tryParse(json['vacation_start_date'].toString());
    vacationEndDate = DateTime.tryParse(json['vacation_end_date'].toString());
    vacationNote = json['vacation_note']?.toString();
    if(json['vacation_status'] != null){
      try{
        vacationStatus = json['vacation_status'] ?? false;
      }catch(e){
        vacationStatus = json['vacation_status'] == 1 ? true :false;
      }
    }
    if(json['temporary_close'] != null){
      try{
        temporaryClose = json['temporary_close'] ?? false;
      }catch(e){
        temporaryClose = json['temporary_close'] == 1 ? true : false;
      }
    }

    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    banner = json['banner']?.toString();

    if(json['vacation_duration_type'] != null) {
      vacationDurationType =  VacationDurationType.fromJson(json['vacation_duration_type']);
    }
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'address': address,
      'contact': contact,
      'latitude': latitude,
      'longitude': longitude,
      'image': image,
      'image_full_url': imageFullUrl?.toJson(),
      'bottom_banner': bottomBanner,
      'offer_banner': offerBanner,
      'vacation_start_date': vacationStartDate,
      'vacation_end_date': vacationEndDate,
      'vacation_note': vacationNote,
      'vacation_status': vacationStatus,
      'temporary_close': temporaryClose,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'banner': banner,
      'vacation_duration_type': vacationDurationType?.toJson(),
    };
  }


}