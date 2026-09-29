import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/assignment/domain/models/assignment_settings_model.dart';
import 'package:quiksee/features/order/domain/models/date_type.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/domain/services/order_service_interface.dart';
import 'package:quiksee/features/order/helpers/combined_order_helper.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order/widgets/new_order_action_sheet.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/helper/gps_location_helper.dart';
import 'package:quiksee/helper/location_permission_helper.dart';
import 'package:quiksee/helper/new_order_alert_helper.dart';
import 'package:quiksee/helper/vendor_ready_popup_helper.dart';
import 'package:quiksee/features/order/helpers/scheduled_delivery_response_helper.dart';
import 'package:quiksee/helper/scheduled_slot_reminder_helper.dart';
import 'package:quiksee/utill/app_constants.dart';

class OrderController extends GetxController implements GetxService {
  final OrderServiceInterface orderServiceInterface;
  OrderController({required this.orderServiceInterface});

  SharedPreferences? _prefs;
  final Set<int> _driverAcceptedOrderIds = {};
  Set<int> get driverAcceptedOrderIds => Set.unmodifiable(_driverAcceptedOrderIds);


  List<OrderModel> _currentOrders = [];
  List<OrderModel> get currentOrders => _currentOrders;

  List<OrderModel> _scheduledCurrentOrders = [];
  List<OrderModel> get scheduledCurrentOrders => _scheduledCurrentOrders;

  int _homeDeliveryTabIndex = 0;
  int get homeDeliveryTabIndex => _homeDeliveryTabIndex;

  bool _isScheduledHistoryMode = false;
  bool get isScheduledHistoryMode => _isScheduledHistoryMode;

  bool get scheduledDeliveryEnabled =>
      Get.isRegistered<AssignmentController>() &&
      Get.find<AssignmentController>().scheduledDeliveryEnabled;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isHistoryLoading = false;
  bool get isHistoryLoading => _isHistoryLoading;
  int _orderTypeIndex = 0;
  int get orderTypeIndex => _orderTypeIndex;
  List<OrderModel>? _allOrderHistory;
  List<OrderModel>? _outForDeliveryOrderHistory;
  List<OrderModel>? _returnOrderHistory;
  List<OrderModel>? _canceledOrderHistory;
  List<OrderModel>? pauseOrderHistory;
  List<OrderModel>? deliveredOrderHistory;
  List<OrderModel>? get allOrderHistory => _allOrderHistory;

  /// Active assigned orders (pickup stage), not lifetime `total_delivery`.
  int get activeAssignedCount {
    final history = _allOrderHistory ?? const <OrderModel>[];
    final merged = _mergeOrdersById(history, _currentOrders);
    return _filterHistoryByTab(merged, '', 0).length;
  }

  int get pausedHistoryCountValue => pauseOrderHistory?.length ?? 0;

  int? get deliveredHistoryCountValue => deliveredOrderHistory?.length;

  /// List for the currently selected history status tab.
  List<OrderModel>? get currentHistoryOrders {
    switch (_orderTypeIndex) {
      case 1:
        return _outForDeliveryOrderHistory;
      case 2:
        return pauseOrderHistory;
      case 3:
        return deliveredOrderHistory;
      case 4:
        return _returnOrderHistory;
      case 5:
        return _canceledOrderHistory;
      default:
        return _allOrderHistory;
    }
  }

  String? selectedOrderLat = '23.83721';
  String? selectedOrderLng = '90.363715';

  void setSelectedOrderLatLng(LatLng latLng) {
    selectedOrderLat = latLng.latitude.toString();
    selectedOrderLng = latLng.longitude.toString();
  }


  void selectedOrderLatLng(String? lat, String? lng){
    selectedOrderLat = lat;
    selectedOrderLng = lng;
    update();
  }

  String dateType = DateType.overall.key;

  List<OrderModel>? _orderList;
  List<OrderModel>? get orderList => _orderList != null ? _orderList!.reversed.toList() : _orderList;


  bool _isSearchActive = false;
  bool get isSearchActive => _isSearchActive;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;
  String? _actionType;
  String? get actionType => _actionType;

  Timer? _newOrderPollTimer;
  Timer? _scheduledReminderTimer;
  Timer? _newOrderResponseTimer;
  Timer? _vendorReadyPollTimer;
  int? _newOrderSecondsRemaining;
  int? get newOrderSecondsRemaining => _newOrderSecondsRemaining;
  final Set<int> _promptedOrderIds = {};
  final Set<int> _timedOutOrderIds = {};
  bool _newOrderSheetOpen = false;
  bool get isNewOrderSheetOpen => _newOrderSheetOpen;
  bool _isFetchingOrders = false;
  bool _pendingOrdersRefresh = false;
  bool _pendingOrdersRefreshPromptAccept = false;
  bool _isFetchingScheduledOrders = false;
  DateTime? _lastOrdersRefreshAt;
  DateTime? _lastScheduledOrdersRefreshAt;
  static const Duration _ordersRefreshDebounce = Duration(seconds: 4);
  static const Duration _scheduledOrdersCacheTtl = Duration(seconds: 30);
  String? _historyFetchKey;
  bool _historyInitialized = false;
  bool _acceptedOrdersLoaded = false;
  final Set<int> _handlingTimeoutOrderIds = {};
  bool _baselineOrdersCaptured = false;
  /// Orders merged from accept-offer response until current-orders API catches up.
  final Map<int, OrderModel> _locallyMergedOrders = {};
  /// Orders merged from accept-offer until scheduled current-orders API catches up.
  final Map<int, OrderModel> _locallyMergedScheduledOrders = {};

  bool _isAutoAssignMode() {
    if (!Get.isRegistered<ProfileController>()) return false;
    final settings =
        Get.find<ProfileController>().profileModel?.assignmentSettings;
    return settings?.isManualMode != true;
  }

  AssignmentSettingsModel? _assignmentSettings() {
    if (!Get.isRegistered<ProfileController>()) return null;
    return Get.find<ProfileController>().profileModel?.assignmentSettings;
  }

  /// Offer flow + manual: driver must tap Accept. Instant auto-assign: no sheet.
  bool _requiresDriverAcceptance() {
    return _assignmentSettings()?.requiresDriverAcceptance == true;
  }

  /// Offer flow: hide unaccepted offers. Already-advanced orders always show
  /// (e.g. after app restart, or status already past Accept).
  List<OrderModel> _filterVisibleCurrentOrders(List<OrderModel> orders) {
    if (!_requiresDriverAcceptance()) return orders;
    var acceptedDirty = false;
    final visible = orders.where((order) {
      final id = order.id;
      if (id == null) return false;
      if (_timedOutOrderIds.contains(id)) return false;
      if (_driverAcceptedOrderIds.contains(id)) return true;
      // Server already past Accept (confirmed / OFD / arrived / …).
      if (OrderStatusHelper.canSkipAcceptApi(order.orderStatus)) {
        _driverAcceptedOrderIds.add(id);
        acceptedDirty = true;
        return true;
      }
      return false;
    }).toList();
    if (acceptedDirty) {
      unawaited(_saveAcceptedOrders());
    }
    return visible;
  }

  List<OrderModel> _filterVisibleScheduledCurrentOrders(List<OrderModel> orders) {
    return orders.where((order) {
      final id = order.id;
      if (id == null) return false;
      return !_timedOutOrderIds.contains(id);
    }).toList();
  }

  void _upsertScheduledOrder(OrderModel order) {
    if (order.id == null) return;
    final idx = _scheduledCurrentOrders.indexWhere((o) => o.id == order.id);
    if (idx >= 0) {
      _scheduledCurrentOrders[idx] = order;
    } else {
      _scheduledCurrentOrders.insert(0, order);
    }
  }

  /// Scheduled orders must never appear under Normal tab.
  void _segregateDeliveryLists() {
    final leakedScheduled =
        _currentOrders.where((o) => o.isScheduledDeliveryOrder).toList();
    if (leakedScheduled.isNotEmpty) {
      _currentOrders.removeWhere((o) => o.isScheduledDeliveryOrder);
      for (final order in leakedScheduled) {
        _upsertScheduledOrder(order);
      }
    }

    final scheduledIds = _scheduledCurrentOrders
        .map((o) => o.id)
        .whereType<int>()
        .toSet();
    _currentOrders.removeWhere(
      (o) => o.id != null && scheduledIds.contains(o.id),
    );

    final seen = <int>{};
    _scheduledCurrentOrders = _scheduledCurrentOrders.where((o) {
      if (o.id == null) return true;
      if (seen.contains(o.id)) return false;
      seen.add(o.id!);
      return true;
    }).toList();
  }

  bool _shouldPromptAcceptOnPoll() {
    if (_isAutoAssignMode() && !_requiresDriverAcceptance()) return false;
    return _baselineOrdersCaptured;
  }

  void _captureOrderBaselineIfNeeded() {
    if (_baselineOrdersCaptured) return;
    _baselineOrdersCaptured = true;
    for (final order in _currentOrders) {
      if (order.id != null) {
        _promptedOrderIds.add(order.id!);
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    _ensureAcceptedOrdersLoaded();
  }

  Future<void> _ensureAcceptedOrdersLoaded() async {
    if (_acceptedOrdersLoaded) return;
    await _loadAcceptedOrders();
    _acceptedOrdersLoaded = true;
  }

  @override
  void onClose() {
    stopNewOrderPolling();
    _stopScheduledSlotReminders();
    _stopNewOrderResponseTimer();
    _vendorReadyPollTimer?.cancel();
    _vendorReadyPollTimer = null;
    super.onClose();
  }

  int _resolveAcceptTimeoutSeconds() {
    if (Get.isRegistered<ProfileController>()) {
      final seconds = Get.find<ProfileController>()
          .profileModel
          ?.assignmentSettings
          ?.autoAssignTimeoutSeconds;
      if (seconds != null && seconds >= 30) return seconds;
    }
    return 30;
  }

  void _startNewOrderResponseTimer(int orderId) {
    _stopNewOrderResponseTimer();
    _newOrderSecondsRemaining = _resolveAcceptTimeoutSeconds();
    update();

    _newOrderResponseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_newOrderSecondsRemaining == null || _newOrderSecondsRemaining! <= 0) {
        timer.cancel();
        unawaited(_onNewOrderResponseTimeout(orderId));
        return;
      }
      _newOrderSecondsRemaining = _newOrderSecondsRemaining! - 1;
      update();
    });
  }

  void _stopNewOrderResponseTimer() {
    _newOrderResponseTimer?.cancel();
    _newOrderResponseTimer = null;
    _newOrderSecondsRemaining = null;
  }

  Future<void> _onNewOrderResponseTimeout(int orderId) async {
    if (_handlingTimeoutOrderIds.contains(orderId)) return;
    if (_driverAcceptedOrderIds.contains(orderId)) {
      _stopNewOrderResponseTimer();
      NewOrderAlertHelper.stop();
      closeNewOrderActionSheet();
      return;
    }

    _handlingTimeoutOrderIds.add(orderId);
    _timedOutOrderIds.add(orderId);
    _promptedOrderIds.add(orderId);
    _stopNewOrderResponseTimer();
    NewOrderAlertHelper.stop();
    closeNewOrderActionSheet();

    try {
      final response = await orderServiceInterface.rejectAssignedOrder(
        orderId,
        reason: 'acceptance_timeout',
      );
      if (response.statusCode == 200 && response.body != null) {
        await _markOrderReleased(orderId);
        showQuikseeSnackBarWidget(
          response.body['message']?.toString() ?? 'order_released_timeout'.tr,
          isError: false,
        );
      }
    } finally {
      _handlingTimeoutOrderIds.remove(orderId);
    }

    await refreshCurrentOrdersOnly(promptAccept: false, force: true);
    _pruneTimedOutOrders();
  }

  void _pruneTimedOutOrders() {
    final currentIds = _currentOrders.map((o) => o.id).whereType<int>().toSet();
    _timedOutOrderIds.removeWhere((id) => !currentIds.contains(id));
  }

  bool _isOrderAlertSuppressed(int orderId) =>
      _timedOutOrderIds.contains(orderId);

  bool needsAcceptForOrder(OrderModel? order) {
    if (!_requiresDriverAcceptance()) return false;
    return OrderStatusHelper.needsDriverAcceptance(
      order,
      _driverAcceptedOrderIds,
    );
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadAcceptedOrders() async {
    await _ensurePrefs();
    final raw = _prefs?.getString(AppConstants.driverAcceptedOrders);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _driverAcceptedOrderIds
        ..clear()
        ..addAll(list.map((e) => int.parse('$e')));
    } catch (_) {}
  }

  Future<void> _saveAcceptedOrders() async {
    await _ensurePrefs();
    await _prefs?.setString(
      AppConstants.driverAcceptedOrders,
      jsonEncode(_driverAcceptedOrderIds.toList()),
    );
  }

  Future<void> markOrderAccepted(int orderId) async {
    NewOrderAlertHelper.muteFor(const Duration(seconds: 8));
    NewOrderAlertHelper.stop();
    closeNewOrderActionSheet();
    await _persistOrderAccepted(orderId);
  }

  void markOrderTransferDone(int orderId) {
    if (orderId <= 0) return;
    for (final order in _currentOrders) {
      if (order.id == orderId) {
        order.orderTransferAlreadyDone = 1;
        order.orderTransferLocked = 1;
      }
    }
    final merged = _locallyMergedOrders[orderId];
    if (merged != null) {
      merged.orderTransferAlreadyDone = 1;
      merged.orderTransferLocked = 1;
    }
    update();
  }

  Future<void> mergeAcceptedOrder({
    required int orderId,
    Map<String, dynamic>? orderJson,
  }) async {
    await markOrderAccepted(orderId);
    _insertOrderFromAcceptResponse(orderId, orderJson);
  }

  Future<bool> finalizeOfferAccept({
    required int orderId,
    Map<String, dynamic>? orderJson,
    bool forceScheduled = false,
  }) async {
    NewOrderAlertHelper.muteFor(const Duration(seconds: 8));
    NewOrderAlertHelper.stop();
    closeNewOrderActionSheet();
    await markOrderAccepted(orderId);
    _insertOrderFromAcceptResponse(
      orderId,
      orderJson,
      forceScheduled: forceScheduled,
    );
    final confirmed = await acceptOrder(orderId, forceBackendConfirm: true);
    if (confirmed) {
      _setLocalOrderStatus(orderId, 'confirmed');
      final merged = _locallyMergedOrders[orderId];
      if (merged != null) {
        merged.orderStatus = 'confirmed';
      }
      final scheduledMerged = _locallyMergedScheduledOrders[orderId];
      if (scheduledMerged != null) {
        scheduledMerged.orderStatus = 'confirmed';
      }
      _setHistoryOrderStatus(orderId, 'confirmed');
    }
    // Refresh Order History → Assigned so the new order sticks from API too.
    unawaited(refreshAssignedOrderHistory());
    return confirmed;
  }

  void _insertOrderFromAcceptResponse(
    int orderId,
    Map<String, dynamic>? orderJson, {
    bool forceScheduled = false,
  }) {
    try {
      final OrderModel accepted;
      if (orderJson != null) {
        final normalized = forceScheduled
            ? ScheduledDeliveryResponseHelper.normalizeOrderJson(orderJson)
            : Map<String, dynamic>.from(orderJson);
        accepted = OrderModel.fromJson(normalized);
      } else {
        accepted = OrderModel(id: orderId, orderStatus: 'confirmed');
      }
      // Transfer / store-wait orders must never fall back to "go to store".
      final transferReceived = (accepted.orderTransferReceived ?? 0) == 1;
      final waitStarted = (accepted.storeWaitStartedAt ?? '').trim().isNotEmpty &&
          accepted.storeWaitStartedAt != 'null';
      if ((accepted.orderStatus == null ||
              accepted.orderStatus!.isEmpty ||
              accepted.orderStatus == 'confirmed') &&
          (transferReceived || waitStarted)) {
        accepted.orderStatus = 'reached_restaurant';
      }
      accepted.orderStatus ??= 'confirmed';
      final isScheduled = forceScheduled || accepted.isScheduledDeliveryOrder;
      if (isScheduled) {
        _locallyMergedScheduledOrders[orderId] = accepted;
        _locallyMergedOrders.remove(orderId);
        _currentOrders.removeWhere((o) => o.id == orderId);
        _upsertScheduledOrder(accepted);
        _syncScheduledSlotReminders();
      } else {
        _locallyMergedScheduledOrders.remove(orderId);
        _locallyMergedOrders[orderId] = accepted;
        _scheduledCurrentOrders.removeWhere((o) => o.id == orderId);
        _currentOrders.removeWhere((o) => o.id == orderId);
        _currentOrders.insert(0, accepted);
      }
      // Order History → Assigned must update immediately (same GetBuilder).
      _insertIntoAssignedHistory(accepted, isScheduled: isScheduled);
      update();
    } catch (_) {}
  }

  void _insertIntoAssignedHistory(
    OrderModel accepted, {
    required bool isScheduled,
  }) {
    // Only update the history list that matches this order + current mode.
    final bool matchesCurrentMode =
        (_isScheduledHistoryMode && isScheduled) ||
        (!_isScheduledHistoryMode && !isScheduled);
    if (!matchesCurrentMode) return;

    _allOrderHistory ??= <OrderModel>[];
    _allOrderHistory!.removeWhere((o) => o.id == accepted.id);
    pauseOrderHistory?.removeWhere((o) => o.id == accepted.id);
    deliveredOrderHistory?.removeWhere((o) => o.id == accepted.id);
    _allOrderHistory!.insert(0, accepted);
    if (_orderTypeIndex != 0) {
      _orderTypeIndex = 0;
    }
  }

  void _setHistoryOrderStatus(int orderId, String status) {
    for (final list in [
      _allOrderHistory,
      pauseOrderHistory,
      deliveredOrderHistory,
    ]) {
      if (list == null) continue;
      for (final order in list) {
        if (order.id == orderId) {
          order.orderStatus = status;
        }
      }
    }
  }

  /// Force-refresh Order History Assigned list after accept.
  Future<void> refreshAssignedOrderHistory() async {
    await getAllOrderHistory(dateType, '', '', '', '', 0, force: true);
  }

  void _reconcileLocallyMergedIntoHistory(List<OrderModel> orders) {
    final fetchedIds = orders.map((o) => o.id).whereType<int>().toSet();
    final localSource = _isScheduledHistoryMode
        ? _locallyMergedScheduledOrders
        : _locallyMergedOrders;
    for (final entry in localSource.entries) {
      final id = entry.key;
      if (!_driverAcceptedOrderIds.contains(id)) continue;
      if (fetchedIds.contains(id)) continue;
      final status = (entry.value.orderStatus ?? '').toLowerCase();
      if (status == 'delivered' ||
          status == 'canceled' ||
          status == 'cancelled' ||
          status == 'returned') {
        continue;
      }
      orders.insert(0, entry.value);
      fetchedIds.add(id);
    }
  }

  void _reconcileLocallyMergedScheduledOrders(List<OrderModel> fetched) {
    final fetchedIds = fetched.map((o) => o.id).whereType<int>().toSet();
    for (final id in fetchedIds) {
      _locallyMergedScheduledOrders.remove(id);
    }
    for (final entry in _locallyMergedScheduledOrders.entries.toList()) {
      if (!_driverAcceptedOrderIds.contains(entry.key)) {
        _locallyMergedScheduledOrders.remove(entry.key);
        continue;
      }
      if (!fetchedIds.contains(entry.key)) {
        fetched.insert(0, entry.value);
        fetchedIds.add(entry.key);
      }
    }
  }

  void _reconcileLocallyMergedOrders(List<OrderModel> fetched) {
    final fetchedIds = fetched.map((o) => o.id).whereType<int>().toSet();
    for (final id in fetchedIds) {
      _locallyMergedOrders.remove(id);
    }
    for (final entry in _locallyMergedOrders.entries.toList()) {
      if (!_driverAcceptedOrderIds.contains(entry.key)) {
        _locallyMergedOrders.remove(entry.key);
        continue;
      }
      if (!fetchedIds.contains(entry.key)) {
        fetched.insert(0, entry.value);
        fetchedIds.add(entry.key);
      }
    }
  }

  Future<void> _persistOrderAccepted(int orderId) async {
    _driverAcceptedOrderIds.add(orderId);
    _promptedOrderIds.remove(orderId);
    await _saveAcceptedOrders();
  }

  Future<void> _markOrderReleased(int orderId) async {
    _driverAcceptedOrderIds.remove(orderId);
    _promptedOrderIds.remove(orderId);
    await _saveAcceptedOrders();
  }

  void _pruneAcceptedOrders() {
    final currentById = <int, OrderModel>{
      for (final o in _currentOrders)
        if (o.id != null) o.id!: o,
    };
    _driverAcceptedOrderIds.removeWhere((id) {
      final order = currentById[id];
      if (order != null &&
          OrderStatusHelper.isTerminalStatus(order.orderStatus)) {
        _locallyMergedOrders.remove(id);
        return true;
      }
      return false;
    });
    _promptedOrderIds.removeWhere((id) {
      final order = currentById[id];
      return order == null || !needsAcceptForOrder(order);
    });
    _saveAcceptedOrders();
  }

  OrderModel? _findOrderById(int orderId) {
    for (final order in _currentOrders) {
      if (order.id == orderId) return order;
    }
    for (final order in _scheduledCurrentOrders) {
      if (order.id == orderId) return order;
    }
    for (final list in [_allOrderHistory, pauseOrderHistory, deliveredOrderHistory]) {
      if (list == null) continue;
      for (final order in list) {
        if (order.id == orderId) return order;
      }
    }
    return null;
  }

  void _checkAndPromptAcceptOrders() {
    if (_isAutoAssignMode() && !_requiresDriverAcceptance()) return;
    if (!Get.isRegistered<ProfileController>()) return;
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;
    if (_newOrderSheetOpen || _isActionLoading) return;
    if (Get.isRegistered<AssignmentController>()) {
      final assign = Get.find<AssignmentController>();
      // Offer flow / unknown settings → AssignmentOfferSheet only.
      if (assign.settings == null ||
          assign.usesOfferFlow ||
          assign.isBusyWithOffer ||
          assign.isOfferAlertProtected) {
        return;
      }
    }

    final candidates = _currentOrders
        .where((o) => o.id != null && needsAcceptForOrder(o))
        .where((o) => !_promptedOrderIds.contains(o.id))
        .where((o) => !_timedOutOrderIds.contains(o.id))
        .toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    if (candidates.isEmpty) return;
    showNewOrderActionSheet(candidates.first.id!);
  }

  void closeNewOrderActionSheet({bool stopAlert = true}) {
    if (!_newOrderSheetOpen) return;
    _stopNewOrderResponseTimer();
    _newOrderSheetOpen = false;
    final bool keepAlertForOffer = Get.isRegistered<AssignmentController>() &&
        (Get.find<AssignmentController>().isOfferSheetOpen ||
            Get.find<AssignmentController>().isOfferAlertProtected ||
            Get.find<AssignmentController>().usesOfferFlow ||
            !stopAlert);
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    if (!keepAlertForOffer) {
      NewOrderAlertHelper.stop();
    }
  }

  Future<void> refreshCurrentOrdersOnly({
    bool promptAccept = false,
    bool showLoading = false,
    bool force = false,
  }) async {
    await _ensureAcceptedOrdersLoaded();
    if (_isFetchingOrders) {
      // In-flight list can be stale (e.g. started before transfer accept).
      // Queue a follow-up so UI does not wait on the next poll.
      if (force || showLoading || promptAccept) {
        _pendingOrdersRefresh = true;
        if (promptAccept) _pendingOrdersRefreshPromptAccept = true;
      }
      return;
    }
    if (!force && !showLoading) {
      final last = _lastOrdersRefreshAt;
      if (last != null &&
          DateTime.now().difference(last) < _ordersRefreshDebounce) {
        if (promptAccept && _shouldPromptAcceptOnPoll()) {
          _checkAndPromptAcceptOrders();
        }
        return;
      }
    }
    _isFetchingOrders = true;
    _lastOrdersRefreshAt = DateTime.now();
    if (showLoading) {
      _isLoading = true;
      update();
    }

    try {
      final previousOrders = List<OrderModel>.from(_currentOrders);
      _currentOrders = await orderServiceInterface.getCurrentOrders();
      _preserveAdvancedLocalStatuses(_currentOrders, previousOrders);
      _currentOrders = _filterVisibleCurrentOrders(_currentOrders);
      _reconcileLocallyMergedOrders(_currentOrders);
      _pruneAcceptedOrders();
      _pruneTimedOutOrders();
      _segregateDeliveryLists();
    } finally {
      if (showLoading) _isLoading = false;
      _isFetchingOrders = false;
    }
    update();

    if (Get.isRegistered<RiderController>()) {
      Get.find<RiderController>().resumeGpsForOrders(_currentOrders);
    }
    _captureOrderBaselineIfNeeded();
    if (promptAccept && _shouldPromptAcceptOnPoll()) {
      _checkAndPromptAcceptOrders();
    }
    _prefetchEarningsInBackground();
    unawaited(VendorReadyPopupHelper.maybeShowFromOrders(_currentOrders));
    _syncVendorReadyPolling();

    if (_pendingOrdersRefresh) {
      _pendingOrdersRefresh = false;
      final againPrompt = _pendingOrdersRefreshPromptAccept;
      _pendingOrdersRefreshPromptAccept = false;
      unawaited(refreshCurrentOrdersOnly(
        force: true,
        promptAccept: againPrompt,
      ));
    }
  }

  void _syncVendorReadyPolling() {
    final waiting = _currentOrders.any((order) {
      final status = (order.orderStatus ?? '').toLowerCase();
      final ready = order.vendorReadyAt?.trim() ?? '';
      final waitingStatus = status == 'reached_restaurant' ||
          status == 'confirmed' ||
          status == 'processing';
      return waitingStatus && (ready.isEmpty || ready == 'null');
    });
    if (waiting) {
      _vendorReadyPollTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(
          refreshCurrentOrdersOnly(force: true, promptAccept: false),
        );
      });
    } else {
      _vendorReadyPollTimer?.cancel();
      _vendorReadyPollTimer = null;
    }
  }

  void _prefetchEarningsInBackground() {
    if (!Get.isRegistered<DistancePaymentController>()) return;
    final orders = List<OrderModel>.from(_currentOrders);
    Future.microtask(() {
      Get.find<DistancePaymentController>().prefetchEarningsForOrders(orders);
    });
  }

  Future<void> getCurrentOrders({
    bool promptAccept = true,
    bool showLoading = false,
  }) async {
    await refreshCurrentOrdersOnly(
      promptAccept: promptAccept,
      showLoading: showLoading,
    );
    if (scheduledDeliveryEnabled) {
      await refreshScheduledCurrentOrdersOnly(showLoading: false);
    }
  }

  Future<void> refreshScheduledCurrentOrdersOnly({
    bool showLoading = false,
    bool force = false,
    bool promptAccept = false,
  }) async {
    if (!scheduledDeliveryEnabled || _isFetchingScheduledOrders) return;
    _isFetchingScheduledOrders = true;
    if (showLoading) {
      _isLoading = true;
      update();
    }

    try {
      final previousScheduled =
          List<OrderModel>.from(_scheduledCurrentOrders);
      _scheduledCurrentOrders =
          await orderServiceInterface.getScheduledCurrentOrders();
      _preserveAdvancedLocalStatuses(
        _scheduledCurrentOrders,
        previousScheduled,
      );
      _preservePaymentCollectFieldsOnRefresh(
        _scheduledCurrentOrders,
        previousScheduled,
      );
      _lastScheduledOrdersRefreshAt = DateTime.now();
      _scheduledCurrentOrders =
          _filterVisibleScheduledCurrentOrders(_scheduledCurrentOrders);
      _reconcileLocallyMergedScheduledOrders(_scheduledCurrentOrders);
      _segregateDeliveryLists();

      if (Get.isRegistered<RiderController>()) {
        Get.find<RiderController>().resumeGpsForOrders(_scheduledCurrentOrders);
      }
      _syncScheduledSlotReminders();
    } catch (_) {
      // Keep previous scheduled list on failure.
    } finally {
      if (showLoading) _isLoading = false;
      _isFetchingScheduledOrders = false;
      update();
    }
  }

  void _stopScheduledSlotReminders() {
    _scheduledReminderTimer?.cancel();
    _scheduledReminderTimer = null;
  }

  void _syncScheduledSlotReminders() {
    _stopScheduledSlotReminders();
    if (!scheduledDeliveryEnabled) return;
    if (!Get.isRegistered<ProfileController>()) return;
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;

    final orders = _collectScheduledOrdersForReminders();

    unawaited(ScheduledSlotReminderHelper.syncOrders(orders: orders));

    _scheduledReminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(ScheduledSlotReminderHelper.syncOrders(
        orders: _collectScheduledOrdersForReminders(),
      ));
    });
  }

  List<OrderModel> _collectScheduledOrdersForReminders() {
    final byId = <int, OrderModel>{};
    for (final order in _scheduledCurrentOrders) {
      if (order.id != null) {
        byId[order.id!] = order;
      }
    }
    for (final entry in _locallyMergedScheduledOrders.entries) {
      byId.putIfAbsent(entry.key, () => entry.value);
    }
    return byId.values.toList();
  }

  void setHomeDeliveryTabIndex(int index, {bool isUpdate = true}) {
    _homeDeliveryTabIndex = index;
    if (isUpdate) update();
  }

  void setScheduledHistoryMode(bool enabled, {bool isUpdate = true}) {
    if (_isScheduledHistoryMode == enabled) {
      if (isUpdate) update();
      return;
    }
    _isScheduledHistoryMode = enabled;
    _allOrderHistory = null;
    _outForDeliveryOrderHistory = null;
    _returnOrderHistory = null;
    _canceledOrderHistory = null;
    pauseOrderHistory = null;
    deliveredOrderHistory = null;
    if (isUpdate) update();
  }

  Future<Position?> _resolvePositionForAccept() async {
    return GpsLocationHelper.resolveFreshPosition(
      timeout: const Duration(seconds: 5),
      accuracy: LocationAccuracy.bestForNavigation,
    );
  }

  Future<void> _completeLocalAccept(int orderId, {String? message}) async {
    _handlingTimeoutOrderIds.remove(orderId);
    _timedOutOrderIds.remove(orderId);
    _driverAcceptedOrderIds.add(orderId);
    _promptedOrderIds.remove(orderId);
    _setLocalOrderStatus(orderId, 'confirmed');
    closeNewOrderActionSheet();
    showQuikseeSnackBarWidget(message ?? 'order_accepted'.tr, isError: false);
    _saveAcceptedOrders();
    refreshCurrentOrdersOnly(promptAccept: false);
  }

  /// Keep in-memory current-order status in sync (e.g. right after swipe).
  void setLocalOrderStatus(int orderId, String status) {
    _setLocalOrderStatus(orderId, status);
  }

  /// Sync food-pickup OTP flags from order-details / push into current list.
  void applyPickupOtpFields(OrderModel source) {
    if (source.id == null) return;

    void patch(OrderModel? order) {
      if (order == null) return;
      if (order.id == source.id) {
        _patchPickupOtpOnto(order, source);
      }
      if (order.combinedOrders != null) {
        for (final child in order.combinedOrders!) {
          if (child.id == source.id) {
            _patchPickupOtpOnto(child, source);
          }
        }
      }
    }

    for (final order in _currentOrders) {
      patch(order);
    }
    patch(_locallyMergedOrders[source.id]);
    patch(_locallyMergedScheduledOrders[source.id]);
    update();
  }

  void markPickupOtpVerified(int orderId, {String? verifiedAt}) {
    if (orderId <= 0) return;
    final unlocked = OrderModel(id: orderId);
    unlocked.foodPickupOtpEnabled = 1;
    unlocked.pickupVerificationStatus = 1;
    unlocked.pickupOtpRequired = 0;
    unlocked.canPickup = 1;
    unlocked.pickupVerificationCode = null;
    unlocked.pickupVerifiedAt = verifiedAt;
    applyPickupOtpFields(unlocked);
  }

  void _patchPickupOtpOnto(OrderModel target, OrderModel source) {
    // Never downgrade verified → locked from a stale refresh.
    if (target.pickupVerificationStatus == 1 &&
        source.pickupVerificationStatus != 1) {
      return;
    }
    target.foodPickupOtpEnabled =
        source.foodPickupOtpEnabled ?? target.foodPickupOtpEnabled;
    if (source.pickupVerificationStatus != null) {
      target.pickupVerificationStatus = source.pickupVerificationStatus;
    }
    if (source.pickupOtpRequired != null) {
      target.pickupOtpRequired = source.pickupOtpRequired;
    }
    if (source.canPickup != null) {
      target.canPickup = source.canPickup;
    }
    if (source.pickupVerificationStatus == 1) {
      target.pickupVerificationCode = null;
      target.pickupOtpRequired = 0;
      target.canPickup = 1;
    } else if (source.pickupVerificationCode != null) {
      target.pickupVerificationCode = source.pickupVerificationCode;
    }
    target.pickupVerifiedAt =
        source.pickupVerifiedAt ?? target.pickupVerifiedAt;
  }

  void _setLocalOrderStatus(int orderId, String status) {
    void apply(OrderModel? order) {
      if (order == null) return;
      if (order.id == orderId) {
        order.orderStatus = status;
      }
      if (order.combinedOrders != null) {
        for (final child in order.combinedOrders!) {
          if (child.id == orderId) {
            child.orderStatus = status;
          }
        }
      }
    }

    for (final order in _currentOrders) {
      apply(order);
    }
    apply(_locallyMergedOrders[orderId]);
    apply(_locallyMergedScheduledOrders[orderId]);
    for (final order in _scheduledCurrentOrders) {
      apply(order);
    }
    update();
  }

  /// After swipe, a concurrent current-orders poll can briefly return an older
  /// status. Keep the more advanced in-memory step so the action bar does not
  /// snap back (e.g. Arrived → Out for Delivery).
  void _preserveAdvancedLocalStatuses(
    List<OrderModel> fetched,
    List<OrderModel> previous,
  ) {
    final prevStatus = <int, String>{};
    void collect(OrderModel? order) {
      if (order?.id == null) return;
      final status = (order!.orderStatus ?? '').trim();
      if (status.isEmpty) return;
      prevStatus[order.id!] = status;
      for (final child in order.combinedOrders ?? const <OrderModel>[]) {
        collect(child);
      }
    }

    for (final order in previous) {
      collect(order);
    }

    void apply(OrderModel? order) {
      if (order?.id == null) return;
      final previous = prevStatus[order!.id!];
      if (previous == null || previous.isEmpty) return;
      if (OrderStatusHelper.isTerminalStatus(order.orderStatus)) return;
      if (OrderStatusHelper.isTerminalStatus(previous)) return;
      if (OrderStatusHelper.statusProgressRank(previous) >
          OrderStatusHelper.statusProgressRank(order.orderStatus)) {
        order.orderStatus = previous;
      }
      for (final child in order.combinedOrders ?? const <OrderModel>[]) {
        apply(child);
      }
    }

    for (final order in fetched) {
      apply(order);
    }
  }

  /// Lean scheduled list payloads often omit payment_method after status change.
  void _preservePaymentCollectFieldsOnRefresh(
    List<OrderModel> fetched,
    List<OrderModel> previous,
  ) {
    final prevById = <int, OrderModel>{};
    void collect(OrderModel? order) {
      if (order?.id == null) return;
      prevById[order!.id!] = order;
      for (final child in order.combinedOrders ?? const <OrderModel>[]) {
        collect(child);
      }
    }

    for (final order in previous) {
      collect(order);
    }

    void apply(OrderModel? order) {
      if (order?.id == null) return;
      final prev = prevById[order!.id!];
      if (prev != null) {
        final method = (order.paymentMethod ?? '').trim();
        final prevMethod = (prev.paymentMethod ?? '').trim();
        if (method.isEmpty && prevMethod.isNotEmpty) {
          order.paymentMethod = prev.paymentMethod;
        }
        final payStatus = (order.paymentStatus ?? '').trim();
        final prevPayStatus = (prev.paymentStatus ?? '').trim();
        if (payStatus.isEmpty && prevPayStatus.isNotEmpty) {
          order.paymentStatus = prev.paymentStatus;
        }
      }
      for (final child in order.combinedOrders ?? const <OrderModel>[]) {
        apply(child);
      }
    }

    for (final order in fetched) {
      apply(order);
    }
  }

  bool _isApiSuccess(Response response) {
    return response.statusCode == 200;
  }

  Future<OrderModel?> resolveOrderForAction(int orderId) =>
      _resolveOrderForAction(orderId);

  Future<OrderModel?> _resolveOrderForAction(int orderId) async {
    var order = _findOrderById(orderId);
    if (order != null) return order;

    await refreshCurrentOrdersOnly(force: true, promptAccept: false);
    if (scheduledDeliveryEnabled) {
      await refreshScheduledCurrentOrdersOnly(force: true);
    }
    order = _findOrderById(orderId);
    if (order != null) return order;

    if (Get.isRegistered<AssignmentController>()) {
      final assign = Get.find<AssignmentController>();
      if (assign.usesOfferFlow && assign.hasPendingOfferForOrder(orderId)) {
        return null;
      }
    }

    final response =
        await orderServiceInterface.getSingleOrderHistory('$orderId');
    if (response.statusCode == 200 && response.body is Map) {
      try {
        order = OrderModel.fromJson(response.body as Map<String, dynamic>);
        if (order.id != null) {
          if (order.isScheduledDeliveryOrder) {
            _upsertScheduledOrder(order);
          } else {
            final existing =
                _currentOrders.indexWhere((o) => o.id == order!.id);
            if (existing >= 0) {
              _currentOrders[existing] = order;
            } else {
              _currentOrders.add(order);
            }
          }
          _segregateDeliveryLists();
          update();
        }
        return order;
      } catch (_) {}
    } else if (response.statusCode != 404) {
      ApiChecker.checkApi(response);
    }
    return null;
  }

  Future<bool> acceptOrder(int orderId, {bool forceBackendConfirm = false}) async {
    if (!forceBackendConfirm && _driverAcceptedOrderIds.contains(orderId)) {
      final local = _findOrderById(orderId);
      if (OrderStatusHelper.canSkipAcceptApi(local?.orderStatus)) {
        closeNewOrderActionSheet();
        return true;
      }
    }

    _isActionLoading = true;
    _actionType = 'accept';
    update();

    try {
      final OrderModel? order = await _resolveOrderForAction(orderId);
      final String? currentStatus = order?.orderStatus;

      final bool backendAlreadyAdvanced =
          OrderStatusHelper.canSkipAcceptApi(currentStatus);
      final bool maySkipAcceptApi = backendAlreadyAdvanced &&
          (!_requiresDriverAcceptance() ||
              _driverAcceptedOrderIds.contains(orderId));

      if (maySkipAcceptApi && !forceBackendConfirm) {
        await _completeLocalAccept(
          orderId,
          message: 'order_accepted'.tr,
        );
        return true;
      }

      final bool locationReady =
          await LocationPermissionHelper.ensureLocationReady();
      if (!locationReady) {
        return false;
      }

      final Position? pos = await _resolvePositionForAccept();
      if (pos == null) {
        showQuikseeSnackBarWidget('gps_required_for_accept'.tr);
        return false;
      }

      final acceptStatus =
          OrderStatusHelper.resolveAcceptApiStatus(currentStatus);
      final response = await orderServiceInterface.acceptOrder(
        orderId,
        pos.latitude,
        pos.longitude,
        location: 'Accepted by driver',
        status: acceptStatus,
      );

      if (_isApiSuccess(response)) {
        final msg = response.body is Map
            ? response.body['message']?.toString()
            : null;
        await _completeLocalAccept(orderId, message: msg);
        return true;
      }

      if (response.statusCode == 403) {
        final refreshed = await _resolveOrderForAction(orderId);
        if (OrderStatusHelper.canSkipAcceptApi(refreshed?.orderStatus) &&
            (!_requiresDriverAcceptance() ||
                _driverAcceptedOrderIds.contains(orderId))) {
          await _completeLocalAccept(orderId);
          return true;
        }
      }

      if (response.statusCode != null && response.statusCode! >= 500) {
        showQuikseeSnackBarWidget('server_busy_try_again'.tr);
      } else {
        ApiChecker.checkApi(response);
      }
      return false;
    } finally {
      _isActionLoading = false;
      _actionType = null;
      update();
    }
  }

  Future<bool> cancelAssignedOrder(int orderId, {String? reason}) async {
    _isActionLoading = true;
    _actionType = 'cancel';
    update();

    try {
      await _resolveOrderForAction(orderId);

      final response = await orderServiceInterface.rejectAssignedOrder(
        orderId,
        reason: reason,
      );

      if (response.body != null && response.statusCode == 200) {
        await _markOrderReleased(orderId);
        closeNewOrderActionSheet();
        showQuikseeSnackBarWidget(
          response.body['message'] ?? 'order_released'.tr,
          isError: false,
        );
        refreshCurrentOrdersOnly(promptAccept: false, force: true);
        return true;
      }

      ApiChecker.checkApi(response);
      return false;
    } finally {
      _isActionLoading = false;
      _actionType = null;
      update();
    }
  }

  void showNewOrderActionSheet(int orderId) {
    if (_newOrderSheetOpen) return;
    if (Get.isRegistered<AssignmentController>()) {
      final assign = Get.find<AssignmentController>();
      // the small legacy sheet (it hangs under / over the real offer popup).
      final settingsUnknown = assign.settings == null;
      if (settingsUnknown ||
          assign.usesOfferFlow ||
          assign.isBusyWithOffer ||
          assign.isOfferAlertProtected ||
          assign.hasPendingOfferForOrder(orderId)) {
        if (settingsUnknown || assign.usesOfferFlow) {
          unawaited(assign.ensureOfferPresentedForOrder(orderId));
        }
        return;
      }
    }
    if (_isOrderAlertSuppressed(orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }
    if (_driverAcceptedOrderIds.contains(orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }
    if (_promptedOrderIds.contains(orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }
    final order = _findOrderById(orderId);
    if (order != null && !needsAcceptForOrder(order)) {
      NewOrderAlertHelper.stop();
      return;
    }
    _newOrderSheetOpen = true;
    _promptedOrderIds.add(orderId);

    Future.microtask(() {
      if (Get.context == null) {
        _newOrderSheetOpen = false;
        return;
      }
      if (Get.isRegistered<AssignmentController>()) {
        final assign = Get.find<AssignmentController>();
        if (assign.settings == null ||
            assign.usesOfferFlow ||
            assign.isBusyWithOffer ||
            assign.isOfferAlertProtected ||
            assign.hasPendingOfferForOrder(orderId)) {
          _newOrderSheetOpen = false;
          if (assign.settings == null || assign.usesOfferFlow) {
            unawaited(assign.ensureOfferPresentedForOrder(orderId));
          }
          return;
        }
      }
      final timeout = _resolveAcceptTimeoutSeconds();
      NewOrderAlertHelper.start(
        maxSeconds: timeout,
        onTimeout: () => unawaited(_onNewOrderResponseTimeout(orderId)),
      );
      _startNewOrderResponseTimer(orderId);
      Get.bottomSheet(
        NewOrderActionSheet(orderId: orderId),
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
      ).whenComplete(() {
        _newOrderSheetOpen = false;
        _stopNewOrderResponseTimer();
        if (Get.isRegistered<AssignmentController>()) {
          final assign = Get.find<AssignmentController>();
          if (assign.usesOfferFlow ||
              assign.isOfferSheetOpen ||
              assign.isOfferAlertProtected) {
            return;
          }
        }
        NewOrderAlertHelper.stop();
      });
    });
  }

  Future<void> onAssignedOrderReleasedPush({int? orderId}) async {
    if (orderId == null || orderId <= 0) return;
    _timedOutOrderIds.add(orderId);
    _promptedOrderIds.add(orderId);
    NewOrderAlertHelper.stop();
    _driverAcceptedOrderIds.remove(orderId);
    await _saveAcceptedOrders();
    if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().clearAcceptedOrderBlock(orderId);
    }
    _stopNewOrderResponseTimer();
    _currentOrders.removeWhere((o) => o.id == orderId);
    _scheduledCurrentOrders.removeWhere((o) => o.id == orderId);
    _locallyMergedOrders.remove(orderId);
    _locallyMergedScheduledOrders.remove(orderId);
    unawaited(ScheduledSlotReminderHelper.clearForOrder(orderId));
    if (_newOrderSheetOpen) {
      closeNewOrderActionSheet();
    } else {
      NewOrderAlertHelper.stop();
    }
    update();
    unawaited(refreshCurrentOrdersOnly(promptAccept: false, force: true));
    if (scheduledDeliveryEnabled) {
      unawaited(refreshScheduledCurrentOrdersOnly(force: true));
    }
  }

  Future<void> handleNewOrderNotification({
    required int orderId,
    String? type,
  }) async {
    if (orderId <= 0) return;

    // the FCM that follows after the rider already accepted an offer.
    if (type == 'new_order_assigned') {
      final alreadyOurs = _driverAcceptedOrderIds.contains(orderId) ||
          _isOrderAlertSuppressed(orderId) ||
          currentOrders.any((o) => o.id == orderId) ||
          (Get.isRegistered<AssignmentController>() &&
              Get.find<AssignmentController>()
                  .isOfferAlreadyHandled(orderId: orderId));
      if (alreadyOurs || await NewOrderAlertHelper.isMuted()) {
        NewOrderAlertHelper.muteFor(const Duration(seconds: 90));
        await NewOrderAlertHelper.stop();
        unawaited(refreshCurrentOrdersOnly(promptAccept: false, force: true));
        return;
      }
      await NewOrderAlertHelper.start(
        maxSeconds: 12,
        forceRestart: true,
      );
      await refreshCurrentOrdersOnly(promptAccept: false, force: true);
      return;
    }

    if (Get.isRegistered<AssignmentController>()) {
      final assign = Get.find<AssignmentController>();
      final bool offerFlow = assign.usesOfferFlow ||
          type == 'delivery_assignment_offer' ||
          assign.settings?.autoAssignUseOfferFlow == true;
      if (offerFlow) {
        if (assign.isOfferAlreadyHandled(orderId: orderId)) {
          NewOrderAlertHelper.stop();
          return;
        }
        assign.armOfferArrivalGrace();
        if (!NewOrderAlertHelper.isActive &&
            !await NewOrderAlertHelper.isAlertLive()) {
          await NewOrderAlertHelper.start(
            maxSeconds: assign.offerAcceptTimeoutSeconds,
            loopUntilStopped: true,
          );
        }
        if (assign.hasPendingOfferForOrder(orderId)) {
          await assign.ensureOfferPresentedForOrder(orderId);
          return;
        }
        await assign.refreshAllOffers(showSheet: true);
        if (assign.hasPendingOfferForOrder(orderId)) {
          await assign.ensureOfferPresentedForOrder(orderId);
        }
        return;
      }
    }

    if (_isOrderAlertSuppressed(orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }
    if (_driverAcceptedOrderIds.contains(orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }

    await refreshCurrentOrdersOnly(promptAccept: false, force: true);
    if (_isOrderAlertSuppressed(orderId) ||
        _driverAcceptedOrderIds.contains(orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }
    if (_newOrderSheetOpen) return;

    showNewOrderActionSheet(orderId);
  }

  void startNewOrderPolling() {
    stopNewOrderPolling();
    _pollForNewOrders();
    _newOrderPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _pollForNewOrders();
    });
  }

  void stopNewOrderPolling() {
    _newOrderPollTimer?.cancel();
    _newOrderPollTimer = null;
  }

  int _orderPollPauseCount = 0;
  bool get isOrderPollPaused => _orderPollPauseCount > 0;

  void pauseBackgroundOrderPolls() {
    _orderPollPauseCount++;
  }

  void resumeBackgroundOrderPolls() {
    if (_orderPollPauseCount > 0) {
      _orderPollPauseCount--;
    }
  }

  Future<void> _pollForNewOrders() async {
    if (isOrderPollPaused) return;
    if (!Get.isRegistered<ProfileController>()) return;
    if (_newOrderSheetOpen || _isActionLoading) return;
    if (Get.isRegistered<AssignmentController>() &&
        Get.find<AssignmentController>().isBackgroundSyncPaused) {
      return;
    }
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;
    await refreshCurrentOrdersOnly(
      promptAccept: _shouldPromptAcceptOnPoll(),
    );
    if (scheduledDeliveryEnabled) {
      await refreshScheduledCurrentOrdersOnly(force: false);
    }
  }

  void syncNewOrderPolling() {
    if (!Get.isRegistered<ProfileController>()) return;
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive == true && profile?.isOnline == 1) {
      startNewOrderPolling();
      _syncScheduledSlotReminders();
    } else {
      stopNewOrderPolling();
      _stopScheduledSlotReminders();
    }
  }


  bool _shouldMergeScheduledCurrentOrders(String type, int isPause) {
    if (!_isScheduledHistoryMode) return false;
    if (isPause == 1) return true;
    return type.isEmpty || type == 'out_for_delivery';
  }

  /// statuses when `status` is empty (Assigned), so UI must filter itself.
  bool _matchesHistoryTab(OrderModel order, String type, int isPause) {
    if (isPause == 1) return order.isPause == true;

    final status = (order.orderStatus ?? '').toLowerCase().trim();
    final paused = order.isPause == true;

    if (type == 'out_for_delivery') {
      return (status == 'out_for_delivery' ||
              status == 'arrived_at_customer') &&
          !paused;
    }
    if (type == 'delivered') {
      return status == 'delivered';
    }
    if (type == 'return') {
      return status == 'return' || status == 'returned';
    }
    if (type == 'canceled') {
      return status == 'canceled' || status == 'cancelled';
    }

    // Assigned / All tab: active pickup stages only (OFD + arrived have own tab).
    const terminal = {
      'delivered',
      'canceled',
      'cancelled',
      'return',
      'returned',
      'failed',
    };
    if (terminal.contains(status)) return false;
    if (status == 'out_for_delivery' || status == 'arrived_at_customer') {
      return false;
    }
    if (paused) return false;
    return true;
  }

  bool _matchesScheduledHistoryTab(OrderModel order, String type, int isPause) {
    return _matchesHistoryTab(order, type, isPause);
  }

  List<OrderModel> _filterHistoryByTab(
    List<OrderModel> orders,
    String type,
    int isPause,
  ) {
    return orders
        .where((order) => _matchesHistoryTab(order, type, isPause))
        .toList();
  }

  List<OrderModel> _mergeOrdersById(List<OrderModel> history, List<OrderModel> active) {
    final byId = <int, OrderModel>{};
    for (final order in history) {
      if (order.id != null) byId[order.id!] = order;
    }
    for (final order in active) {
      if (order.id != null) byId[order.id!] = order;
    }
    final merged = byId.values.toList();
    merged.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return merged;
  }

  Future<List<OrderModel>> _getScheduledCurrentOrdersCached({bool force = false}) async {
    if (!scheduledDeliveryEnabled) return _scheduledCurrentOrders;

    final last = _lastScheduledOrdersRefreshAt;
    if (!force &&
        _scheduledCurrentOrders.isNotEmpty &&
        last != null &&
        DateTime.now().difference(last) < _scheduledOrdersCacheTtl) {
      return _scheduledCurrentOrders;
    }
    if (_isFetchingScheduledOrders) {
      var waited = 0;
      while (_isFetchingScheduledOrders && waited < 40) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        waited++;
      }
      return _scheduledCurrentOrders;
    }

    await refreshScheduledCurrentOrdersOnly(force: force);
    return _scheduledCurrentOrders;
  }

  String _historyRequestKey({
    required String type,
    required int isPause,
    required String startDate,
    required String endDate,
    required String search,
  }) {
    return [
      _isScheduledHistoryMode ? 'scheduled' : 'normal',
      dateType,
      type,
      '$isPause',
      startDate,
      endDate,
      search.trim(),
    ].join('|');
  }

  Future<List<OrderModel>> _appendScheduledActiveOrders(
    List<OrderModel> historyOrders,
    String type,
    int isPause,
  ) async {
    var current = _filterVisibleScheduledCurrentOrders(
      await _getScheduledCurrentOrdersCached(),
    );
    _reconcileLocallyMergedScheduledOrders(current);
    _scheduledCurrentOrders = current;

    final active = current
        .where((order) => _matchesScheduledHistoryTab(order, type, isPause))
        .toList();
    return _mergeOrdersById(historyOrders, active);
  }

  Future<void> getAllOrderHistory(
    String dateType,
    String type,
    String startDate,
    String endDate,
    String search,
    int isPause, {
    bool force = false,
  }) async {
    final requestKey = _historyRequestKey(
      type: type,
      isPause: isPause,
      startDate: startDate,
      endDate: endDate,
      search: search,
    );
    if (!force && _isHistoryLoading && _historyFetchKey == requestKey) {
      return;
    }
    _historyFetchKey = requestKey;
    _isHistoryLoading = true;
    update();

    try {
      final Response response = _isScheduledHistoryMode
          ? await orderServiceInterface.getScheduledAllOrderHistory(
              dateType, type, startDate, endDate, search, isPause)
          : await orderServiceInterface.getAllOrderHistory(
              dateType, type, startDate, endDate, search, isPause);

      if (_historyFetchKey != requestKey) return;

      if (response.body != null && response.statusCode == 200) {
        var orders = _isScheduledHistoryMode
            ? ScheduledDeliveryResponseHelper.parseOrderList(response.body)
            : ScheduledDeliveryResponseHelper.extractOrderList(response.body)
                .whereType<Map>()
                .map((raw) =>
                    OrderModel.fromJson(Map<String, dynamic>.from(raw)))
                .toList();

        if (_shouldMergeScheduledCurrentOrders(type, isPause)) {
          try {
            orders =
                await _appendScheduledActiveOrders(orders, type, isPause);
          } catch (_) {}
        }

        if (_historyFetchKey != requestKey) return;

        orders = CombinedOrderHelper.groupOrders(orders);

        if (type != 'delivered' && isPause != 1) {
          _reconcileLocallyMergedIntoHistory(orders);
        }

        if (!_isScheduledHistoryMode &&
            type.isEmpty &&
            isPause != 1 &&
            _currentOrders.isNotEmpty) {
          orders = _mergeOrdersById(orders, _currentOrders);
        }

        _storeHistoryOrders(orders, type: type, isPause: isPause);
      } else {
        // Avoid stuck skeleton when bucket was cleared (mode switch).
        if (_historyBucketIsNull(type: type, isPause: isPause)) {
          _storeHistoryOrders(const [], type: type, isPause: isPause);
        }
        ApiChecker.checkApi(response);
      }
    } catch (_) {
      if (_historyFetchKey == requestKey &&
          _historyBucketIsNull(type: type, isPause: isPause)) {
        _storeHistoryOrders(const [], type: type, isPause: isPause);
      }
    } finally {
      if (_historyFetchKey == requestKey) {
        _isHistoryLoading = false;
        _historyInitialized = true;
        update();
      }
    }
  }

  bool _historyBucketIsNull({required String type, required int isPause}) {
    if (isPause == 1) return pauseOrderHistory == null;
    if (type == 'delivered') return deliveredOrderHistory == null;
    if (type == 'out_for_delivery') return _outForDeliveryOrderHistory == null;
    if (type == 'return') return _returnOrderHistory == null;
    if (type == 'canceled') return _canceledOrderHistory == null;
    return _allOrderHistory == null;
  }

  void _storeHistoryOrders(
    List<OrderModel> orders, {
    required String type,
    required int isPause,
  }) {
    if (type.isEmpty && isPause != 1) {
      _allOrderHistory = _filterHistoryByTab(orders, '', 0);
      return;
    }

    final filtered = _filterHistoryByTab(orders, type, isPause);
    if (isPause == 1) {
      pauseOrderHistory = filtered;
    } else if (type == 'delivered') {
      deliveredOrderHistory = filtered;
    } else if (type == 'out_for_delivery') {
      _outForDeliveryOrderHistory = filtered;
    } else if (type == 'return') {
      _returnOrderHistory = filtered;
    } else if (type == 'canceled') {
      _canceledOrderHistory = filtered;
    } else {
      _allOrderHistory = filtered;
    }
  }

  Future<void> ensureOrderHistoryLoaded({bool force = false}) async {
    if (!force && _historyInitialized && _allOrderHistory != null) {
      return;
    }
    await getAllOrderHistory(dateType, '', '', '', '', 0, force: force);
  }


  Future orderRefresh(BuildContext context) async {
    return getCurrentOrders(promptAccept: !_newOrderSheetOpen);
  }


  void setOrderTypeIndex(
    int index, {
    String startDate = '',
    String endDate = '',
    String search = '',
    bool reload = false,
    bool isUpdate = true,
    bool force = false,
  }) {
    final previousIndex = _orderTypeIndex;
    _orderTypeIndex = index;

    String type = '';
    int isPause = 0;
    if (orderTypeIndex == 1) {
      type = 'out_for_delivery';
    } else if (orderTypeIndex == 2) {
      isPause = 1;
    } else if (orderTypeIndex == 3) {
      type = 'delivered';
    } else if (orderTypeIndex == 4) {
      type = 'return';
    } else if (orderTypeIndex == 5) {
      type = 'canceled';
    }

    final hasCachedData = currentHistoryOrders != null;
    if (!force &&
        !reload &&
        previousIndex == index &&
        hasCachedData &&
        !_isHistoryLoading) {
      if (isUpdate) update();
      return;
    }

    getAllOrderHistory(
      dateType,
      type,
      startDate,
      endDate,
      search,
      isPause,
      force: force || reload,
    );

    if (search.trim().isNotEmpty) {
      _isSearchActive = true;
    }

    if (isUpdate) {
      update();
    }
  }

  void setDateType(DateType type, {bool isUpdate = true}){
    dateType = type.key;
    if(isUpdate) {
      update();
    }
  }

  void setSearchStatus(bool status, {bool isUpdate = true}) {
    _isSearchActive = status;
    if(isUpdate) {
      update();
    }
  }


  String? _startDate;
  String? _endDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-d');
  String ? get startDate => _startDate;
  String ? get endDate => _endDate;
  DateFormat get dateFormat => _dateFormat;

  void selectDate({required String startDate, required String endDate}){
    _startDate = startDate;
    _endDate = endDate;
    update();
  }


  TextEditingController searchOrderController = TextEditingController();

  void setSearchText({String? searchText, bool isUpdate = true}){
    searchOrderController.text = searchText ?? '';
    if(isUpdate){
      update();
    }
  }


  void resetFilters({bool isUpdate = false}){
    _startDate = null;
    _endDate = null;
    dateType = DateType.overall.key;
    searchOrderController.clear();

    if(isUpdate) {
      update();
    }
  }


}
