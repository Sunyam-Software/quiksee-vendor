import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorReadyPopupHelper {
  static int? _lastShownOrderId;
  static DateTime? _lastShownAt;
  static bool _dialogOpen = false;
  static final Set<int> _shownOrderIds = <int>{};
  static bool _ordersSeeded = false;
  static bool _dismissedLoaded = false;
  static bool _currentOrdersFetchAttempted = false;

  static Future<void> storePending({
    required int orderId,
    String? description,
  }) async {
    if (orderId <= 0) return;
    if (await _wasDismissed(orderId)) return;
    if (!await _isPickupRelevant(orderId)) {
      await clearPending(orderId: orderId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.pendingVendorReadyOrderId, orderId);
    await prefs.setString(
      AppConstants.pendingVendorReadyDescription,
      description?.trim() ?? '',
    );
    await prefs.setInt(
      AppConstants.pendingVendorReadyStoredAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearPending({int? orderId}) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getInt(AppConstants.pendingVendorReadyOrderId) ?? 0;
    if (orderId != null && orderId > 0 && pending != orderId) return;
    await prefs.remove(AppConstants.pendingVendorReadyOrderId);
    await prefs.remove(AppConstants.pendingVendorReadyDescription);
    await prefs.remove(AppConstants.pendingVendorReadyStoredAtMs);
  }

  static Future<void> dismissForOrder(int orderId) async {
    if (orderId <= 0) return;
    await _markDismissed(orderId);
    await clearPending(orderId: orderId);
  }

  static Future<void> processPending() async {
    final prefs = await SharedPreferences.getInstance();
    final orderId = prefs.getInt(AppConstants.pendingVendorReadyOrderId) ?? 0;
    if (orderId <= 0) return;

    final description =
        prefs.getString(AppConstants.pendingVendorReadyDescription);
    final storedAtMs =
        prefs.getInt(AppConstants.pendingVendorReadyStoredAtMs) ?? 0;

    const maxAgeMs = 30 * 60 * 1000;
    if (storedAtMs > 0 &&
        DateTime.now().millisecondsSinceEpoch - storedAtMs > maxAgeMs) {
      await clearPending(orderId: orderId);
      return;
    }

    await _ensureCurrentOrdersLoaded();

    if (await _wasDismissed(orderId) || !await _isPickupRelevant(orderId)) {
      await clearPending(orderId: orderId);
      return;
    }

    await show(
      orderId: orderId,
      description: description,
      clearPendingOnShow: true,
    );
  }

  static Future<void> showFromPushData(Map<String, dynamic> data) async {
    final type = data['type']?.toString() ?? '';
    if (type != 'order_ready_for_pickup') return;

    final orderId = int.tryParse('${data['order_id'] ?? ''}') ?? 0;
    if (orderId <= 0) return;

    final description = (data['description'] ?? data['body'] ?? data['title'])
        ?.toString();

    await show(orderId: orderId, description: description);
  }

  static Future<void> maybeShowFromOrder(OrderModel? order) async {
    if (order?.id == null || order!.id! <= 0) return;
    final readyAt = order.vendorReadyAt?.trim() ?? '';
    if (readyAt.isEmpty || readyAt == 'null') return;
    if (!_isStatusPickupRelevant(order.orderStatus)) return;
    await show(orderId: order.id!);
  }

  static Future<void> maybeShowFromOrders(List<OrderModel>? orders) async {
    if (orders == null || orders.isEmpty) {
      _ordersSeeded = true;
      return;
    }
    if (!_ordersSeeded) {
      for (final order in orders) {
        final id = order.id ?? 0;
        final readyAt = order.vendorReadyAt?.trim() ?? '';
        if (id > 0 && readyAt.isNotEmpty && readyAt != 'null') {
          _shownOrderIds.add(id);
        }
      }
      _ordersSeeded = true;
      return;
    }
    for (final order in orders) {
      await maybeShowFromOrder(order);
    }
  }

  static Future<void> show({
    required int orderId,
    String? description,
    bool clearPendingOnShow = true,
  }) async {
    if (orderId <= 0) return;

    await _ensureDismissedLoaded();
    if (_shownOrderIds.contains(orderId) || await _wasDismissed(orderId)) {
      await clearPending(orderId: orderId);
      return;
    }

    await _ensureCurrentOrdersLoaded();
    if (!await _isPickupRelevant(orderId)) {
      await dismissForOrder(orderId);
      return;
    }

    final now = DateTime.now();
    if (_lastShownOrderId == orderId &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(seconds: 2)) {
      return;
    }
    if (_dialogOpen) {
      await storePending(orderId: orderId, description: description);
      return;
    }

    if (Get.context == null) {
      await storePending(orderId: orderId, description: description);
      return;
    }

    _lastShownOrderId = orderId;
    _lastShownAt = now;
    _shownOrderIds.add(orderId);
    await _markDismissed(orderId);
    if (clearPendingOnShow) {
      await clearPending(orderId: orderId);
    }

    _refreshOrderUi(orderId);

    final body = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : 'vendor_order_ready_popup_body'.trParams({
            'order': orderId.toString(),
          });

    _dialogOpen = true;
    try {
      await Get.dialog(
        Dialog(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!)
                        .primaryColor
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'order_ready_for_pickup'.tr,
                  textAlign: TextAlign.center,
                  style: rubikBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${'order'.tr} # $orderId',
                  textAlign: TextAlign.center,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(Get.context!)
                        .textTheme
                        .bodyLarge
                        ?.color
                        ?.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                QuikseeButtonWidget(
                  btnTxt: 'check'.tr,
                  withIcon: true,
                  icon: Icons.check_rounded,
                  onTap: () async {
                    await dismissForOrder(orderId);
                    if (Get.isDialogOpen ?? false) {
                      Get.back();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
        name: 'vendor_ready_popup_$orderId',
      );
    } finally {
      _dialogOpen = false;
      await clearPending(orderId: orderId);
      unawaited(processPending());
    }
  }

  static Future<void> _ensureCurrentOrdersLoaded() async {
    if (!Get.isRegistered<OrderController>()) return;
    final oc = Get.find<OrderController>();
    if (oc.currentOrders.isNotEmpty || oc.scheduledCurrentOrders.isNotEmpty) {
      _currentOrdersFetchAttempted = true;
      return;
    }
    try {
      await oc.refreshCurrentOrdersOnly(promptAccept: false);
    } catch (_) {}
    _currentOrdersFetchAttempted = true;
  }

  static OrderModel? _findActiveOrder(int orderId) {
    if (!Get.isRegistered<OrderController>()) return null;
    final oc = Get.find<OrderController>();
    for (final order in [
      ...oc.currentOrders,
      ...oc.scheduledCurrentOrders,
    ]) {
      if (order.id == orderId) return order;
    }
    for (final list in [
      oc.deliveredOrderHistory,
      oc.allOrderHistory,
    ]) {
      if (list == null) continue;
      for (final order in list) {
        if (order.id == orderId) return order;
      }
    }
    return null;
  }

  static bool _isStatusPickupRelevant(String? status) {
    final s = OrderStatusHelper.normalize(status);
    if (s.isEmpty) return true;
    if (s == OrderStatusHelper.delivered ||
        s == OrderStatusHelper.canceled ||
        s == 'cancelled' ||
        s == OrderStatusHelper.returned ||
        s == OrderStatusHelper.failed ||
        s == OrderStatusHelper.outForDelivery) {
      return false;
    }
    return s == OrderStatusHelper.confirmed ||
        s == OrderStatusHelper.reachedRestaurant ||
        s == OrderStatusHelper.processing;
  }

  static Future<bool> _isPickupRelevant(int orderId) async {
    final order = _findActiveOrder(orderId);
    if (order != null) {
      return _isStatusPickupRelevant(order.orderStatus);
    }
    if (_currentOrdersFetchAttempted) return false;
    return true;
  }

  static Future<void> _ensureDismissedLoaded() async {
    if (_dismissedLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getStringList(AppConstants.dismissedVendorReadyOrderIds) ?? [];
    for (final value in raw) {
      final id = int.tryParse(value);
      if (id != null && id > 0) _shownOrderIds.add(id);
    }
    _dismissedLoaded = true;
  }

  static Future<bool> _wasDismissed(int orderId) async {
    await _ensureDismissedLoaded();
    return _shownOrderIds.contains(orderId);
  }

  static Future<void> _markDismissed(int orderId) async {
    if (orderId <= 0) return;
    await _ensureDismissedLoaded();
    if (!_shownOrderIds.add(orderId) && _dismissedLoaded) {
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = _shownOrderIds.toList()..sort();
    final trimmed = ids.length > 120 ? ids.sublist(ids.length - 120) : ids;
    await prefs.setStringList(
      AppConstants.dismissedVendorReadyOrderIds,
      trimmed.map((e) => '$e').toList(),
    );
  }

  static void _refreshOrderUi(int orderId) {
    try {
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().refreshCurrentOrdersOnly(
          promptAccept: false,
        );
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<OrderDetailsController>()) {
        final details = Get.find<OrderDetailsController>();
        if (details.loadedOrderId == orderId && Get.context != null) {
          details.getOrderDetails(
            orderId.toString(),
            Get.context!,
            silent: true,
          );
        }
      }
    } catch (_) {}
  }
}
