import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/assignment/domain/models/assignment_settings_model.dart';

/// Shared gate for OLD rider Transfer button (mirrors backend rules).
class OrderTransferHelper {
  static const String unlockAfterReachSeconds = 'after_reach_seconds';
  static const String unlockPrepOverdue = 'prep_overdue';
  static const String unlockEither = 'either';

  static String unlockMode(
    OrderModel? order, {
    AssignmentSettingsModel? settings,
  }) {
    final fromSettings = (settings?.orderTransferUnlockMode ?? '').trim();
    if (fromSettings.isNotEmpty) return fromSettings;
    final fromOrder = (order?.orderTransferUnlockMode ?? '').trim();
    if (fromOrder.isNotEmpty) return fromOrder;

    // Older app/API: map only_after_prep_overdue flag.
    final onlyOverdue = settings?.orderTransferOnlyAfterPrepOverdue == true ||
        (order?.orderTransferOnlyAfterPrepOverdue ?? 0) == 1;
    return onlyOverdue ? unlockPrepOverdue : unlockAfterReachSeconds;
  }

  static int afterReachSeconds(
    OrderModel? order, {
    AssignmentSettingsModel? settings,
  }) {
    final fromSettings = settings?.orderTransferAfterReachSeconds;
    if (fromSettings != null && fromSettings >= 30) {
      return fromSettings.clamp(30, 120);
    }
    final fromOrder = order?.orderTransferAfterReachSeconds;
    if (fromOrder != null && fromOrder >= 30) {
      return fromOrder.clamp(30, 120);
    }
    return 40;
  }

  static int secondsSinceReachStore(OrderModel? order) {
    final raw = (order?.storeWaitStartedAt ?? '').trim();
    if (raw.isEmpty || raw == 'null') return 0;
    final started = DateTime.tryParse(raw);
    if (started == null) return 0;
    final elapsed = DateTime.now().difference(started).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  static int secondsUntilUnlock(
    OrderModel? order, {
    AssignmentSettingsModel? settings,
    bool? overdueOverride,
  }) {
    if (!canShowTransferBase(order, settings: settings)) return -1;

    final mode = unlockMode(order, settings: settings);
    final need = afterReachSeconds(order, settings: settings);
    final elapsed = secondsSinceReachStore(order);
    final remaining = (need - elapsed).clamp(0, need);
    final overdue = overdueOverride == true ||
        (order?.storeWaitOverdue ?? 0) == 1;

    if (mode == unlockPrepOverdue) {
      // Transfer button vanishes while food prep is still running.
      return overdue ? 0 : -1;
    }
    if (mode == unlockEither) {
      if (overdue || elapsed >= need) return 0;
      return remaining;
    }
    // after_reach_seconds
    return remaining;
  }

  /// Status / lock / packaging gates without unlock timing.
  static bool canShowTransferBase(
    OrderModel? order, {
    AssignmentSettingsModel? settings,
  }) {
    if (order == null) return false;

    final settingsEnabled = settings?.orderTransferEnabled;
    final enabled = settingsEnabled == true ||
        (order.orderTransferEnabled ?? 0) == 1;
    if (!enabled) return false;

    if ((order.orderTransferLocked ?? 0) == 1 ||
        (order.orderTransferAlreadyDone ?? 0) == 1) {
      return false;
    }

    final status = OrderStatusHelper.normalize(order.orderStatus);
    final onlyReach = settings?.orderTransferOnlyAfterReachStore != false &&
        (order.orderTransferOnlyAfterReachStore ?? 1) != 0;
    final blockPickup = settings?.orderTransferBlockAfterPickup != false &&
        (order.orderTransferBlockAfterPickup ?? 1) != 0;
    final blockOfd = settings?.orderTransferBlockOutForDelivery != false &&
        (order.orderTransferBlockOutForDelivery ?? 1) != 0;

    if (blockOfd &&
        (status == OrderStatusHelper.outForDelivery ||
            status == OrderStatusHelper.arrivedAtCustomer ||
            status == OrderStatusHelper.delivered ||
            status == OrderStatusHelper.canceled ||
            status == 'cancelled' ||
            status == OrderStatusHelper.returned ||
            status == OrderStatusHelper.failed)) {
      return false;
    }

    // Pickup OTP / OFD still block below.

    if (blockPickup && (order.pickupVerificationStatus ?? 0) == 1) {
      // (processing / reached_restaurant) until rider starts OFD.
      final atStoreForTransfer =
          status == OrderStatusHelper.reachedRestaurant ||
              status == OrderStatusHelper.confirmed ||
              status == OrderStatusHelper.processing;
      if (!atStoreForTransfer) {
        return false;
      }
    }

    if (status != OrderStatusHelper.reachedRestaurant &&
        status != OrderStatusHelper.confirmed &&
        status != OrderStatusHelper.processing) {
      return false;
    }

    if (onlyReach) {
      final reached = status == OrderStatusHelper.reachedRestaurant ||
          ((order.storeWaitStartedAt ?? '').trim().isNotEmpty &&
              order.storeWaitStartedAt != 'null');
      if (!reached) return false;
    }

    return true;
  }

  static bool canShowTransfer(
    OrderModel? order, {
    AssignmentSettingsModel? settings,
    bool? overdueOverride,
  }) {
    if (!canShowTransferBase(order, settings: settings)) return false;

    final mode = unlockMode(order, settings: settings);
    final need = afterReachSeconds(order, settings: settings);
    final elapsed = secondsSinceReachStore(order);
    final overdue = overdueOverride == true ||
        (order?.storeWaitOverdue ?? 0) == 1;
    final elapsedOk = elapsed >= need;

    if (mode == unlockPrepOverdue) return overdue;
    if (mode == unlockEither) return elapsedOk || overdue;
    return elapsedOk;
  }
}
