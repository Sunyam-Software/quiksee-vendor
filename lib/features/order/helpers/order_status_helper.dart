import 'package:quiksee/features/order/domain/models/order_model.dart';

class OrderStatusHelper {
  static const String pending = 'pending';
  static const String assigned = 'assigned';
  static const String confirmed = 'confirmed';
  static const String reachedRestaurant = 'reached_restaurant';
  static const String processing = 'processing';
  static const String outForDelivery = 'out_for_delivery';
  static const String arrivedAtCustomer = 'arrived_at_customer';
  static const String delivered = 'delivered';
  static const String canceled = 'canceled';
  static const String returned = 'returned';
  static const String failed = 'failed';

  static String normalize(String? status) => (status ?? '').toLowerCase().trim();

  /// UI label for any order status (unknown → spaced fallback).
  static String label(String? status) {
    switch (normalize(status)) {
      case pending:
        return 'Pending';
      case assigned:
        return 'Assigned';
      case confirmed:
        return 'Confirmed';
      case reachedRestaurant:
        return 'Reached Restaurant';
      case processing:
        return 'Packaging';
      case outForDelivery:
        return 'Out For Delivery';
      case arrivedAtCustomer:
        return 'Arrived at Customer';
      case delivered:
        return 'Delivered';
      case 'cancelled':
      case canceled:
        return 'Canceled';
      case returned:
      case 'return':
        return 'Returned';
      case failed:
        return 'Failed to Deliver';
      default:
        final raw = (status ?? '').trim();
        if (raw.isEmpty) return '--';
        return raw.replaceAll('_', ' ');
    }
  }

  /// Localization key when available; else falls back to [label].
  static String labelKey(String? status) {
    switch (normalize(status)) {
      case pending:
        return 'pending';
      case assigned:
        return 'assigned';
      case confirmed:
        return 'order_confirmed';
      case reachedRestaurant:
        return 'reached_restaurant';
      case processing:
        return 'order_processing';
      case outForDelivery:
        return 'out_for_delivery';
      case arrivedAtCustomer:
        return 'arrived_at_customer';
      case delivered:
        return 'delivered';
      case 'cancelled':
      case canceled:
        return 'canceled';
      case returned:
      case 'return':
        return 'returned';
      case failed:
        return 'failed';
      default:
        return '';
    }
  }

  static int statusRank(String? status) {
    switch (normalize(status)) {
      case pending:
        return 0;
      case 'accepted':
      case assigned:
        return 1;
      case confirmed:
        return 2;
      case reachedRestaurant:
        return 3;
      case processing:
        return 4;
      case outForDelivery:
        return 5;
      case arrivedAtCustomer:
        return 6;
      case delivered:
        return 7;
      default:
        return -1;
    }
  }

  static String? nextStatusFor(String? current) {
    switch (normalize(current)) {
      case pending:
      case assigned:
      case 'accepted':
        return confirmed;
      case confirmed:
        return reachedRestaurant;
      case reachedRestaurant:
        return processing;
      case processing:
        return outForDelivery;
      case outForDelivery:
        return arrivedAtCustomer;
      case arrivedAtCustomer:
        return delivered;
      default:
        return null;
    }
  }

  static bool isTerminalStatus(String? status) {
    final s = normalize(status);
    return s == delivered ||
        s == canceled ||
        s == 'cancelled' ||
        s == failed ||
        s == returned ||
        s == 'return';
  }

  static bool isActiveCurrentOrderStatus(String? status) {
    final s = normalize(status);
    return s == pending ||
        s == confirmed ||
        s == reachedRestaurant ||
        s == processing ||
        s == outForDelivery ||
        s == arrivedAtCustomer ||
        s == assigned ||
        s == 'accepted';
  }

  /// Driver must tap Accept before delivery starts (even if backend auto-assigned).
  static bool needsDriverAcceptance(
    OrderModel? order,
    Set<int> driverAcceptedOrderIds,
  ) {
    if (order?.id == null) return false;
    if (driverAcceptedOrderIds.contains(order!.id)) return false;
    if (isTerminalStatus(order.orderStatus)) return false;
    return true;
  }

  static String resolveAcceptApiStatus(String? currentStatus) {
    final s = normalize(currentStatus);
    if (s == outForDelivery ||
        s == arrivedAtCustomer ||
        s == processing ||
        s == confirmed ||
        s == reachedRestaurant) {
      return s;
    }
    return confirmed;
  }

  /// Backend may already have advanced status before driver taps Accept.
  static bool canSkipAcceptApi(String? status) {
    final s = normalize(status);
    return s == confirmed ||
        s == reachedRestaurant ||
        s == processing ||
        s == outForDelivery ||
        s == arrivedAtCustomer;
  }

  static String acceptApiStatus(String? currentStatus) {
    return confirmed;
  }

  static bool needsAcceptAction(String? status) {
    if (isTerminalStatus(status)) return false;
    final s = normalize(status);
    return s == pending ||
        s == confirmed ||
        s == reachedRestaurant ||
        s == processing ||
        s == 'accepted' ||
        s == outForDelivery ||
        s == assigned;
  }

  /// After accept: rider must mark reach restaurant (GPS-gated) before packaging.
  /// Hide Reach Store when already at store / transferred / OTP verified / OFD.
  static bool canReachRestaurant(
    String? status, {
    bool alreadyReached = false,
    String? storeWaitStartedAt,
    int? pickupVerificationStatus,
    int? orderTransferReceived,
  }) {
    if (alreadyAtStore(
      status: status,
      alreadyReached: alreadyReached,
      storeWaitStartedAt: storeWaitStartedAt,
      pickupVerificationStatus: pickupVerificationStatus,
      orderTransferReceived: orderTransferReceived,
    )) {
      return false;
    }
    final s = normalize(status);
    // confirmed = going to store; processing = vendor Ready early (rider still needs Reach).
    return s == confirmed || s == processing;
  }

  static bool alreadyAtStore({
    String? status,
    bool alreadyReached = false,
    String? storeWaitStartedAt,
    int? pickupVerificationStatus,
    int? orderTransferReceived,
  }) {
    if (alreadyReached) return true;
    if (pickupVerificationStatus == 1) return true;
    if (orderTransferReceived == 1) return true;
    final s = normalize(status);
    if (s == reachedRestaurant ||
        s == outForDelivery ||
        s == arrivedAtCustomer ||
        s == delivered) {
      return true;
    }
    // at-store when wait/OTP/transfer evidence exists.
    if (s == processing) {
      final started = (storeWaitStartedAt ?? '').trim();
      return started.isNotEmpty && started != 'null';
    }
    final started = (storeWaitStartedAt ?? '').trim();
    return started.isNotEmpty && started != 'null';
  }

  /// Packaging (processing) only after restaurant reach.
  static bool canPickUp(
    String? status, {
    bool alreadyReached = false,
    String? storeWaitStartedAt,
    int? pickupVerificationStatus,
    int? orderTransferReceived,
  }) {
    final s = normalize(status);
    if (s == reachedRestaurant) return true;
    if (s == confirmed &&
        alreadyAtStore(
          status: status,
          alreadyReached: alreadyReached,
          storeWaitStartedAt: storeWaitStartedAt,
          pickupVerificationStatus: pickupVerificationStatus,
          orderTransferReceived: orderTransferReceived,
        )) {
      return true;
    }
    return false;
  }

  /// Rank for merging stale details vs live current-orders status.
  static int statusProgressRank(String? status) {
    switch (normalize(status)) {
      case delivered:
        return 50;
      case arrivedAtCustomer:
        return 45;
      case outForDelivery:
        return 40;
      case processing:
        return 30;
      case reachedRestaurant:
        return 20;
      case confirmed:
      case assigned:
      case 'accepted':
        return 10;
      case pending:
        return 5;
      default:
        return 0;
    }
  }

  static bool canStartOutForDelivery(String? status) =>
      normalize(status) == processing;

  /// Rider at customer door (max cancel fee stage).
  static bool canArriveAtCustomer(String? status) =>
      normalize(status) == outForDelivery;

  static bool canDeliver(String? status) =>
      normalize(status) == arrivedAtCustomer;

  static bool showsDeliveryActionBar(String? status) {
    final s = normalize(status);
    return s == confirmed ||
        s == reachedRestaurant ||
        s == processing ||
        s == outForDelivery ||
        s == arrivedAtCustomer;
  }

  static bool isDelivered(String? status) => normalize(status) == delivered;

  /// After delivery, hide customer address + mobile for privacy.
  static bool shouldHideCustomerContact(String? status) =>
      isDelivered(status);

  /// Still navigating to / at store (before packaging pickup).
  static bool isStoreNavigationStatus(String? status) {
    final s = normalize(status);
    return s == confirmed || s == reachedRestaurant;
  }

  static bool isReachedRestaurant(String? status) =>
      normalize(status) == reachedRestaurant;
}
