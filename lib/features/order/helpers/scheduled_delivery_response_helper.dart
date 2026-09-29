import 'package:quiksee/features/order/domain/models/order_model.dart';

/// Scheduled delivery list APIs wrap payloads as `{order_type, orders: [...]}`.
class ScheduledDeliveryResponseHelper {
  ScheduledDeliveryResponseHelper._();

  static List<dynamic> extractOrderList(dynamic body) {
    if (body == null) return const [];
    if (body is List) return body;
    if (body is Map) {
      final orders = body['orders'];
      if (orders is List) return orders;
    }
    return const [];
  }

  static List<Map<String, dynamic>> extractOffersList(dynamic body) {
    if (body == null) return const [];
    if (body is Map) {
      final offers = body['offers'];
      if (offers is List) {
        return offers
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  static List<OrderModel> parseOrderList(dynamic body) {
    final orders = <OrderModel>[];
    for (final raw in extractOrderList(body)) {
      if (raw is! Map) continue;
      try {
        orders.add(
          OrderModel.fromJson(normalizeOrderJson(raw)),
        );
      } catch (_) {}
    }
    return orders;
  }

  static Map<String, dynamic> normalizeOrderJson(Map<dynamic, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);

    if (json['id'] == null && json['order_id'] != null) {
      json['id'] = json['order_id'];
    }

    // Scheduled list APIs often send flat store_* fields (or seller without address).
    // Normal current-orders sends full seller.shop with address/lat/lng.
    _ensureSellerShopFromStoreFields(json);

    if (json['customer_name'] != null && json['customer'] == null) {
      json['customer'] = {
        'f_name': json['customer_name'],
        'phone': json['customer_phone'],
      };
    }

    final storeAddress = (json['store_address'] ??
            (json['seller'] is Map
                ? ((json['seller'] as Map)['shop'] is Map
                    ? ((json['seller'] as Map)['shop'] as Map)['address']
                    : null)
                : null))
        ?.toString()
        .trim()
        .toLowerCase();
    final deliveryAddress = json['delivery_address']?.toString().trim();
    final deliveryLooksLikeStore = deliveryAddress != null &&
        storeAddress != null &&
        storeAddress.isNotEmpty &&
        deliveryAddress.toLowerCase() == storeAddress;

    // Never seed shipping from store-duplicated delivery_address.
    if (deliveryAddress != null &&
        deliveryAddress.isNotEmpty &&
        !deliveryLooksLikeStore &&
        json['shipping_address'] == null) {
      json['shipping_address'] = {
        'address': deliveryAddress,
        'phone': json['customer_phone'],
        'latitude': json['delivery_latitude']?.toString(),
        'longitude': json['delivery_longitude']?.toString(),
        'city': json['delivery_city'],
        'zip': json['delivery_zip'],
      };
    }

    if (json['scheduled_delivery'] is Map) {
      final sd = Map<String, dynamic>.from(json['scheduled_delivery']);
      json['is_scheduled_delivery'] ??= sd['is_scheduled_delivery'];
      json['is_scheduled_order'] ??= sd['is_scheduled_order'];
      json['scheduled_delivery_date'] ??= sd['scheduled_delivery_date'];
      json['scheduled_delivery_time_from'] ??=
          sd['scheduled_delivery_time_from'];
      json['scheduled_delivery_time_to'] ??= sd['scheduled_delivery_time_to'];
      json['delivery_type'] ??= sd['delivery_type'];
      if (sd['label'] != null) {
        json['scheduled_delivery'] = {
          ...sd,
          'label': sd['label'],
          'is_scheduled_delivery': sd['is_scheduled_delivery'] ?? true,
        };
      }
    }

    json['order_type'] ??= 'scheduled';
    json['is_scheduled_delivery'] ??= true;
    json['delivery_type'] ??= 'scheduled';

    // Prefer amount_to_collect aliases when present.
    json['order_amount'] ??= json['amount_to_collect'] ??
        json['cash_to_collect'] ??
        json['collectable_amount'] ??
        json['total_amount'] ??
        0;
    json['discount_amount'] ??= 0;
    json['shipping_cost'] ??= 0;
    if (json['payment_info'] is Map) {
      final pi = Map<String, dynamic>.from(json['payment_info'] as Map);
      json['platform_fee'] ??= pi['platform_fee'] ?? 0;
      json['scheduled_delivery_charge'] ??=
          pi['scheduled_delivery_charge'] ?? 0;
      json['delivery_man_tip'] ??= pi['delivery_man_tip'] ?? 0;
      json['total_tax_amount'] ??= pi['tax'] ?? 0;
      json['item_discount'] ??= pi['item_discount'] ?? 0;
      json['coupon_discount'] ??= pi['coupon_discount'] ?? 0;
      json['extra_discount'] ??= pi['extra_discount'] ?? 0;
      json['refer_and_earn_discount'] ??=
          pi['refer_and_earn_discount'] ?? json['refer_and_earn_discount'] ?? 0;
      if ((pi['discount'] ?? 0) is num && (pi['discount'] as num) > 0) {
        json['discount_amount'] = pi['discount'];
      }
    } else {
      json['platform_fee'] ??= 0;
      json['scheduled_delivery_charge'] ??= 0;
      json['delivery_man_tip'] ??= 0;
      json['total_tax_amount'] ??= 0;
    }
    json['refer_and_earn_discount'] ??= 0;
    json['item_discount'] ??= 0;
    json['coupon_discount'] ??= 0;
    json['extra_discount'] ??= 0;
    json['is_guest'] ??= false;
    json['created_at'] ??=
        json['assigned_at'] ?? json['updated_at'] ?? DateTime.now().toIso8601String();

    return json;
  }

  /// Fill seller.shop from flat scheduled fields so Reach Restaurant GPS works
  /// the same as normal delivery (which already has full seller.shop).
  static void _ensureSellerShopFromStoreFields(Map<String, dynamic> json) {
    final storeName = json['store_name']?.toString().trim();
    final storeAddress = json['store_address']?.toString().trim();
    final storeLat = (json['store_latitude'] ??
            json['store_lat'] ??
            json['pickup_latitude'] ??
            json['pickup_lat'])
        ?.toString();
    final storeLng = (json['store_longitude'] ??
            json['store_lng'] ??
            json['store_long'] ??
            json['pickup_longitude'] ??
            json['pickup_lng'])
        ?.toString();

    if (json['seller'] == null) {
      if ((storeName == null || storeName.isEmpty) &&
          (storeAddress == null || storeAddress.isEmpty)) {
        return;
      }
      json['seller'] = {
        'shop': {
          'seller_id': 0,
          if (storeName != null && storeName.isNotEmpty) 'name': storeName,
          if (storeAddress != null && storeAddress.isNotEmpty)
            'address': storeAddress,
          if (storeLat != null && storeLat.isNotEmpty) 'latitude': storeLat,
          if (storeLng != null && storeLng.isNotEmpty) 'longitude': storeLng,
        },
      };
      return;
    }

    if (json['seller'] is! Map) return;
    final seller = Map<String, dynamic>.from(json['seller'] as Map);
    final shopRaw = seller['shop'];
    final shop = shopRaw is Map
        ? Map<String, dynamic>.from(shopRaw)
        : <String, dynamic>{};

    if ((shop['name'] == null || '${shop['name']}'.trim().isEmpty) &&
        storeName != null &&
        storeName.isNotEmpty) {
      shop['name'] = storeName;
    }
    if ((shop['address'] == null || '${shop['address']}'.trim().isEmpty) &&
        storeAddress != null &&
        storeAddress.isNotEmpty) {
      shop['address'] = storeAddress;
    }
    if ((shop['latitude'] == null || '${shop['latitude']}'.trim().isEmpty) &&
        storeLat != null &&
        storeLat.isNotEmpty) {
      shop['latitude'] = storeLat;
    }
    if ((shop['longitude'] == null || '${shop['longitude']}'.trim().isEmpty) &&
        storeLng != null &&
        storeLng.isNotEmpty) {
      shop['longitude'] = storeLng;
    }

    seller['shop'] = shop;
    json['seller'] = seller;
  }
}
