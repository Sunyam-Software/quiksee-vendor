import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';

class OrderGroupHelper {
  static const String defaultGroupId = 'def-order-group';

  static bool isCombinedCheckout(OrderModel? order) {
    if (order == null) return false;
    if (order.isCombinedCheckout) return true;
    final children = order.combinedOrders;
    if (children != null && children.length >= 2) return true;
    final groupId = order.orderGroupId;
    return groupId != null && groupId.isNotEmpty && groupId != defaultGroupId;
  }

  static bool sharesCheckoutGroup(OrderModel a, OrderModel b) {
    if (!isCombinedCheckout(a) || !isCombinedCheckout(b)) return false;
    if (a.orderGroupId != b.orderGroupId) return false;
    if (a.customerId != null &&
        b.customerId != null &&
        a.customerId != b.customerId) {
      return false;
    }
    return true;
  }

  static List<OrderModel> poolFor(OrderModel anchor, List<OrderModel> pool) {
    return expandOrderPool([anchor, ...pool]);
  }

  static List<OrderModel> siblingOrders(
    OrderModel anchor,
    List<OrderModel> pool, {
    bool includeAnchor = true,
  }) {
    final expanded = poolFor(anchor, pool);
    if (!isCombinedCheckout(anchor)) {
      return includeAnchor ? [anchor] : [];
    }

    final matches =
        expanded.where((order) => sharesCheckoutGroup(anchor, order)).toList();
    if (!includeAnchor) {
      matches.removeWhere((order) => order.id == anchor.id);
    }
    // Prefer pickup sequence when present.
    matches.sort((a, b) {
      final as = a.pickupSequence ?? a.id ?? 0;
      final bs = b.pickupSequence ?? b.id ?? 0;
      return as.compareTo(bs);
    });
    return matches;
  }

  static List<OrderModel> expandOrderPool(List<OrderModel> pool) {
    final result = <OrderModel>[];
    final seen = <int>{};

    void add(OrderModel? order) {
      final id = order?.id;
      if (order == null || id == null || seen.contains(id)) return;
      seen.add(id);
      result.add(order);
    }

    for (final order in pool) {
      add(order);
      if (order.combinedOrders != null) {
        for (final child in order.combinedOrders!) {
          add(child);
        }
      }
    }

    return result;
  }

  /// Per-store pickup; shared drop only after each store is packaged.
  static List<OrderModel> ordersForStatusTransition(
    OrderModel anchor,
    String targetStatus,
    List<OrderModel> pool,
  ) {
    bool alreadyReached(OrderModel order) {
      if (!Get.isRegistered<OrderDetailsController>()) return false;
      return Get.find<OrderDetailsController>()
          .hasReachedRestaurant(order.id);
    }

    bool eligible(OrderModel order) {
      switch (targetStatus) {
        case 'reached_restaurant':
          return OrderStatusHelper.canReachRestaurant(
            order.orderStatus,
            alreadyReached: alreadyReached(order),
            storeWaitStartedAt: order.storeWaitStartedAt,
            pickupVerificationStatus: order.pickupVerificationStatus,
            orderTransferReceived: order.orderTransferReceived,
          );
        case 'processing':
          return OrderStatusHelper.canPickUp(
            order.orderStatus,
            alreadyReached: alreadyReached(order),
            storeWaitStartedAt: order.storeWaitStartedAt,
            pickupVerificationStatus: order.pickupVerificationStatus,
            orderTransferReceived: order.orderTransferReceived,
          );
        case 'out_for_delivery':
          return OrderStatusHelper.canStartOutForDelivery(order.orderStatus);
        case 'arrived_at_customer':
          return OrderStatusHelper.canArriveAtCustomer(order.orderStatus);
        case 'delivered':
          return OrderStatusHelper.canDeliver(order.orderStatus);
        default:
          return order.id == anchor.id;
      }
    }

    if (targetStatus == 'reached_restaurant' || targetStatus == 'processing') {
      return [anchor];
    }

    // Drop / arrive / deliver: only siblings that already completed packaging.
    if (targetStatus == 'out_for_delivery' ||
        targetStatus == 'arrived_at_customer' ||
        targetStatus == 'delivered') {
      final group = siblingOrders(anchor, pool);
      if (group.length <= 1) return [anchor];

      final eligibleOrders = group.where((order) {
        final status = (order.orderStatus ?? '').toLowerCase();
        if (targetStatus == 'out_for_delivery') {
          // Must be packaged (processing) or already OFD-eligible.
          return status == 'processing' ||
              OrderStatusHelper.canStartOutForDelivery(order.orderStatus);
        }
        if (targetStatus == 'arrived_at_customer') {
          return status == 'out_for_delivery' ||
              OrderStatusHelper.canArriveAtCustomer(order.orderStatus);
        }
        // delivered: already OFD or arrived (or can deliver).
        return status == 'out_for_delivery' ||
            status == 'arrived_at_customer' ||
            OrderStatusHelper.canDeliver(order.orderStatus);
      }).toList();

      if (eligibleOrders.isEmpty) return [anchor];
      if (!eligibleOrders.any((o) => o.id == anchor.id)) {
        return [anchor, ...eligibleOrders];
      }
      return eligibleOrders;
    }

    final group = siblingOrders(anchor, pool);
    final eligibleOrders = group.where(eligible).toList();
    if (eligibleOrders.isNotEmpty) return eligibleOrders;
    return [anchor];
  }

  static int combinedOrderCount(OrderModel anchor, List<OrderModel> pool) {
    return siblingOrders(anchor, pool).length;
  }

  /// Unpaid COD sibling ids for payment mark-all.
  static List<int> unpaidCodOrderIds(OrderModel anchor, List<OrderModel> pool) {
    return siblingOrders(anchor, pool)
        .where((order) =>
            order.paymentMethod == 'cash_on_delivery' &&
            order.paymentStatus != 'paid' &&
            order.id != null)
        .map((order) => order.id!)
        .toList();
  }

  static double combinedCodAmount(
    OrderModel anchor,
    List<OrderModel> pool,
  ) {
    double total = 0;
    for (final order in siblingOrders(anchor, pool)) {
      if (order.paymentMethod == 'cash_on_delivery' &&
          order.paymentStatus != 'paid') {
        total += order.orderAmount ?? 0;
      }
    }
    if (total > 0) return total;
    // Single-row fallback when nested children not expanded yet.
    if (anchor.paymentMethod == 'cash_on_delivery' &&
        anchor.paymentStatus != 'paid') {
      return anchor.orderAmount ?? 0;
    }
    return 0;
  }
}
