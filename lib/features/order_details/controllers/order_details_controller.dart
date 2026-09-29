import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/distance_payment/domain/models/delivery_distance_info_model.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/helpers/order_collect_amount_helper.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order_details/domain/models/order_details_model.dart';
import 'package:quiksee/features/order_details/domain/services/order_details_service_interface.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/splash/domain/models/config_model.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_group_helper.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/helper/image_size_checker.dart';
import 'package:quiksee/helper/gps_location_helper.dart';
import 'package:quiksee/helper/location_permission_helper.dart';
import 'package:quiksee/helper/vendor_ready_popup_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OrderActionType { cancel, reschedule, pause, resume}

class OrderDetailsController extends GetxController implements GetxService {
  final OrderDetailsServiceInterface orderDetailsServiceInterface;
  OrderDetailsController({required this.orderDetailsServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _detailsFetchComplete = false;
  bool get detailsFetchComplete => _detailsFetchComplete;
  int _orderDetailsFetchToken = 0;
  Future<List<OrderDetailsModel>?>? _primaryOrderDetailsInFlight;
  String? _primaryOrderDetailsInFlightId;
  int? _loadedOrderId;
  int? get loadedOrderId => _loadedOrderId;

  final Set<int> _pickupOtpUnlockedIds = <int>{};
  bool isPickupOtpUnlocked(int? orderId) =>
      orderId != null &&
      orderId > 0 &&
      _pickupOtpUnlockedIds.contains(orderId);

  bool hasCachedDetailsForOrder(int? orderId) {
    if (orderId == null || orderId <= 0) return false;
    return _loadedOrderId == orderId &&
        (_orderDetails?.isNotEmpty ?? false) &&
        _detailsFetchComplete;
  }

  /// Call from OrderDetailsScreen.initState (no notify) so the first frame
  /// shows shimmer for a different/missing order instead of stale cache.
  void prepareForOrderScreen(int? orderId) {
    if (hasCachedDetailsForOrder(orderId)) return;
    _detailsFetchComplete = false;
    if (_loadedOrderId != orderId) {
      _orderDetails = null;
    }
  }

  void clearOrderDetailsCache() {
    _loadedOrderId = null;
    _orderDetails = null;
    _detailsFetchComplete = false;
    _safeUpdate();
  }
  int _orderTypeFilterIndex = 0;
  int get orderTypeFilterIndex => _orderTypeFilterIndex;
  OrderDetailsModel? _orderDetailsModel;
  OrderDetailsModel? get orderDetailsModel => _orderDetailsModel;
  List<OrderDetailsModel>? _orderDetails;
  List<OrderDetailsModel>? get orderDetails => _orderDetails;

  double? _totalPrice;
  double? get totalPrice => _totalPrice;
  set setTotalPrice(double? amount) {
    _totalPrice = amount;
  }

  /// Keep COD collect amount aligned with Payment Info.
  void syncCollectAmount({
    required OrderModel? order,
    double? editDueAmount,
    DeliveryDistanceInfo? distanceInfo,
    bool notify = true,
  }) {
    final amount = OrderCollectAmountHelper.resolve(
      order: order,
      lineItems: _orderDetails,
      distanceInfo: distanceInfo ?? order?.deliveryDistanceInfo,
      editDueAmount: editDueAmount,
      currentOrders: Get.isRegistered<OrderController>()
          ? Get.find<OrderController>().currentOrders
          : null,
    );
    final resolved = ((amount * 100).round()) / 100.0;

    if (editDueAmount != null && editDueAmount > 0) {
      _totalPrice = resolved;
      if (notify) update();
      return;
    }

    final current = _totalPrice;
    if (current != null && current > 0 && resolved > 0) {
      if ((current - resolved).abs() < 0.05) {
        final rounded = ((current * 100).round()) / 100.0;
        if ((current - rounded).abs() > 0.0001) {
          _totalPrice = rounded;
          if (notify) update();
        }
        return;
      }
      // Never replace a higher Payment Info / server total with a lower
      // re-sum (that caused under-collect when latefee was missing).
      if (current > resolved) {
        return;
      }
    }

    _totalPrice = resolved;
    if (notify) update();
  }

  final Map<OrderActionType, String?> _actionReasons = {
    OrderActionType.cancel: null,
    OrderActionType.reschedule: null,
    OrderActionType.pause: null,
    OrderActionType.resume: 'resume',
  };

  String? getReason(OrderActionType type) {
    return _actionReasons[type];
  }

  final List<String> reasonList = [
    'could_not_contact_with_the_customer',
    'customer_cant_collect_the_parcel_now_request_to_deliver_delay',
    'could_not_find_the_location',
    'delivery_man_transport_broken',
    'other'
  ];

  String? _reasonValue = '';
  String? get reasonValue => _reasonValue;

  List<OrderModel>? _orderList;
  List<OrderModel>? get orderList => _orderList != null ? _orderList!.reversed.toList() : _orderList;

  void setReason(OrderActionType type, String? value) {
    _actionReasons[type] = value;
    update();
  }

  Future<List<OrderDetailsModel>?> getOrderDetails(
    String orderID,
    BuildContext context, {
    bool silent = false,
  }) async {
    final normalizedId = orderID.trim();
    if (normalizedId.isEmpty || normalizedId == 'null') {
      if (!silent) {
        _orderDetails = [];
        _detailsFetchComplete = true;
        _safeUpdate();
      }
      return _orderDetails;
    }

    // Quiet background refreshes while COD UPI sheet needs the pipe.
    if (silent && _acceptPaymentSheetOpen) {
      return _orderDetails;
    }

    if (!silent &&
        _primaryOrderDetailsInFlight != null &&
        _primaryOrderDetailsInFlightId == normalizedId) {
      return _primaryOrderDetailsInFlight!;
    }

    final future = _fetchOrderDetails(normalizedId, context, silent: silent);
    if (!silent) {
      _primaryOrderDetailsInFlightId = normalizedId;
      _primaryOrderDetailsInFlight = future;
    }

    try {
      return await future;
    } finally {
      if (!silent && _primaryOrderDetailsInFlightId == normalizedId) {
        _primaryOrderDetailsInFlight = null;
        _primaryOrderDetailsInFlightId = null;
      }
    }
  }

  Future<List<OrderDetailsModel>?> _fetchOrderDetails(
    String normalizedId,
    BuildContext context, {
    required bool silent,
  }) async {
    // not invalidate an in-flight fetch (that left shimmer stuck forever).
    final token = silent ? null : ++_orderDetailsFetchToken;

    if (!silent) {
      _detailsFetchComplete = false;
      _orderDetails = null;
      _safeUpdate();
    }

    List<OrderDetailsModel> parsed = [];
    var attempts = silent ? 1 : 2;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await orderDetailsServiceInterface.getOrderDetails(
          orderID: normalizedId,
        );
        if (response.body != null && response.statusCode == 200) {
          parsed = [];
          if (response.body is List) {
            for (final orderDetail in response.body) {
              if (orderDetail is Map) {
                try {
                  parsed.add(
                    OrderDetailsModel.fromJson(
                      Map<String, dynamic>.from(orderDetail),
                    ),
                  );
                } catch (_) {}
              }
            }
          }
          break;
        } else if (!silent && attempt == attempts - 1) {
          ApiChecker.checkApi(response);
        }
      } catch (_) {
        if (!silent && attempt == attempts - 1) {
          parsed = [];
        }
      }
      if (parsed.isNotEmpty) break;
      if (!silent && attempt < attempts - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    if (!silent && token != _orderDetailsFetchToken) {
      return _orderDetails;
    }

    if (parsed.isNotEmpty) {
      final previousModel = _orderDetails?.first.orderModel;
      final previousStatus = previousModel?.orderStatus;
      _orderDetails = parsed;
      _loadedOrderId = int.tryParse(normalizedId);
      final orderModel = parsed.first.orderModel;
      if (orderModel != null &&
          previousStatus != null &&
          !OrderStatusHelper.isTerminalStatus(previousStatus)) {
        final prevRank = OrderStatusHelper.statusProgressRank(previousStatus);
        final newRank =
            OrderStatusHelper.statusProgressRank(orderModel.orderStatus);
        if (prevRank > newRank) {
          orderModel.orderStatus = previousStatus;
        }
      }
      // Silent/lean refresh must not wipe COD collect fields (Accept Payment).
      if (orderModel != null && previousModel != null) {
        final method = (orderModel.paymentMethod ?? '').trim();
        final prevMethod = (previousModel.paymentMethod ?? '').trim();
        if (method.isEmpty && prevMethod.isNotEmpty) {
          orderModel.paymentMethod = previousModel.paymentMethod;
        }
        final payStatus = (orderModel.paymentStatus ?? '').trim();
        final prevPayStatus = (previousModel.paymentStatus ?? '').trim();
        if (payStatus.isEmpty && prevPayStatus.isNotEmpty) {
          orderModel.paymentStatus = previousModel.paymentStatus;
        }
      }
      _upgradeOrderStatusFromLiveList(orderModel);
      if (orderModel != null && Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().applyPickupOtpFields(orderModel);
      }
      if (orderModel?.id != null && orderModel!.pickupVerificationStatus == 1) {
        _pickupOtpUnlockedIds.add(orderModel.id!);
      }
      _maybePrefetchCodUpiForOrder(orderModel);
      if (silent) {
        _safeUpdate();
      }
    } else if (!silent) {
      _orderDetails = [];
      _loadedOrderId = int.tryParse(normalizedId);
    }

    if (!silent) {
      _detailsFetchComplete = true;
      _safeUpdate();
    }
    return _orderDetails;
  }

  /// Avoid "setState() called during build" when opened from initState/mount.
  void _safeUpdate() {
    if (isClosed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      update();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) update();
    });
  }

  Future<bool> updateOrderStatus({
    int? orderId,
    String? status,
    BuildContext? context,
    OrderModel? anchorOrder,
    bool showLoadingOverlay = false,
    bool releaseSliderEarly = false,
  }) async {
    if (orderId == null || status == null) return false;

    if (showLoadingOverlay) {
      _isLoading = true;
      update();
    }

    if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().pauseBackgroundSync();
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().pauseBackgroundOrderPolls();
    }

    final optimisticEligible = !OrderStatusHelper.isTerminalStatus(status);
    final deliverEarly = releaseSliderEarly && status == 'delivered';
    final deferResume =
        releaseSliderEarly && (optimisticEligible || deliverEarly);

    try {
      double? latitude;
      double? longitude;
      String? location;
      if (status == 'out_for_delivery' ||
          status == OrderStatusHelper.reachedRestaurant) {
        final pos = await _resolvePositionForOutForDelivery(context);
        if (pos == null) {
          showQuikseeSnackBarWidget('gps_required_for_accept'.tr);
          if (showLoadingOverlay) {
            _isLoading = false;
            update();
          }
          return false;
        }
        latitude = pos.latitude;
        longitude = pos.longitude;
        location = '${pos.latitude}, ${pos.longitude}';
      }

      final pool = Get.isRegistered<OrderController>()
          ? [
              ...Get.find<OrderController>().currentOrders,
              ...Get.find<OrderController>().scheduledCurrentOrders,
            ]
          : <OrderModel>[];
      var anchor = anchorOrder ?? OrderModel(id: orderId);
      if (anchorOrder == null) {
        for (final order in pool) {
          if (order.id == orderId) {
            anchor = order;
            break;
          }
        }
        if (!OrderGroupHelper.isCombinedCheckout(anchor) &&
            _orderDetails?.isNotEmpty == true) {
          final detailOrder = _orderDetails!.first.orderModel;
          if (detailOrder?.id == orderId) {
            anchor = detailOrder!;
          }
        }
      }

      final targets = OrderGroupHelper.ordersForStatusTransition(
        anchor,
        status,
        pool,
      );
      final targetIds = targets
          .map((order) => order.id)
          .whereType<int>()
          .toSet()
          .toList();

      if (!targetIds.contains(orderId)) {
        targetIds.insert(0, orderId);
      } else {
        targetIds.remove(orderId);
        targetIds.insert(0, orderId);
      }

      final Map<int, String?> previousStatuses = {};
      var optimisticApplied = false;

      if (deliverEarly) {
        for (final id in targetIds) {
          previousStatuses[id] = _currentStatusForOrder(id);
        }
        _applyStatusLocally(targetIds, status);
        if (Get.isRegistered<OrderController>()) {
          for (final id in targetIds) {
            Get.find<OrderController>().setLocalOrderStatus(id, status);
          }
        }
        _applyDeliveredSideEffects(orderId);
        optimisticApplied = true;
        update();
        unawaited(
          _finalizeStatusUpdate(
            orderId: orderId,
            status: status,
            targetIds: targetIds,
            anchor: anchor,
            latitude: latitude,
            longitude: longitude,
            location: location,
            previousStatuses: previousStatuses,
            optimisticApplied: optimisticApplied,
            context: context,
            resumeBackgroundWhenDone: true,
          ),
        );
        if (showLoadingOverlay) {
          _isLoading = false;
          update();
        }
        return true;
      }

      if (optimisticEligible) {
        for (final id in targetIds) {
          previousStatuses[id] = _currentStatusForOrder(id);
        }
        _applyStatusLocally(targetIds, status);
        if (Get.isRegistered<OrderController>()) {
          for (final id in targetIds) {
            Get.find<OrderController>().setLocalOrderStatus(id, status);
          }
        }
        _applyStatusSideEffectsEarly(
          orderId: orderId,
          status: status,
          anchor: anchor,
          targetIds: targetIds,
        );
        optimisticApplied = true;
        update();
      }

      if (deferResume) {
        unawaited(
          _finalizeStatusUpdate(
            orderId: orderId,
            status: status,
            targetIds: targetIds,
            anchor: anchor,
            latitude: latitude,
            longitude: longitude,
            location: location,
            previousStatuses: previousStatuses,
            optimisticApplied: optimisticApplied,
            context: context,
            resumeBackgroundWhenDone: true,
          ),
        );
        return true;
      }

      final success = await _finalizeStatusUpdate(
        orderId: orderId,
        status: status,
        targetIds: targetIds,
        anchor: anchor,
        latitude: latitude,
        longitude: longitude,
        location: location,
        previousStatuses: previousStatuses,
        optimisticApplied: optimisticApplied,
        context: context,
        resumeBackgroundWhenDone: false,
      );

      if (showLoadingOverlay) {
        _isLoading = false;
        update();
      }
      return success;
    } finally {
      if (!deferResume) {
        if (Get.isRegistered<AssignmentController>()) {
          Get.find<AssignmentController>().resumeBackgroundSync();
        }
        if (Get.isRegistered<OrderController>()) {
          Get.find<OrderController>().resumeBackgroundOrderPolls();
        }
      }
    }
  }

  String? _currentStatusForOrder(int orderId) {
    if (_orderDetails != null) {
      for (final line in _orderDetails!) {
        if (line.orderModel?.id == orderId) {
          return line.orderModel?.orderStatus;
        }
      }
    }
    if (Get.isRegistered<OrderController>()) {
      final orderCtrl = Get.find<OrderController>();
      for (final order in [
        ...orderCtrl.currentOrders,
        ...orderCtrl.scheduledCurrentOrders,
      ]) {
        if (order.id == orderId) return order.orderStatus;
        for (final child in order.combinedOrders ?? const <OrderModel>[]) {
          if (child.id == orderId) return child.orderStatus;
        }
      }
    }
    return null;
  }

  OrderModel _navOrderForStatusTransition({
    required OrderModel anchor,
    required int orderId,
    required String status,
  }) {
    OrderModel navOrder = anchor;
    final detailOrder = _orderDetails
        ?.map((e) => e.orderModel)
        .whereType<OrderModel>()
        .where((o) => o.id == orderId)
        .firstOrNull;
    if (detailOrder != null) {
      navOrder = detailOrder;
    }
    navOrder.orderStatus = status;
    if ((navOrder.combinedOrders == null ||
            navOrder.combinedOrders!.length < 2) &&
        (anchor.combinedOrders?.length ?? 0) >= 2) {
      navOrder.combinedOrders = anchor.combinedOrders;
      navOrder.isCombinedCheckout = true;
    }
    return navOrder;
  }

  void _applyDeliveredSideEffects(int orderId) {
    if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().markDriverBusy(false);
    }
    if (Get.isRegistered<RiderController>()) {
      Get.find<RiderController>().stopGpsBroadcast();
      Get.find<RiderController>().stopMapTracking(clearExternalNav: true);
    }
    unawaited(VendorReadyPopupHelper.dismissForOrder(orderId));
  }

  void _applyStatusSideEffectsEarly({
    required int orderId,
    required String status,
    required OrderModel anchor,
    required List<int> targetIds,
  }) {
    if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().markDriverBusy(
        status != 'delivered' && status != 'canceled' && status != 'cancelled',
      );
    }

    if (status == 'out_for_delivery') {
      if (Get.isRegistered<RiderController>()) {
        Get.find<RiderController>().startGpsBroadcast(orderId);
        final navOrder = _navOrderForStatusTransition(
          anchor: anchor,
          orderId: orderId,
          status: status,
        );
        unawaited(
          Get.find<RiderController>().retargetNavigationForOrder(navOrder),
        );
      }
      unawaited(VendorReadyPopupHelper.dismissForOrder(orderId));
      prefetchCodUpiQr(orderId);
    } else if (status == 'reached_restaurant') {
      prefetchCodUpiQr(orderId);
    } else if (status == 'arrived_at_customer') {
      prefetchCodUpiQr(orderId);
    } else if (status == 'processing') {
      unawaited(VendorReadyPopupHelper.dismissForOrder(orderId));
      prefetchCodUpiQr(orderId);
      if (Get.isRegistered<RiderController>()) {
        final navOrder = _navOrderForStatusTransition(
          anchor: anchor,
          orderId: orderId,
          status: status,
        );
        unawaited(
          Get.find<RiderController>().retargetNavigationForOrder(navOrder),
        );
      }
    }
  }

  Future<bool> _finalizeStatusUpdate({
    required int orderId,
    required String status,
    required List<int> targetIds,
    required OrderModel anchor,
    required double? latitude,
    required double? longitude,
    required String? location,
    required Map<int, String?> previousStatuses,
    required bool optimisticApplied,
    BuildContext? context,
    required bool resumeBackgroundWhenDone,
  }) async {
    try {
      var primarySuccess = false;
      for (var i = 0; i < targetIds.length; i++) {
        final id = targetIds[i];
        final success = await _postOrderStatusUpdate(
          orderId: id,
          status: status,
          latitude: latitude,
          longitude: longitude,
          location: location,
          showSnackBar: i == 0 && targetIds.length == 1 && !optimisticApplied,
        );
        if (i == 0) {
          primarySuccess = success;
        }
      }

      if (!primarySuccess) {
        if (optimisticApplied && status == 'delivered') {
          for (var retry = 0; retry < 2 && !primarySuccess; retry++) {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            primarySuccess = await _postOrderStatusUpdate(
              orderId: orderId,
              status: status,
              latitude: latitude,
              longitude: longitude,
              location: location,
              showSnackBar: false,
            );
          }
          if (!primarySuccess) {
            showQuikseeSnackBarWidget(
              'Could not sync delivery to server. Order may still show as active — check order history.',
              isError: true,
            );
          }
          return primarySuccess;
        }
        if (optimisticApplied) {
          for (final entry in previousStatuses.entries) {
            final previous = entry.value;
            if (previous == null) continue;
            _applyStatusLocally([entry.key], previous);
            if (Get.isRegistered<OrderController>()) {
              Get.find<OrderController>().setLocalOrderStatus(
                entry.key,
                previous,
              );
            }
          }
          update();
        }
        return false;
      }

      if (!optimisticApplied) {
        if (Get.isRegistered<AssignmentController>()) {
          Get.find<AssignmentController>().markDriverBusy(
            status != 'delivered' &&
                status != 'canceled' &&
                status != 'cancelled',
          );
        }

        if (status == 'out_for_delivery') {
          Get.find<RiderController>().startGpsBroadcast(orderId);
          unawaited(VendorReadyPopupHelper.dismissForOrder(orderId));
          // Warm Accept Payment QR while rider is en route.
          prefetchCodUpiQr(orderId);
        } else if (status == 'reached_restaurant') {
          prefetchCodUpiQr(orderId);
        } else if (status == 'arrived_at_customer') {
          prefetchCodUpiQr(orderId);
        } else if (status == 'processing') {
          unawaited(VendorReadyPopupHelper.dismissForOrder(orderId));
          prefetchCodUpiQr(orderId);
        } else if (status == 'delivered') {
          _applyDeliveredSideEffects(orderId);
        }

        _applyStatusLocally(targetIds, status);
        if (Get.isRegistered<OrderController>()) {
          for (final id in targetIds) {
            Get.find<OrderController>().setLocalOrderStatus(id, status);
          }
        }

        if (status == 'processing' || status == 'out_for_delivery') {
          final navOrder = _navOrderForStatusTransition(
            anchor: anchor,
            orderId: orderId,
            status: status,
          );
          unawaited(
            Get.find<RiderController>().retargetNavigationForOrder(navOrder),
          );
        }

        update();
      }

      if (targetIds.length > 1) {
        showQuikseeSnackBarWidget(
          'combined_orders_status_updated'
              .trParams({'count': '${targetIds.length}'}),
          isError: false,
        );
      }

      unawaited(
        getOrderDetails('$orderId', context ?? Get.context!, silent: true),
      );
      unawaited(
        Get.find<OrderController>().getCurrentOrders(promptAccept: false),
      );
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!Get.isRegistered<OrderController>()) return;
        final orders = Get.find<OrderController>();
        unawaited(orders.refreshAssignedOrderHistory());
        if (status == 'delivered') {
          unawaited(orders.getAllOrderHistory(
            orders.dateType,
            'delivered',
            '',
            '',
            '',
            0,
            force: true,
          ));
        } else if (status == 'out_for_delivery') {
          unawaited(orders.getAllOrderHistory(
            orders.dateType,
            'out_for_delivery',
            '',
            '',
            '',
            0,
            force: true,
          ));
        }
      });
      if (status == 'delivered') {
        unawaited(Get.find<ProfileController>().refreshAfterDelivery());
      } else {
        unawaited(Get.find<ProfileController>().getProfile(silent: true));
      }

      return true;
    } finally {
      if (resumeBackgroundWhenDone) {
        if (Get.isRegistered<AssignmentController>()) {
          Get.find<AssignmentController>().resumeBackgroundSync();
        }
        if (Get.isRegistered<OrderController>()) {
          Get.find<OrderController>().resumeBackgroundOrderPolls();
        }
      }
    }
  }

  Future<bool> _postOrderStatusUpdate({
    required int orderId,
    required String status,
    double? latitude,
    double? longitude,
    String? location,
    bool showSnackBar = true,
  }) async {
    final response = await orderDetailsServiceInterface.updateOrderStatus(
      orderId: orderId,
      status: status,
      latitude: latitude,
      longitude: longitude,
      location: location,
    );

    if (response.statusCode == 200 &&
        response.body != null &&
        response.body is Map) {
      final body = Map<String, dynamic>.from(response.body as Map);
      final successRaw = body['success'];
      final failed = successRaw == 0 ||
          successRaw == false ||
          successRaw == '0';
      if (failed) {
        final message = body['message']?.toString().toLowerCase() ?? '';
        if (status == 'delivered' && message.contains('already delivered')) {
          return true;
        }
        if (showSnackBar) {
          ApiChecker.checkApi(response);
        }
        return false;
      }
      if (showSnackBar) {
        final message = body['message']?.toString();
        if (message != null && message.isNotEmpty) {
          showQuikseeSnackBarWidget(message, isError: false);
        }
      }
      // Apply pickup OTP fields from status update (Reach Store generates OTP).
      _applyPickupOtpFromMap(orderId, body);
      return true;
    }

    if (showSnackBar) {
      ApiChecker.checkApi(response);
    }
    return false;
  }

  /// Patch details + in-memory models immediately so swipe UI advances
  /// even when order-details API still returns a stale status.
  void _applyStatusLocally(List<int> orderIds, String status) {
    final nextRank = OrderStatusHelper.statusProgressRank(status);
    final nextIsTerminal = OrderStatusHelper.isTerminalStatus(status);
    void patch(OrderModel? order) {
      if (order == null || order.id == null) return;
      if (!orderIds.contains(order.id)) return;
      final currentTerminal =
          OrderStatusHelper.isTerminalStatus(order.orderStatus);
      // Don't revive a terminal order with an earlier step status.
      if (currentTerminal && !nextIsTerminal) return;
      final currentRank =
          OrderStatusHelper.statusProgressRank(order.orderStatus);
      if (nextIsTerminal || nextRank >= currentRank) {
        order.orderStatus = status;
      }
      if (order.combinedOrders != null) {
        for (final child in order.combinedOrders!) {
          if (child.id != null && orderIds.contains(child.id)) {
            final childTerminal =
                OrderStatusHelper.isTerminalStatus(child.orderStatus);
            if (childTerminal && !nextIsTerminal) continue;
            final childRank =
                OrderStatusHelper.statusProgressRank(child.orderStatus);
            if (nextIsTerminal || nextRank >= childRank) {
              child.orderStatus = status;
            }
          }
        }
      }
    }

    if (_orderDetails != null) {
      for (final line in _orderDetails!) {
        patch(line.orderModel);
      }
    }
  }

  void _upgradeOrderStatusFromLiveList(OrderModel? order) {
    if (order?.id == null || !Get.isRegistered<OrderController>()) return;
    final orderCtrl = Get.find<OrderController>();
    final liveOrders = [
      ...orderCtrl.currentOrders,
      ...orderCtrl.scheduledCurrentOrders,
    ];
    for (final live in liveOrders) {
      if (live.id == order!.id) {
        _preferHigherStatus(order, live.orderStatus);
        _preservePaymentCollectFields(order, live);
        return;
      }
      for (final child in live.combinedOrders ?? const <OrderModel>[]) {
        if (child.id == order.id) {
          _preferHigherStatus(order, child.orderStatus);
          _preservePaymentCollectFields(order, child);
          return;
        }
      }
    }
  }

  void _preservePaymentCollectFields(OrderModel target, OrderModel source) {
    final method = (target.paymentMethod ?? '').trim();
    final sourceMethod = (source.paymentMethod ?? '').trim();
    if (method.isEmpty && sourceMethod.isNotEmpty) {
      target.paymentMethod = source.paymentMethod;
    }
    final payStatus = (target.paymentStatus ?? '').trim();
    final sourcePayStatus = (source.paymentStatus ?? '').trim();
    if (payStatus.isEmpty && sourcePayStatus.isNotEmpty) {
      target.paymentStatus = source.paymentStatus;
    }
  }

  void _preferHigherStatus(OrderModel target, String? candidate) {
    if ((candidate ?? '').trim().isEmpty) return;
    if (OrderStatusHelper.isTerminalStatus(target.orderStatus)) return;
    if (OrderStatusHelper.isTerminalStatus(candidate)) {
      target.orderStatus = candidate;
      return;
    }
    if (OrderStatusHelper.statusProgressRank(candidate) >
        OrderStatusHelper.statusProgressRank(target.orderStatus)) {
      target.orderStatus = candidate;
    }
  }

  void _applyPickupOtpFromMap(int orderId, Map<String, dynamic> body) {
    void patch(OrderModel? order) {
      if (order == null || order.id != orderId) return;
      // Never downgrade verified → locked.
      final incomingStatus =
          int.tryParse('${body['pickup_verification_status'] ?? ''}');
      if (order.pickupVerificationStatus == 1 && incomingStatus != 1) {
        return;
      }
      if (body.containsKey('food_pickup_otp_enabled')) {
        order.foodPickupOtpEnabled =
            int.tryParse('${body['food_pickup_otp_enabled']}');
      }
      if (body.containsKey('pickup_verification_status')) {
        order.pickupVerificationStatus = incomingStatus;
      }
      if (body.containsKey('pickup_otp_required')) {
        order.pickupOtpRequired =
            int.tryParse('${body['pickup_otp_required']}');
      }
      if (body.containsKey('can_pickup')) {
        order.canPickup = int.tryParse('${body['can_pickup']}');
      }
      if (order.pickupVerificationStatus == 1) {
        _pickupOtpUnlockedIds.add(orderId);
        order.pickupVerificationCode = null;
        order.pickupOtpRequired = 0;
        order.canPickup = 1;
      } else if (body.containsKey('pickup_verification_code')) {
        final code = body['pickup_verification_code']?.toString();
        order.pickupVerificationCode =
            (code != null && code.isNotEmpty && code != 'null') ? code : null;
      }
      if (body.containsKey('pickup_verified_at')) {
        order.pickupVerifiedAt = body['pickup_verified_at']?.toString();
      }
      if (body.containsKey('store_wait_active')) {
        order.storeWaitActive =
            int.tryParse('${body['store_wait_active']}');
      }
      if (body.containsKey('store_wait_enabled')) {
        order.storeWaitEnabled =
            int.tryParse('${body['store_wait_enabled']}');
      }
      if (body.containsKey('store_wait_started_at')) {
        order.storeWaitStartedAt = body['store_wait_started_at']?.toString();
      }
      if (body.containsKey('store_wait_deadline_at')) {
        order.storeWaitDeadlineAt = body['store_wait_deadline_at']?.toString();
      }
      if (body.containsKey('store_wait_remaining_seconds')) {
        order.storeWaitRemainingSeconds =
            int.tryParse('${body['store_wait_remaining_seconds']}');
      }
      if (body.containsKey('store_wait_overdue')) {
        order.storeWaitOverdue =
            int.tryParse('${body['store_wait_overdue']}');
      }
      if (body.containsKey('can_poke')) {
        order.canPoke = int.tryParse('${body['can_poke']}');
      }
      if (body.containsKey('poke_count')) {
        order.pokeCount = int.tryParse('${body['poke_count']}');
      }
      if (body.containsKey('poke_max')) {
        order.pokeMax = int.tryParse('${body['poke_max']}');
      }
      if (body.containsKey('next_poke_at')) {
        order.nextPokeAt = body['next_poke_at']?.toString();
      }
      if (body.containsKey('store_last_poke_at')) {
        order.storeLastPokeAt = body['store_last_poke_at']?.toString();
      }
      if (body.containsKey('store_wait_packed')) {
        order.storeWaitPacked =
            int.tryParse('${body['store_wait_packed']}');
      }
      if (body.containsKey('vendor_ready_at')) {
        final readyAt = body['vendor_ready_at']?.toString();
        if (readyAt != null && readyAt.isNotEmpty && readyAt != 'null') {
          order.vendorReadyAt = readyAt;
        }
      }
      if (body.containsKey('order_transfer_enabled')) {
        order.orderTransferEnabled =
            int.tryParse('${body['order_transfer_enabled']}');
      }
      if (body.containsKey('order_transfer_already_done')) {
        order.orderTransferAlreadyDone =
            int.tryParse('${body['order_transfer_already_done']}');
      }
      if (body.containsKey('order_transfer_locked')) {
        order.orderTransferLocked =
            int.tryParse('${body['order_transfer_locked']}');
      }
      if (body.containsKey('order_transfer_unlock_mode')) {
        final mode = body['order_transfer_unlock_mode']?.toString();
        if (mode != null && mode.isNotEmpty && mode != 'null') {
          order.orderTransferUnlockMode = mode;
        }
      }
      if (body.containsKey('order_transfer_after_reach_seconds')) {
        order.orderTransferAfterReachSeconds = int.tryParse(
          '${body['order_transfer_after_reach_seconds']}',
        );
      }
      if (body.containsKey('order_transfer_block_after_pickup')) {
        order.orderTransferBlockAfterPickup = int.tryParse(
          '${body['order_transfer_block_after_pickup']}',
        );
      }
      if (body.containsKey('order_transfer_block_out_for_delivery')) {
        order.orderTransferBlockOutForDelivery = int.tryParse(
          '${body['order_transfer_block_out_for_delivery']}',
        );
      }
    }

    if (_orderDetails != null) {
      for (final line in _orderDetails!) {
        patch(line.orderModel);
      }
    }
    if (Get.isRegistered<OrderController>()) {
      final oc = Get.find<OrderController>();
      for (final o in oc.currentOrders) {
        if (o.id == orderId) {
          patch(o);
          oc.applyPickupOtpFields(o);
          break;
        }
        for (final c in o.combinedOrders ?? const <OrderModel>[]) {
          if (c.id == orderId) {
            patch(c);
            oc.applyPickupOtpFields(c);
            break;
          }
        }
      }
    }
    update();
  }

  void markPickupOtpVerified(int orderId, {String? verifiedAt}) {
    if (orderId <= 0) return;
    _pickupOtpUnlockedIds.add(orderId);
    _applyPickupOtpFromMap(orderId, {
      'food_pickup_otp_enabled': 1,
      'pickup_verification_status': 1,
      'pickup_otp_required': 0,
      'can_pickup': 1,
      'pickup_verification_code': null,
      if (verifiedAt != null) 'pickup_verified_at': verifiedAt,
    });
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().markPickupOtpVerified(
        orderId,
        verifiedAt: verifiedAt,
      );
    }
    update();
  }

  /// Lightweight pickup-otp status check (avoids heavy order-details race).
  Future<bool> refreshPickupOtpStatus(int orderId) async {
    if (orderId <= 0 || !Get.isRegistered<ApiClient>()) return false;
    if (isPickupOtpUnlocked(orderId)) return true;
    try {
      final response = await Get.find<ApiClient>().postData(
        AppConstants.pickupOtpUri,
        {'order_id': orderId, 'resend': 0},
      );
      if (response.statusCode == 200 && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        final verified =
            int.tryParse('${body['pickup_verification_status'] ?? ''}') == 1;
        _applyPickupOtpFromMap(orderId, body);
        if (verified) {
          markPickupOtpVerified(
            orderId,
            verifiedAt: body['pickup_verified_at']?.toString(),
          );
          return true;
        }
        return false;
      }
    } catch (_) {
      // non-blocking
    }
    return false;
  }

  Future<Position?> _resolvePositionForOutForDelivery(BuildContext? context) async {
    Position? cached;
    if (Get.isRegistered<RiderController>()) {
      cached = Get.find<RiderController>().position;
      if (cached != null &&
          GpsLocationHelper.hasValidCoordinates(
            cached.latitude,
            cached.longitude,
          )) {
        return cached;
      }
    }

    final bool locationReady = await LocationPermissionHelper.ensureLocationReady(
      context: context,
      showDialog: cached == null,
    );
    if (!locationReady) return null;

    return GpsLocationHelper.resolveForStatusUpdate(cachedPosition: cached);
  }

  Future<bool> cancelOrderStatus({int? orderId, String? cause,BuildContext? context}) async {
    _isLoading = true;
    update();
    bool _isSuccess = await orderDetailsServiceInterface.cancelOrderStatus(orderId: orderId,  cause: cause);
    if(_isSuccess) {
      getOrderDetails(orderId.toString(), Get.context!, silent: true);
    }

    _isLoading = false;
    update();
    return _isSuccess;
  }

  Future<bool> rescheduleOrderStatus({int? orderId, String? deliveryDate, String? cause, BuildContext? context}) async {
    _isLoading = true;
    update();
    bool _isSuccess = await orderDetailsServiceInterface.rescheduleOrder(orderId: orderId, deliveryDate: deliveryDate, cause: cause);

    if(_isSuccess) {
      showQuikseeSnackBarWidget('order_status_rescheduled_successfully'.tr, isError: false);
    }
    _isLoading = false;
    update();
    return _isSuccess;
  }

  Future<bool> pauseAndResumeOrder({int? orderId, int? isPos, String? cause, BuildContext? context}) async {
    _isLoading = true;
    update();
    bool _isSuccess = await orderDetailsServiceInterface.pauseAndResumeOrder(orderId: orderId, isPos: isPos, cause: cause);
    Get.find<OrderController>().getCurrentOrders();
    _isLoading = false;
    update();
    return _isSuccess;
  }

  Future<Response?> updatePaymentStatus({int? orderId, String? status}) async {
    if (orderId == null || orderId <= 0) {
      return null;
    }

    // Combined COD: mark every unpaid sibling paid, not just the lead.
    if (status == 'paid' && Get.isRegistered<OrderController>()) {
      final pool = Get.find<OrderController>().currentOrders;
      OrderModel? anchor;
      for (final order in OrderGroupHelper.expandOrderPool(pool)) {
        if (order.id == orderId) {
          anchor = order;
          break;
        }
      }
      if (anchor != null && OrderGroupHelper.isCombinedCheckout(anchor)) {
        final ids = OrderGroupHelper.unpaidCodOrderIds(anchor, pool);
        final targetIds = ids.isNotEmpty ? ids : [orderId];
        Response? last;
        for (final id in targetIds) {
          last = await orderDetailsServiceInterface.updatePaymentStatus(
            orderId: id,
            status: status,
          );
          if (last?.statusCode == 200) {
            _applyPaidLocally(id);
          }
        }
        update();
        return last;
      }
    }

    Response apiResponse = await orderDetailsServiceInterface.updatePaymentStatus(
      orderId: orderId,
      status: status,
    );
    if (apiResponse.statusCode == 200 && status == 'paid') {
      _applyPaidLocally(orderId);
    }
    update();
    return apiResponse;
  }

  final Set<int> _codPaymentCollectedOrderIds = {};
  final Set<int> _reachedRestaurantOrderIds = {};
  bool _reachedRestaurantLoaded = false;

  bool _acceptPaymentSheetOpen = false;
  bool get isAcceptPaymentSheetOpen => _acceptPaymentSheetOpen;

  void setAcceptPaymentSheetOpen(bool open) {
    _acceptPaymentSheetOpen = open;
  }

  bool isCodPaymentCollected(int? orderId) {
    if (orderId == null || orderId <= 0) return false;
    return _codPaymentCollectedOrderIds.contains(orderId);
  }

  /// Deliver swipe/proceed may run only after payment is confirmed.
  /// COD: cash-in-hand or QR scan (local flag) / server `paid`.
  /// Online prepaid: `paymentStatus == paid`.
  bool isDeliveryPaymentConfirmed(
    OrderModel? order, {
    bool editOrderPaymentDue = false,
  }) {
    if (order == null) return false;
    if (editOrderPaymentDue) {
      return isCodPaymentCollected(order.id);
    }
    if (order.paymentStatus == 'paid' || isCodPaymentCollected(order.id)) {
      return true;
    }
    // Unpaid COD (or other unpaid) must collect via Accept Payment first.
    return false;
  }

  bool hasReachedRestaurant(int? orderId) {
    if (orderId == null || orderId <= 0) return false;
    return _reachedRestaurantOrderIds.contains(orderId);
  }

  Future<void> ensureReachedRestaurantLoaded() async {
    if (_reachedRestaurantLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          prefs.getStringList(AppConstants.reachedRestaurantOrderIds) ?? [];
      for (final value in raw) {
        final id = int.tryParse(value);
        if (id != null && id > 0) _reachedRestaurantOrderIds.add(id);
      }
    } catch (_) {}
    _reachedRestaurantLoaded = true;
  }

  Future<void> _persistReachedRestaurantIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = _reachedRestaurantOrderIds.toList()..sort();
    final trimmed = ids.length > 80 ? ids.sublist(ids.length - 80) : ids;
    await prefs.setStringList(
      AppConstants.reachedRestaurantOrderIds,
      trimmed.map((e) => '$e').toList(),
    );
  }

  void _applyReachedLocally(int orderId) {
    _reachedRestaurantOrderIds.add(orderId);
    void patch(OrderModel? order) {
      if (order == null || order.id != orderId) return;
      final status = (order.orderStatus ?? '').toLowerCase();
      if (status == OrderStatusHelper.confirmed || status.isEmpty) {
        order.orderStatus = OrderStatusHelper.reachedRestaurant;
      }
      order.storeWaitEnabled ??= 1;
      order.storeWaitActive ??= 1;
      final started = (order.storeWaitStartedAt ?? '').trim();
      if (started.isEmpty || started == 'null') {
        order.storeWaitStartedAt = DateTime.now().toIso8601String();
      }
    }

    if (orderDetails != null) {
      for (final line in orderDetails!) {
        if (line.orderId == orderId || line.orderModel?.id == orderId) {
          patch(line.orderModel);
        }
      }
    }
    if (Get.isRegistered<OrderController>()) {
      final orderCtrl = Get.find<OrderController>();
      for (final order in [
        ...orderCtrl.currentOrders,
        ...orderCtrl.scheduledCurrentOrders,
      ]) {
        if (order.id == orderId) {
          patch(order);
        }
        for (final c in order.combinedOrders ?? const <OrderModel>[]) {
          if (c.id == orderId) patch(c);
        }
      }
      orderCtrl.update();
    }
    unawaited(_persistReachedRestaurantIds());
    update();
  }

  void markReachedRestaurantLocally(int orderId) {
    if (orderId <= 0) return;
    unawaited(ensureReachedRestaurantLoaded().then((_) {
      _applyReachedLocally(orderId);
    }));
  }

  /// GPS-gated: only when rider is near the restaurant.
  Future<bool> markReachedRestaurant(OrderModel order) async {
    final orderId = order.id;
    if (orderId == null || orderId <= 0) return false;
    await ensureReachedRestaurantLoaded();
    if (hasReachedRestaurant(orderId) ||
        OrderStatusHelper.isReachedRestaurant(order.orderStatus)) {
      _applyReachedLocally(orderId);
      return true;
    }

    if (!Get.isRegistered<RiderController>()) {
      showQuikseeSnackBarWidget('gps_required_for_accept'.tr);
      return false;
    }

    // Free bandwidth while Reach Store API runs.
    if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().pauseBackgroundSync();
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().pauseBackgroundOrderPolls();
    }

    _isLoading = true;
    update();
    try {
      var workingOrder = order;
      var check =
          await Get.find<RiderController>().checkNearRestaurant(workingOrder);

      if (!check.near && check.errorKey == 'store_location_unavailable') {
        try {
          await getOrderDetails(orderId.toString(), Get.context!, silent: true);
          final detailOrder = _orderDetails?.isNotEmpty == true
              ? _orderDetails!.first.orderModel
              : null;
          if (detailOrder != null && detailOrder.id == orderId) {
            workingOrder = detailOrder;
            check = await Get.find<RiderController>()
                .checkNearRestaurant(workingOrder);
          }
        } catch (_) {}
      }

      if (!check.near) {
        final key = check.errorKey ?? 'not_near_restaurant';
        if (key == 'not_near_restaurant' && check.distanceMeters != null) {
          final meters = check.distanceMeters!.round();
          showQuikseeSnackBarWidget(
            'not_near_restaurant'.trParams({'distance': '$meters'}),
          );
        } else {
          showQuikseeSnackBarWidget(key.tr);
        }
        return false;
      }

      final pos = check.position;
      final apiOk = await _postOrderStatusUpdate(
        orderId: orderId,
        status: OrderStatusHelper.reachedRestaurant,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
        location: pos == null ? null : '${pos.latitude}, ${pos.longitude}',
        showSnackBar: false,
      );

      if (!apiOk) {
        showQuikseeSnackBarWidget(
          'failed_to_update_status'.tr.isNotEmpty &&
                  'failed_to_update_status'.tr != 'failed_to_update_status'
              ? 'failed_to_update_status'.tr
              : 'Could not update status. Try again.',
        );
        return false;
      }

      _applyReachedLocally(orderId);
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().setLocalOrderStatus(
          orderId,
          OrderStatusHelper.reachedRestaurant,
        );
      }
      // OTP + wait timer already applied from status response meta.
      unawaited(getOrderDetails(orderId.toString(), Get.context!, silent: true));
      showQuikseeSnackBarWidget('reached_restaurant_success'.tr, isError: false);
      return true;
    } finally {
      _isLoading = false;
      update();
      if (Get.isRegistered<AssignmentController>()) {
        Get.find<AssignmentController>().resumeBackgroundSync();
      }
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().resumeBackgroundOrderPolls();
      }
    }
  }

  static const Duration _codUpiQrCacheTtl = Duration(minutes: 15);

  final Map<int, Map<String, dynamic>> _codUpiQrCache = {};
  final Map<int, DateTime> _codUpiQrCacheAt = {};
  final Map<int, double?> _codUpiQrCacheAmount = {};
  final Map<int, Future<Map<String, dynamic>?>> _codUpiQrInFlight = {};
  final Map<int, Future<bool>> _codUpiPollInFlight = {};

  void clearCodUpiQrCache(int orderId) {
    if (orderId <= 0) return;
    _codUpiQrCache.remove(orderId);
    _codUpiQrCacheAt.remove(orderId);
    _codUpiQrCacheAmount.remove(orderId);
    _codUpiQrInFlight.remove(orderId);
    _codUpiPollInFlight.remove(orderId);
  }

  /// Warm Razorpay QR + download QR image before sheet opens.
  void prefetchCodUpiQr(int orderId, {double? collectAmount}) {
    if (orderId <= 0 || isCodPaymentCollected(orderId)) return;
    if (_isCodUpiQrCacheFresh(orderId, collectAmount: collectAmount)) return;
    if (_codUpiQrInFlight.containsKey(orderId)) return;
    unawaited(_warmCodUpiQr(orderId, collectAmount: collectAmount));
  }

  void _maybePrefetchCodUpiForOrder(OrderModel? order) {
    if (order?.id == null || order!.id! <= 0) return;
    if (order.paymentMethod != 'cash_on_delivery') return;
    if (order.paymentStatus == 'paid' || isCodPaymentCollected(order.id)) {
      return;
    }
    final status = order.orderStatus ?? '';
    if (status == 'processing' ||
        status == 'reached_restaurant' ||
        OrderStatusHelper.canStartOutForDelivery(status) ||
        OrderStatusHelper.canDeliver(status)) {
      prefetchCodUpiQr(order.id!);
    }
  }

  Future<void> _warmCodUpiQr(int orderId, {double? collectAmount}) async {
    final map = await _resolveCodUpiQr(
      orderId,
      collectAmount: collectAmount,
    );
    final url = map?['image_url']?.toString() ??
        map?['qr_image_url']?.toString();
    if (url != null && url.isNotEmpty) {
      unawaited(_warmCodUpiQrImage(url));
    }
  }

  /// Cache hit → in-flight join → parallel create + status poll.
  Future<Map<String, dynamic>?> ensureCodUpiQrReady(
    int orderId, {
    double? collectAmount,
  }) async {
    if (orderId <= 0) return null;
    if (isCodPaymentCollected(orderId)) return {'paid': true};

    if (_isCodUpiQrCacheFresh(orderId, collectAmount: collectAmount)) {
      return Map<String, dynamic>.from(_codUpiQrCache[orderId]!);
    }

    final inFlight = _codUpiQrInFlight[orderId];
    if (inFlight != null) {
      final joined = await inFlight;
      if (joined != null &&
          (joined['paid'] == true || _codUpiQrMapHasImage(joined))) {
        return joined;
      }
    }

    return _resolveCodUpiQr(orderId, collectAmount: collectAmount);
  }

  /// Start Razorpay create immediately; poll status every ~280ms in parallel.
  Future<Map<String, dynamic>?> _resolveCodUpiQr(
    int orderId, {
    double? collectAmount,
  }) async {
    Map<String, dynamic>? createResult;
    var createDone = false;
    Object? createError;
    unawaited(
      createCodUpiQr(orderId, collectAmount: collectAmount).then((value) {
        createResult = value;
        createDone = true;
      }).catchError((Object e) {
        createError = e;
        createDone = true;
      }),
    );

    final deadline = DateTime.now().add(const Duration(seconds: 16));
    while (DateTime.now().isBefore(deadline)) {
      final status = await _recoverCodUpiQrFromStatus(orderId);
      if (status != null) {
        final ready = _finalizeCodUpiQrMap(
          orderId,
          status,
          collectAmount: collectAmount,
        );
        if (ready != null) return ready;
      }

      if (createDone) {
        if (createResult != null) {
          final ready = _finalizeCodUpiQrMap(
            orderId,
            createResult!,
            collectAmount: collectAmount,
          );
          if (ready != null) return ready;
          if (createResult!['status'] == false) return createResult;
        }
        final lastStatus = await _recoverCodUpiQrFromStatus(orderId);
        if (lastStatus != null) {
          final ready = _finalizeCodUpiQrMap(
            orderId,
            lastStatus,
            collectAmount: collectAmount,
          );
          if (ready != null) return ready;
        }
        break;
      }

      await Future<void>.delayed(const Duration(milliseconds: 280));
    }

    if (createResult != null) return createResult;
    if (createError != null) return null;
    return null;
  }

  Map<String, dynamic>? _finalizeCodUpiQrMap(
    int orderId,
    Map<String, dynamic> map, {
    double? collectAmount,
  }) {
    if (map['paid'] == true) {
      _applyPaidLocally(orderId);
      return map;
    }
    if (_codUpiQrMapHasImage(map)) {
      _storeCodUpiQrCache(orderId, map, collectAmount: collectAmount);
      return map;
    }
    if (map['status'] == false) return map;
    return null;
  }

  bool _codUpiQrMapHasImage(Map<String, dynamic> map) {
    if (map['status'] == false) return false;
    final imageUrl =
        map['image_url']?.toString() ?? map['qr_image_url']?.toString();
    return imageUrl != null && imageUrl.isNotEmpty;
  }

  void _storeCodUpiQrCache(
    int orderId,
    Map<String, dynamic> map, {
    double? collectAmount,
  }) {
    if (!_codUpiQrMapHasImage(map)) return;
    _codUpiQrCache[orderId] = Map<String, dynamic>.from(map);
    _codUpiQrCacheAt[orderId] = DateTime.now();
    _codUpiQrCacheAmount[orderId] =
        (map['amount'] as num?)?.toDouble() ?? collectAmount;
  }

  /// Sync peek for Accept Payment sheet first frame (no await).
  Map<String, dynamic>? peekCodUpiQrCache(
    int orderId, {
    double? collectAmount,
  }) {
    if (!_isCodUpiQrCacheFresh(orderId, collectAmount: collectAmount)) {
      return null;
    }
    return Map<String, dynamic>.from(_codUpiQrCache[orderId]!);
  }

  Future<void> _warmCodUpiQrImage(String url) async {
    try {
      final provider = CachedNetworkImageProvider(url);
      final stream = provider.resolve(const ImageConfiguration());
      final done = Completer<void>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo _, bool __) {
          if (!done.isCompleted) done.complete();
          stream.removeListener(listener);
        },
        onError: (Object _, StackTrace? __) {
          if (!done.isCompleted) done.complete();
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await done.future.timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  bool _isCodUpiQrCacheFresh(int orderId, {double? collectAmount}) {
    final cachedAt = _codUpiQrCacheAt[orderId];
    if (cachedAt == null) return false;
    if (DateTime.now().difference(cachedAt) > _codUpiQrCacheTtl) return false;
    if (collectAmount != null) {
      final cachedAmount = _codUpiQrCacheAmount[orderId];
      if (cachedAmount != null &&
          (cachedAmount - collectAmount).abs() > 0.01) {
        return false;
      }
    }
    final data = _codUpiQrCache[orderId];
    if (data == null) return false;
    if (data['status'] == false || data['paid'] == true) return false;
    final imageUrl =
        data['image_url']?.toString() ?? data['qr_image_url']?.toString();
    return imageUrl != null && imageUrl.isNotEmpty;
  }

  void _applyPaidLocally(int orderId) {
    clearCodUpiQrCache(orderId);
    _codPaymentCollectedOrderIds.add(orderId);
    if (orderDetails != null) {
      for (final line in orderDetails!) {
        if (line.orderId == orderId || line.orderModel?.id == orderId) {
          line.orderModel?.paymentStatus = 'paid';
        }
      }
    }
    if (Get.isRegistered<OrderController>()) {
      final orderCtrl = Get.find<OrderController>();
      for (final order in [
        ...orderCtrl.currentOrders,
        ...orderCtrl.scheduledCurrentOrders,
      ]) {
        if (order.id == orderId) {
          order.paymentStatus = 'paid';
        }
      }
      orderCtrl.update();
    }
    update();
  }

  /// Prefer [createCodUpiQr] + [pollCodUpiQrStatus] for scan payments.
  Future<bool> markCodPaymentCollected(int orderId) async {
    return pollCodUpiQrStatus(orderId);
  }

  Future<Map<String, dynamic>?> createCodUpiQr(
    int orderId, {
    double? collectAmount,
    bool forceRefresh = false,
  }) async {
    if (orderId <= 0) return null;
    if (isCodPaymentCollected(orderId)) {
      return {'paid': true};
    }

    if (!forceRefresh && _isCodUpiQrCacheFresh(orderId, collectAmount: collectAmount)) {
      return Map<String, dynamic>.from(_codUpiQrCache[orderId]!);
    }

    final inFlight = _codUpiQrInFlight[orderId];
    if (!forceRefresh && inFlight != null) {
      return inFlight;
    }

    final future = _createCodUpiQrFromApi(orderId);
    _codUpiQrInFlight[orderId] = future;
    try {
      final result = await future;
      if (result != null &&
          result['status'] != false &&
          result['paid'] != true) {
        if (_codUpiQrMapHasImage(result)) {
          _storeCodUpiQrCache(orderId, result, collectAmount: collectAmount);
        }
      } else if (result != null && result['paid'] == true) {
        clearCodUpiQrCache(orderId);
        _applyPaidLocally(orderId);
      }
      return result;
    } finally {
      if (_codUpiQrInFlight[orderId] == future) {
        _codUpiQrInFlight.remove(orderId);
      }
    }
  }

  Future<Map<String, dynamic>?> _createCodUpiQrFromApi(int orderId) async {
    final Response response =
        await orderDetailsServiceInterface.createCodUpiQr(orderId: orderId);
    if (response.body is Map) {
      final map = Map<String, dynamic>.from(response.body as Map);
      if (map['paid'] == true) return map;
      final imageUrl = map['image_url']?.toString() ??
          map['qr_image_url']?.toString();
      if (imageUrl != null &&
          imageUrl.isNotEmpty &&
          map['status'] != false) {
        return map;
      }
    }
    for (var i = 0; i < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final recovered = await _recoverCodUpiQrFromStatus(orderId);
      if (recovered != null) return recovered;
    }

    if (response.statusCode != 200) {
      final msg = response.statusText?.toString();
      return {
        'status': false,
        'message': (msg != null && msg.isNotEmpty)
            ? msg
            : 'Unable to create UPI QR',
      };
    }
    return null;
  }

  /// If create timed out, status may already expose the active Razorpay QR.
  Future<Map<String, dynamic>?> _recoverCodUpiQrFromStatus(int orderId) async {
    try {
      final Response response =
          await orderDetailsServiceInterface.codUpiQrStatus(
        orderId: orderId,
        sync: false,
      );
      if (response.body is! Map) return null;
      final map = Map<String, dynamic>.from(response.body as Map);
      if (map['paid'] == true) return map;
      final imageUrl = map['image_url']?.toString() ??
          map['qr_image_url']?.toString();
      if (imageUrl != null &&
          imageUrl.isNotEmpty &&
          map['status'] != false) {
        return map;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> pollCodUpiQrStatus(
    int orderId, {
    bool showSnack = true,
    bool coalesce = true,
    bool sync = false,
  }) async {
    if (orderId <= 0) return false;
    if (isCodPaymentCollected(orderId)) return true;
    if (!sync && _refreshPaidFromLocalOrderModel(orderId)) return true;

    if (coalesce) {
      final inFlight = _codUpiPollInFlight[orderId];
      if (inFlight != null) return inFlight;
    }

    final future = _fetchCodUpiQrStatus(
      orderId,
      showSnack: showSnack,
      sync: sync,
    );
    _codUpiPollInFlight[orderId] = future;
    try {
      return await future;
    } finally {
      if (_codUpiPollInFlight[orderId] == future) {
        _codUpiPollInFlight.remove(orderId);
      }
    }
  }

  Future<bool> pollCodUpiQrStatusBurst(int orderId) async {
    return forceVerifyCodPayment(orderId);
  }

  bool _refreshPaidFromLocalOrderModel(int orderId) {
    if (isCodPaymentCollected(orderId)) return true;
    if (orderDetails != null) {
      for (final line in orderDetails!) {
        if ((line.orderId == orderId || line.orderModel?.id == orderId) &&
            line.orderModel?.paymentStatus == 'paid') {
          _applyPaidLocally(orderId);
          return true;
        }
      }
    }
    if (Get.isRegistered<OrderController>()) {
      for (final order in Get.find<OrderController>().currentOrders) {
        if (order.id == orderId && order.paymentStatus == 'paid') {
          _applyPaidLocally(orderId);
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> forceVerifyCodPayment(int orderId) async {
    if (orderId <= 0) return false;
    if (isCodPaymentCollected(orderId)) return true;
    if (_refreshPaidFromLocalOrderModel(orderId)) return true;

    _codUpiPollInFlight.remove(orderId);

    final cached = peekCodUpiQrCache(orderId);
    if (cached != null && cached['paid'] == true) {
      _applyPaidLocally(orderId);
      return true;
    }

    var syncDone = false;
    var syncPaid = false;
    unawaited(
      pollCodUpiQrStatus(
        orderId,
        showSnack: false,
        coalesce: false,
        sync: true,
      ).then((paid) {
        syncPaid = paid;
        syncDone = true;
      }).catchError((_) {
        syncDone = true;
      }),
    );

    for (var attempt = 0; attempt < 10; attempt++) {
      if (isCodPaymentCollected(orderId)) return true;
      if (_refreshPaidFromLocalOrderModel(orderId)) return true;
      if (syncDone && syncPaid) return true;

      if (await pollCodUpiQrStatus(
        orderId,
        showSnack: false,
        coalesce: false,
        sync: false,
      )) {
        return true;
      }

      if (syncDone) return syncPaid;

      if (attempt < 9) {
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
    }

    return syncPaid || isCodPaymentCollected(orderId);
  }

  bool _codUpiStatusLooksPaid(Map<String, dynamic> map) {
    if (map['paid'] == true) return true;
    final count = map['payments_count_received'];
    if (count is num && count > 0) return true;
    final paymentStatus =
        '${map['payment_status'] ?? map['paymentStatus'] ?? ''}'.toLowerCase();
    if (paymentStatus == 'paid' || paymentStatus == 'captured') return true;
    final qrStatus = '${map['qr_status'] ?? ''}'.toLowerCase();
    if (qrStatus == 'closed' || qrStatus == 'paid' || qrStatus == 'captured') {
      return true;
    }
    final nested = map['data'];
    if (nested is Map) {
      return _codUpiStatusLooksPaid(Map<String, dynamic>.from(nested));
    }
    return false;
  }

  Future<bool> _fetchCodUpiQrStatus(
    int orderId, {
    required bool showSnack,
    bool sync = false,
  }) async {
    final Response response = await orderDetailsServiceInterface.codUpiQrStatus(
      orderId: orderId,
      sync: sync,
    );
    // 200 or 404 body may still carry paid/pending payload.
    if (response.body is Map) {
      final map = Map<String, dynamic>.from(response.body as Map);
      if (_codUpiStatusLooksPaid(map)) {
        _applyPaidLocally(orderId);
        if (showSnack) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showQuikseeSnackBarWidget(
              'payment_received_successfully'.tr,
              isError: false,
            );
          });
        }
        return true;
      }
      // Keep cache warm from status image_url when create timed out earlier.
      final imageUrl = map['image_url']?.toString() ??
          map['qr_image_url']?.toString();
      if (imageUrl != null &&
          imageUrl.isNotEmpty &&
          map['status'] != false &&
          map['paid'] != true &&
          !_isCodUpiQrCacheFresh(orderId)) {
        _storeCodUpiQrCache(orderId, map);
      }
      return false;
    }
    return false;
  }

  /// Instant UI after driver confirms UPI/cash; server sync runs in background.
  Future<bool> confirmCodPaymentPaidOptimistic(int orderId) async {
    if (orderId <= 0) return false;
    _applyPaidLocally(orderId);
    unawaited(() async {
      final response =
          await updatePaymentStatus(orderId: orderId, status: 'paid');
      if (response?.statusCode != 200) {
        _codPaymentCollectedOrderIds.remove(orderId);
        if (orderDetails != null) {
          for (final line in orderDetails!) {
            if (line.orderId == orderId || line.orderModel?.id == orderId) {
              line.orderModel?.paymentStatus = 'unpaid';
            }
          }
        }
        if (Get.isRegistered<OrderController>()) {
          for (final order
              in Get.find<OrderController>().currentOrders) {
            if (order.id == orderId) {
              order.paymentStatus = 'unpaid';
            }
          }
          Get.find<OrderController>().update();
        }
        update();
        showQuikseeSnackBarWidget(
          'Payment could not be confirmed on server. Please try again.',
          isError: true,
        );
      }
    }());
    return true;
  }

  Future<bool> markCodCashCollected(int orderId) async {
    if (orderId <= 0) return false;
    _isLoading = true;
    update();
    try {
      // Mark all unpaid COD siblings in the combined checkout.
      final pool = Get.isRegistered<OrderController>()
          ? Get.find<OrderController>().currentOrders
          : <OrderModel>[];
      OrderModel? anchor;
      for (final order in OrderGroupHelper.expandOrderPool(pool)) {
        if (order.id == orderId) {
          anchor = order;
          break;
        }
      }
      anchor ??= OrderModel(id: orderId);
      final ids = OrderGroupHelper.unpaidCodOrderIds(anchor, pool);
      final targetIds = ids.isNotEmpty ? ids : [orderId];

      var anySuccess = false;
      for (final id in targetIds) {
        final Response response = await orderDetailsServiceInterface
            .markCodCashCollected(orderId: id);
        if (response.statusCode == 200) {
          _applyPaidLocally(id);
          anySuccess = true;
        }
      }

      if (anySuccess) {
        showQuikseeSnackBarWidget(
          'payment_received_successfully'.tr,
          isError: false,
        );
        return true;
      }
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  void setEarningFilterIndex(int index) {
    _orderTypeFilterIndex = index;
    if(_orderTypeFilterIndex == 0){
      Get.find<WalletController>().getOrderWiseDeliveryCharge('', '', 1, '');
    }else if(_orderTypeFilterIndex == 1){
      Get.find<WalletController>().getOrderWiseDeliveryCharge('', '', 1, 'TodayEarn');
    }
    else if(_orderTypeFilterIndex == 2){
      Get.find<WalletController>().getOrderWiseDeliveryCharge('', '', 1, 'ThisWeekEarn');
    }
    else if(_orderTypeFilterIndex == 3){
      Get.find<WalletController>().getOrderWiseDeliveryCharge('', '', 1, 'ThisMonthEarn');
    }
    update();
  }

  DateTime? _startDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-d');
  DateTime? get startDate => _startDate;
  DateFormat get dateFormat => _dateFormat;

  void selectDate(BuildContext context){
    showDatePicker(

      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    ).then((date) {
      _startDate = date;
      update();
    });
  }

  List<XFile>? identityImage;
  XFile? cameraImage;
  List<XFile> identityImages = [];
  List<MultipartBody> multipartList = [];

  void pickImage( {bool camera = false}) async {
    multipartList = [];
    identityImage = null;
    if(camera) {
      cameraImage = await ImageValidationHelper.validateAndPickImage(
        source: ImageSource.camera,
        context: Get.context!,
      );
      if(cameraImage != null) {
        identityImages.add(cameraImage!);
      }
    }else{
      identityImage = (await ImageValidationHelper.validateAndPickMultipleImages(
        imageQuality: AppConstants.imageQuality, context: Get.context!,
      ));
    }

      if(identityImage != null) {
        for(XFile image in identityImage!) {
          double value =  await ImageValidationHelper.getImageSizeFromXFile(image);

          ConfigModel? configModel = Get.find<SplashController>().configModel;

          if(value > (configModel?.systemImageFileUploadMaxSize ?? AppConstants.fileImageMaxLimit)) {
            showQuikseeSnackBarWidget('${'maximum_image_size'.tr} ${(configModel?.systemImageFileUploadMaxSize ?? AppConstants.fileImageMaxLimit)}MB');
            return;
          } else {
            identityImages.add(image);
          }
        }
      }
      for(int i=0; i<identityImages.length; i++){
        multipartList.add(MultipartBody('image[$i]', identityImages[i]));
      }
    update();
  }

  void removeImage(int index){
    identityImages.removeAt(index);
    update();
  }

  bool endOfPage = false;
  bool endOfPageScrolled = false;
  void gotoEndOfPage() {
    endOfPage = true;
    update();
  }

  void setGotoEndOfPage() {
    endOfPageScrolled = true;
    update();
  }

  void gotoEndOfPageInitialize(){
    endOfPage = false;
    endOfPageScrolled = false;
  }

  bool otpVerified = false;
  bool _otpVerifying = false;
  bool get otpVerifying => _otpVerifying;
  void toggleProceedToNext(){
    identityImages.clear();
    otpVerified = true;
    update();
  }

  String? otp;
  void setOtp(String otp) {
    otp = otp;
    if(otp != '') {
      update();
    }
  }

  bool uploading = false;
  Future<Response> uploadOrderVerificationImage( String oderId) async {
    uploading = true;
    update();
    Response? response = await orderDetailsServiceInterface.uploadOrderVerificationImage(oderId, multipartList);
    if(response!.statusCode == 200){
      uploading = false;
      showQuikseeSnackBarWidget('image_uploaded_successfully'.tr, isError: false);
    }else{
      uploading = false;
      ApiChecker.checkApi(response);
    }

    update();
    return response;
  }

  Future<Response?> otpVerificationForOrderVerification({
    int? orderId,
    String? otp,
    bool showSuccessSnack = false,
    bool notifyUi = true,
  }) async {
    if (notifyUi) {
      _otpVerifying = true;
      update();
    }
    try {
      final Response apiResponse =
          await orderDetailsServiceInterface.verifyOrderDeliveryOtp(
        orderId: orderId,
        verificationCode: otp,
      );
      if (apiResponse.statusCode == 200) {
        if (showSuccessSnack) {
          showQuikseeSnackBarWidget(
            'otp_verified_successfully'.tr,
            isError: false,
          );
        }
      } else {
        ApiChecker.checkApi(apiResponse);
      }
      return apiResponse;
    } finally {
      if (notifyUi) {
        _otpVerifying = false;
        update();
      }
    }
  }

  Future resendOtpForOrderVerification({int? orderId}) async {
     await orderDetailsServiceInterface.resendOtpForOrderVerification(orderId: orderId);
    update();
  }

  TextEditingController searchOrderController = TextEditingController();

  void emptyIdentityImage() {
    identityImages = [];
    otpVerified = false;
  }

}
