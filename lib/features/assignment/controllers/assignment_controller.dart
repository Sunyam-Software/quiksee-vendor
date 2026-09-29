import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/assignment/domain/models/assignment_offer_model.dart';
import 'package:quiksee/features/assignment/domain/models/assignment_settings_model.dart';
import 'package:quiksee/features/assignment/domain/models/delivery_areas_model.dart';
import 'package:quiksee/features/assignment/domain/models/scheduled_delivery_config_model.dart';
import 'package:quiksee/features/assignment/domain/repositories/assignment_repository.dart';
import 'package:quiksee/features/assignment/widgets/assignment_offer_sheet.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/helper/gps_location_helper.dart';
import 'package:quiksee/helper/location_permission_helper.dart';
import 'package:quiksee/helper/new_order_alert_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignmentController extends GetxController implements GetxService {
  final AssignmentRepository assignmentRepository;

  AssignmentController({required this.assignmentRepository});

  AssignmentSettingsModel? _settings;
  AssignmentSettingsModel? get settings => _settings;

  DeliveryAreasModel? _deliveryAreas;
  DeliveryAreasModel? get deliveryAreas => _deliveryAreas;

  List<AssignmentOfferModel> _pendingOffers = [];
  List<AssignmentOfferModel> get pendingOffers => _pendingOffers;

  List<AssignmentOfferModel> _scheduledPendingOffers = [];
  List<AssignmentOfferModel> get scheduledPendingOffers => _scheduledPendingOffers;

  ScheduledDeliveryConfigModel? _scheduledConfig;
  ScheduledDeliveryConfigModel? get scheduledConfig => _scheduledConfig;
  bool get scheduledDeliveryEnabled =>
      _scheduledConfig?.scheduledDeliveryEnabled == true;

  int get scheduledLeadTimeMinutes =>
      _scheduledConfig?.leadTimeMinutes ?? 30;

  AssignmentOfferModel? _activeOffer;
  AssignmentOfferModel? get activeOffer => _activeOffer;

  Timer? _pollTimer;
  Timer? _scheduledPollTimer;
  Timer? _locationTimer;
  Timer? _countdownTimer;
  Timer? _offerSheetWatchdog;

  bool _isAccepting = false;
  bool get isAccepting => _isAccepting;

  bool _isRejecting = false;
  bool get isRejecting => _isRejecting;

  bool _offerSheetOpen = false;

  bool get isOfferSheetOpen => _offerSheetOpen;

  bool get isBusyWithOffer =>
      _offerSheetOpen || _isAccepting || _isRejecting;
  int? _shownOfferId;
  int? _pendingPresentOfferId;
  final Set<int> _timedOutOfferIds = {};
  final Set<int> _timedOutOrderIds = {};
  final Set<int> _handlingTimeoutOfferIds = {};
  /// Popup/alert ended but offer stays in Notifications for Accept.
  final Set<int> _sheetSoftDismissedOfferIds = {};
  final Set<int> _acceptedOfferIds = {};
  /// Require N empty polls before dismissing a live ringing offer (anti-flicker).
  /// When the bell is already live, 1 empty poll is enough (another DM accepted).
  int _consecutiveEmptyOfferPolls = 0;
  static const int _emptyOfferDismissStreak = 2;
  static const int _emptyOfferDismissStreakWhileRinging = 1;
  final Set<int> _acceptedOfferOrderIds = {};
  final Set<int> _dismissedOfferIds = {};
  final Set<int> _invalidOfferIds = {};
  bool _invalidOffersLoaded = false;
  Completer<void>? _invalidOffersLoadCompleter;
  final Set<int> _dismissedOrderIds = {};
  final Map<int, DateTime> _rejectedOfferUntil = {};
  int? _rejectingOfferId;
  int _reOfferPollToken = 0;
  DateTime? _offerFetchGraceUntil;
  /// Offer IDs that appeared at least once in a successful pending-offers response.
  final Set<int> _serverConfirmedOfferIds = {};
  /// Consecutive polls where a specific live offer_id was missing (anti-flicker).
  final Map<int, int> _offerMissingPollStreak = {};
  DateTime? _offerSheetOpenedAt;
  /// After accept/reject, block re-open from stale FCM / wake prefs / poll.
  DateTime? _suppressOfferUiUntil;
  /// Invalidates delayed sheet open / retry callbacks (multi-offer stuck fix).
  int _offerUiGeneration = 0;
  bool _isFetchingOffers = false;
  bool _isFetchingScheduledOffers = false;
  Completer<void>? _offersFetchCompleter;
  Completer<void>? _scheduledOffersFetchCompleter;
  bool _isSendingIdleLocation = false;

  bool isOfferAlreadyHandled({int? offerId, int? orderId}) {
    if (offerId != null) {
      if (_acceptedOfferIds.contains(offerId)) return true;
      if (_invalidOfferIds.contains(offerId)) return true;
      if (_isRejectCooldownActive(offerId)) return true;
      if (_timedOutOfferIds.contains(offerId)) return true;
      // FCM/wake would never clear _timedOutOrderIds otherwise.
      return false;
    }
    if (orderId != null) {
      if (_acceptedOfferOrderIds.contains(orderId)) return true;
      if (_timedOutOrderIds.contains(orderId)) return true;
    }
    return false;
  }

  Future<void> ensureInvalidOffersLoaded() async {
    if (_invalidOffersLoaded) return;
    if (_invalidOffersLoadCompleter != null) {
      await _invalidOffersLoadCompleter!.future;
      return;
    }
    _invalidOffersLoadCompleter = Completer<void>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          prefs.getStringList(AppConstants.invalidAssignmentOfferIds) ?? [];
      for (final value in raw) {
        final id = int.tryParse(value);
        if (id != null && id > 0) {
          _invalidOfferIds.add(id);
          _acceptedOfferIds.add(id);
        }
      }
      _invalidOffersLoaded = true;
    } finally {
      if (!(_invalidOffersLoadCompleter?.isCompleted ?? true)) {
        _invalidOffersLoadCompleter!.complete();
      }
      _invalidOffersLoadCompleter = null;
    }
  }

  Future<void> _persistInvalidOfferIds() async {
    final prefs = await SharedPreferences.getInstance();
    // Cap list so prefs don't grow forever.
    final ids = _invalidOfferIds.toList()..sort();
    final trimmed = ids.length > 80 ? ids.sublist(ids.length - 80) : ids;
    await prefs.setStringList(
      AppConstants.invalidAssignmentOfferIds,
      trimmed.map((e) => '$e').toList(),
    );
  }

  /// Clear permanent accept-block so release → re-offer can ring again.
  void clearAcceptedOrderBlock(int? orderId) {
    if (orderId == null || orderId <= 0) return;
    _acceptedOfferOrderIds.remove(orderId);
    _timedOutOrderIds.remove(orderId);
    _dismissedOrderIds.remove(orderId);
  }

  /// Mark offer dead (expired / taken / cancelled) so app restart cannot revive it.
  void markOfferInvalid({int? offerId, int? orderId}) {
    if (offerId != null && offerId > 0) {
      _invalidOfferIds.add(offerId);
      _acceptedOfferIds.add(offerId);
      _timedOutOfferIds.add(offerId);
      _sheetSoftDismissedOfferIds.remove(offerId);
      _pendingOffers.removeWhere((o) => o.offerId == offerId);
      _scheduledPendingOffers.removeWhere((o) => o.offerId == offerId);
      unawaited(_persistInvalidOfferIds());
    }
    if (orderId != null && orderId > 0) {
      _pendingOffers.removeWhere((o) => o.orderId == orderId);
      _scheduledPendingOffers.removeWhere((o) => o.orderId == orderId);
    }
    if ((_activeOffer?.offerId != null && _activeOffer!.offerId == offerId) ||
        (_shownOfferId != null && _shownOfferId == offerId)) {
      _activeOffer = null;
      _shownOfferId = null;
      _forceCloseAllOfferSheets();
      NewOrderAlertHelper.stop();
    }
  }

  bool _isRejectCooldownActive(int offerId) {
    final until = _rejectedOfferUntil[offerId];
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _rejectedOfferUntil.remove(offerId);
    _dismissedOfferIds.remove(offerId);
    _timedOutOfferIds.remove(offerId);
    return false;
  }

  bool get _isOfferUiSuppressed {
    final until = _suppressOfferUiUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _suppressOfferUi({int seconds = 45}) {
    _suppressOfferUiUntil =
        DateTime.now().add(Duration(seconds: seconds.clamp(5, 120)));
    _offerFetchGraceUntil = null;
    _bumpOfferUiGeneration();
  }

  void _bumpOfferUiGeneration() {
    _offerUiGeneration++;
    _offerSheetWatchdog?.cancel();
    _countdownTimer?.cancel();
    _pendingPresentOfferId = null;
  }

  /// Close every stacked bottom sheet so Accept can't leave a stuck popup.
  void _forceCloseAllOfferSheets() {
    _offerSheetWatchdog?.cancel();
    _countdownTimer?.cancel();
    _pendingPresentOfferId = null;
    var guard = 0;
    while (Get.isBottomSheetOpen == true && guard < 5) {
      Get.back();
      guard++;
    }
    _offerSheetOpen = false;
    _shownOfferId = null;
  }

  bool hasPendingOfferForOrder(int orderId) {
    if (orderId <= 0) return false;
    if (_activeOffer?.orderId == orderId) return true;
    return _pendingOffers.any((o) => o.orderId == orderId) ||
        _scheduledPendingOffers.any((o) => o.orderId == orderId);
  }

  /// Normal + scheduled offers the driver can still accept.
  List<AssignmentOfferModel> get actionablePendingOffers {
    final byOfferId = <int, AssignmentOfferModel>{};
    for (final offer in [..._pendingOffers, ..._scheduledPendingOffers]) {
      final id = offer.offerId;
      if (id == null || id <= 0) continue;
      if (isOfferAlreadyHandled(offerId: id, orderId: offer.orderId)) {
        continue;
      }
      if (_timedOutOfferIds.contains(id)) continue;
      byOfferId[id] = offer;
    }
    return byOfferId.values.toList();
  }

  int get pendingOfferBadgeCount => actionablePendingOffers.length;

  bool get hasActionablePendingOffers => pendingOfferBadgeCount > 0;

  int get offerAcceptTimeoutSeconds =>
      (_settings?.autoAssignTimeoutSeconds ?? 1800).clamp(60, 14400);

  /// Ensures the offer sheet and bell are shown for a known pending order.
  Future<void> ensureOfferPresentedForOrder(int orderId) async {
    if (orderId <= 0) return;
    if (isOfferAlreadyHandled(orderId: orderId)) return;
    if (_offerSheetOpen && _activeOffer?.orderId == orderId) return;

    armOfferArrivalGrace();
    var offer = _findPendingOffer(orderId: orderId);
    if (offer == null) {
      await refreshAllOffers(showSheet: false);
      offer = _findPendingOffer(orderId: orderId);
    }
    if (offer?.offerId == null) return;
    if (_sheetSoftDismissedOfferIds.contains(offer!.offerId!)) return;

    _presentOfferSheet(offer);
  }

  bool get usesOfferFlow => _settings?.autoAssignUseOfferFlow == true;

  void markOfferHandled({int? offerId, int? orderId}) {
    _markOfferHandled(offerId: offerId, orderId: orderId);
  }

  /// Blocks empty-offer polls from killing the ringtone while an offer is arriving.
  void armOfferArrivalGrace({int? seconds}) {
    final timeout = seconds ??
        _settings?.autoAssignTimeoutSeconds ??
        30;
    _offerFetchGraceUntil =
        DateTime.now().add(Duration(seconds: timeout + 20));
  }

  bool get isOfferAlertProtected {
    if (isBusyWithOffer || _offerSheetOpen) return true;
    if (_pendingPresentOfferId != null) return true;
    if (NewOrderAlertHelper.isActive) return true;
    final grace = _offerFetchGraceUntil;
    if (grace != null && DateTime.now().isBefore(grace)) return true;
    return _activeOffer != null || _shownOfferId != null;
  }

  Future<bool> isOfferAlertProtectedAsync() async {
    if (isOfferAlertProtected) return true;
    return NewOrderAlertHelper.isAlertLive();
  }

  void _markOfferHandled({int? offerId, int? orderId}) {
    if (offerId != null) {
      _acceptedOfferIds.add(offerId);
      _invalidOfferIds.add(offerId);
      _sheetSoftDismissedOfferIds.remove(offerId);
      unawaited(_persistInvalidOfferIds());
    }
    if (orderId != null) {
      _acceptedOfferOrderIds.add(orderId);
    }
  }

  void _markOfferDismissed({int? offerId, int? orderId}) {
    if (offerId != null) {
      _dismissedOfferIds.add(offerId);
      _timedOutOfferIds.add(offerId);
      _sheetSoftDismissedOfferIds.remove(offerId);
      _rejectedOfferUntil[offerId] =
          DateTime.now().add(const Duration(seconds: 12));
    }
    if (orderId != null) {
      _timedOutOrderIds.add(orderId);
    }
  }

  void _reconcileLiveOffersFromServer(List<AssignmentOfferModel> offers) {
    final now = DateTime.now();
    _rejectedOfferUntil.removeWhere((id, until) {
      if (now.isBefore(until)) return false;
      _dismissedOfferIds.remove(id);
      _timedOutOfferIds.remove(id);
      return true;
    });

    for (final offer in offers) {
      final id = offer.offerId;
      if (id == null || id <= 0) continue;
      if (_isRejectCooldownActive(id)) continue;
      // Server is offering this again (or still) → show Accept.
      _dismissedOfferIds.remove(id);
      _timedOutOfferIds.remove(id);
      _sheetSoftDismissedOfferIds.remove(id);
      final oid = offer.orderId;
      if (oid != null) {
        _dismissedOrderIds.remove(oid);
        _timedOutOrderIds.remove(oid);
      }
    }
  }

  int _pollIntervalSeconds = 15;
  int _locationIntervalSeconds = 30;
  bool _driverBusy = false;
  int _backgroundSyncPauseCount = 0;

  bool get isDriverBusy => _driverBusy;
  bool get isBackgroundSyncPaused => _backgroundSyncPauseCount > 0;

  /// Pause offer/location polls so critical actions (swipe status) get bandwidth.
  void pauseBackgroundSync() {
    _backgroundSyncPauseCount++;
  }

  void resumeBackgroundSync() {
    if (_backgroundSyncPauseCount > 0) {
      _backgroundSyncPauseCount--;
    }
  }

  /// Call after accept / pickup so offer polls slow down immediately.
  void markDriverBusy([bool busy = true]) {
    final changed = _driverBusy != busy;
    _driverBusy = busy;
    if (changed && _pollTimer != null) {
      startPolling();
    }
  }

  @override
  void onClose() {
    stopServices();
    super.onClose();
  }

  Future<void> syncWithDriverStatus() async {
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.assignmentSettings != null) {
      _settings = profile!.assignmentSettings;
      _pollIntervalSeconds =
          (_settings?.pollOffersIntervalSeconds ?? 15).clamp(5, 45);
      _locationIntervalSeconds =
          _settings?.sendIdleLocationIntervalSeconds ?? 30;
    }

    await ensureInvalidOffersLoaded();
    await loadScheduledConfig();

    if (profile?.isAccountActive == true && profile?.isOnline == 1) {
      if (_settings == null) {
        await loadAssignmentSettings();
      }
      startServices();
      await refreshAllOffers(
        showSheet: (profile?.pendingOffersCount ?? 0) > 0,
      );
      if (_pendingOffers.isEmpty &&
          _scheduledPendingOffers.isEmpty &&
          !await isOfferAlertProtectedAsync()) {
        NewOrderAlertHelper.stop();
      }
    } else {
      stopServices();
    }
  }

  Future<void> loadScheduledConfig() async {
    final response = await assignmentRepository.getScheduledDeliveryConfig();
    if (response.statusCode == 200 && response.body != null) {
      final body = response.body;
      if (body is Map<String, dynamic>) {
        _scheduledConfig = ScheduledDeliveryConfigModel.fromJson(body);
        // Keep Normal poll interval from assignment settings; Scheduled uses its own timer.
        update();
      }
    }
  }

  Future<void> loadAssignmentSettings() async {
    final response = await assignmentRepository.getAssignmentSettings();
    if (response.statusCode == 200 && response.body != null) {
      final body = response.body as Map<String, dynamic>;
      if (body['settings'] != null) {
        _settings = AssignmentSettingsModel.fromJson(body['settings']);
        _pollIntervalSeconds =
            (_settings?.pollOffersIntervalSeconds ?? 15).clamp(5, 45);
        _locationIntervalSeconds =
            _settings?.sendIdleLocationIntervalSeconds ?? 30;
      }
      update();
    }
  }

  Future<void> loadDeliveryAreas() async {
    final response = await assignmentRepository.getDeliveryAreas();
    if (response.statusCode == 200 && response.body != null) {
      _deliveryAreas =
          DeliveryAreasModel.fromJson(response.body as Map<String, dynamic>);
      update();
    }
  }

  void startServices() {
    startPolling();
    startIdleLocationUpdates();
  }

  void stopServices() {
    stopPolling();
    stopIdleLocationUpdates();
    _closeOfferSheet();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _scheduledPollTimer?.cancel();
    // stops our ring even if cancel FCM is delayed.
    final alertLive = NewOrderAlertHelper.isActive ||
        _offerSheetOpen ||
        _activeOffer != null ||
        _shownOfferId != null;
    final interval = _driverBusy
        ? 90
        : (alertLive ? 2 : _pollIntervalSeconds.clamp(5, 45));
    _pollTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) {
        if (isBackgroundSyncPaused) return;
        if (_driverBusy) {
          unawaited(fetchPendingOffers(showSheet: false));
          return;
        }
        final live = NewOrderAlertHelper.isActive ||
            _offerSheetOpen ||
            _activeOffer != null ||
            _shownOfferId != null;
        // Switch cadence when ring starts/stops without waiting for next cycle.
        final wantInterval = live ? 2 : _pollIntervalSeconds.clamp(5, 45);
        if (wantInterval != interval && !_driverBusy) {
          startPolling();
          return;
        }
        unawaited(fetchPendingOffers(showSheet: !live));
      },
    );
    if (scheduledDeliveryEnabled) {
      final scheduledInterval = _driverBusy
          ? 90
          : (_scheduledConfig?.pollOffersIntervalSeconds ?? _pollIntervalSeconds)
              .clamp(5, 60);
      _scheduledPollTimer = Timer.periodic(
        Duration(seconds: scheduledInterval),
        (_) {
          if (isBackgroundSyncPaused || _driverBusy) return;
          unawaited(fetchScheduledPendingOffers(showSheet: true));
        },
      );
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _scheduledPollTimer?.cancel();
    _scheduledPollTimer = null;
  }

  Future<void> refreshAllOffers({bool showSheet = false}) async {
    await Future.wait([
      fetchPendingOffers(showSheet: false),
      if (scheduledDeliveryEnabled)
        fetchScheduledPendingOffers(showSheet: false),
    ]);
    _presentNextOfferIfNeeded(showSheet: showSheet);
  }

  void startIdleLocationUpdates() {
    _locationTimer?.cancel();
    sendIdleLocation();
    _locationTimer = Timer.periodic(
      Duration(seconds: _locationIntervalSeconds),
      (_) => sendIdleLocation(),
    );
  }

  void stopIdleLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> sendIdleLocation() async {
    if (_isSendingIdleLocation || isBackgroundSyncPaused) return;
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;

    _isSendingIdleLocation = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await LocationPermissionHelper.ensureLocationReadyForOnline(
          context: Get.context,
        );
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await LocationPermissionHelper.ensureLocationReadyForOnline(
          context: Get.context,
        );
        return;
      }

      final Position? position = await GpsLocationHelper.resolveFreshPosition(
        timeout: const Duration(seconds: 8),
        accuracy: LocationAccuracy.bestForNavigation,
      );
      if (position == null) {
        return;
      }

      String locationLabel =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          locationLabel = [
            p.subLocality,
            p.locality,
            p.postalCode,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          if (locationLabel.isEmpty) {
            locationLabel =
                '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
          }
        }
      } catch (_) {}

      await assignmentRepository.updateLiveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        location: locationLabel,
      );

      if (!_driverBusy &&
          !isBackgroundSyncPaused &&
          !_offerSheetOpen &&
          _pendingPresentOfferId == null) {
        unawaited(refreshAllOffers(showSheet: true));
      }

      if (Get.isRegistered<RiderController>()) {
        await Get.find<RiderController>().pollExternalNavigationArrival();
      }
    } catch (_) {} finally {
      _isSendingIdleLocation = false;
    }
  }

  List<AssignmentOfferModel> _filterOffers(List<AssignmentOfferModel> offers) {
    _reconcileLiveOffersFromServer(offers);
    return offers.where((offer) {
      if (offer.offerId != null &&
          !_isRejectCooldownActive(offer.offerId!) &&
          !_acceptedOfferIds.contains(offer.offerId) &&
          !_invalidOfferIds.contains(offer.offerId) &&
          offer.orderId != null) {
        _timedOutOrderIds.remove(offer.orderId);
        _dismissedOrderIds.remove(offer.orderId);
      }

      if (isOfferAlreadyHandled(
        offerId: offer.offerId,
        orderId: offer.orderId,
      )) {
        return false;
      }
      if (offer.offerId != null && _isRejectCooldownActive(offer.offerId!)) {
        return false;
      }
      if (offer.secondsRemaining != null && offer.secondsRemaining! <= 0) {
        _rememberInvalidOfferId(offer.offerId);
        return false;
      }
      if (OrderStatusHelper.isTerminalStatus(offer.orderStatus)) {
        _rememberInvalidOfferId(offer.offerId);
        return false;
      }
      return true;
    }).toList();
  }

  void _rememberInvalidOfferId(int? offerId) {
    if (offerId == null || offerId <= 0) return;
    if (_invalidOfferIds.add(offerId)) {
      _acceptedOfferIds.add(offerId);
      unawaited(_persistInvalidOfferIds());
    }
  }

  Future<void> fetchPendingOffers({
    bool showSheet = false,
    bool forceRefresh = false,
  }) async {
    if (isBackgroundSyncPaused && !forceRefresh) return;
    // Never wait forever on a stuck poll when FCM needs the popup NOW.
    if (_isFetchingOffers) {
      if (!forceRefresh) {
        await _offersFetchCompleter?.future;
        if (showSheet) {
          _presentNextOfferIfNeeded(showSheet: true);
        }
        return;
      }
      try {
        await _offersFetchCompleter?.future
            .timeout(const Duration(milliseconds: 400));
      } catch (_) {}
      if (_isFetchingOffers) {
        await _priorityApplyPendingOffers(showSheet: showSheet);
        return;
      }
    }
    while (_isFetchingOffers) {
      await _offersFetchCompleter?.future;
    }
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;

    _isFetchingOffers = true;
    _offersFetchCompleter = Completer<void>();
    try {
      final response = await assignmentRepository.getPendingOffers();
      _applyPendingOffersResponse(response, showSheet: showSheet);
    } finally {
      _isFetchingOffers = false;
      if (!(_offersFetchCompleter?.isCompleted ?? true)) {
        _offersFetchCompleter!.complete();
      }
      _offersFetchCompleter = null;
    }
  }

  Future<void> _priorityApplyPendingOffers({bool showSheet = false}) async {
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;
    final response = await assignmentRepository.getPendingOffers();
    _applyPendingOffersResponse(response, showSheet: showSheet);
  }

  void _applyPendingOffersResponse(
    Response response, {
    required bool showSheet,
  }) {
    if (response.statusCode == 200 && response.body != null) {
      final data = PendingOffersResponse.fromJson(
        response.body as Map<String, dynamic>,
      );
      final wasBusy = _driverBusy;
      _driverBusy = data.driverBusy ||
          ((data.activeOrderId ?? 0) > 0 && (data.offersCount ?? 0) == 0);
      if (data.settings != null) {
        _settings = data.settings;
        final nextPoll =
            (_settings?.pollOffersIntervalSeconds ?? 15).clamp(5, 45);
        if (nextPoll != _pollIntervalSeconds) {
          _pollIntervalSeconds = nextPoll;
        }
      }
      // Restart timer when busy↔idle changes so pick-up swipe isn't starved.
      if (wasBusy != _driverBusy && _pollTimer != null) {
        startPolling();
      }

      final previousActiveOfferId = _activeOffer?.offerId ?? _shownOfferId;
      final previousActiveOrderId = _activeOffer?.orderId;
      final wasRingingOrSheet = NewOrderAlertHelper.isActive ||
          _offerSheetOpen ||
          previousActiveOfferId != null;

      final rawOffers = data.offers ?? [];
      final rawIds = rawOffers
          .map((o) => o.offerId)
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
      _pendingOffers = _filterOffers(rawOffers);
      if (_activeOffer?.offerId != null) {
        for (final offer in _pendingOffers) {
          if (offer.offerId == _activeOffer!.offerId) {
            _activeOffer!.mergeFrom(offer);
            break;
          }
        }
      }

      final keepCurrentOffer = data.keepCurrentOffer == true ||
          (data.assignmentRecovery?['error'] == true) ||
          (data.driverBusy == true && wasRingingOrSheet);

      // Soft-hide when busy must not kill a live ringing offer on first empty.
      // Count empty only when server returned no raw offers (not filter-only).
      final hasAnyServerOffers = rawIds.isNotEmpty;
      final hasScheduledLive = _scheduledPendingOffers.isNotEmpty;

      if (hasAnyServerOffers || hasScheduledLive) {
        _consecutiveEmptyOfferPolls = 0;
      } else if (wasRingingOrSheet && !_isAccepting && !_isRejecting) {
        _consecutiveEmptyOfferPolls += 1;
      } else {
        _consecutiveEmptyOfferPolls = 0;
      }

      // Track offers confirmed by a healthy server response (not error keep-alive).
      if (!keepCurrentOffer) {
        _serverConfirmedOfferIds.addAll(rawIds);
        for (final id in rawIds) {
          _offerMissingPollStreak.remove(id);
        }
      }

      final activeIsScheduled = _activeOffer?.isScheduled == true;
      if (wasRingingOrSheet &&
          previousActiveOfferId != null &&
          !activeIsScheduled &&
          !_isAccepting &&
          !_isRejecting) {
        final stillOnServer = rawIds.contains(previousActiveOfferId) ||
            _scheduledPendingOffers.any((o) => o.offerId == previousActiveOfferId);
        if (stillOnServer) {
          _offerMissingPollStreak.remove(previousActiveOfferId);
        } else if (!_shouldKeepLiveOfferSheet(
          keepCurrentOffer: keepCurrentOffer,
          hasAnyServerOffers: hasAnyServerOffers,
          offerId: previousActiveOfferId,
        )) {
          _dismissVanishedLiveOffer(
            offerId: previousActiveOfferId,
            orderId: previousActiveOrderId,
          );
          return;
        } else if (!rawIds.contains(previousActiveOfferId)) {
          update();
          return;
        }
      }

      if (_driverBusy) {
        // Server: complete current delivery before new offers.
        if (showSheet) {
          // no-op present
        } else if (_pendingOffers.isEmpty &&
            _scheduledPendingOffers.isEmpty &&
            _consecutiveEmptyOfferPolls >= _emptyOfferDismissStreak) {
          unawaited(_handleNoOffersRemaining());
        }
      } else if (showSheet) {
        _presentNextOfferIfNeeded(showSheet: true);
      } else if (_pendingOffers.isEmpty &&
          _scheduledPendingOffers.isEmpty &&
          !wasRingingOrSheet) {
        unawaited(_handleNoOffersRemaining());
      } else if (_pendingOffers.isEmpty &&
          _scheduledPendingOffers.isEmpty &&
          wasRingingOrSheet &&
          _consecutiveEmptyOfferPolls >= _emptyOfferDismissStreak) {
        unawaited(_handleNoOffersRemaining());
      }
      update();
    }
  }

  Future<void> fetchScheduledPendingOffers({
    bool showSheet = false,
    bool forceRefresh = false,
  }) async {
    if (!scheduledDeliveryEnabled) return;
    if (isBackgroundSyncPaused && !forceRefresh) return;
    if (_isFetchingScheduledOffers) {
      if (!forceRefresh) {
        await _scheduledOffersFetchCompleter?.future;
        if (showSheet) {
          _presentNextOfferIfNeeded(showSheet: true);
        }
        return;
      }
      try {
        await _scheduledOffersFetchCompleter?.future
            .timeout(const Duration(milliseconds: 400));
      } catch (_) {}
      if (_isFetchingScheduledOffers) {
        await _priorityApplyScheduledPendingOffers(showSheet: showSheet);
        return;
      }
    }
    while (_isFetchingScheduledOffers) {
      await _scheduledOffersFetchCompleter?.future;
    }
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;

    _isFetchingScheduledOffers = true;
    _scheduledOffersFetchCompleter = Completer<void>();
    try {
      final response = await assignmentRepository.getScheduledPendingOffers();
      _applyScheduledPendingOffersResponse(response, showSheet: showSheet);
    } finally {
      _isFetchingScheduledOffers = false;
      if (!(_scheduledOffersFetchCompleter?.isCompleted ?? true)) {
        _scheduledOffersFetchCompleter!.complete();
      }
      _scheduledOffersFetchCompleter = null;
    }
  }

  Future<void> _priorityApplyScheduledPendingOffers({
    bool showSheet = false,
  }) async {
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) return;
    final response = await assignmentRepository.getScheduledPendingOffers();
    _applyScheduledPendingOffersResponse(response, showSheet: showSheet);
  }

  void _applyScheduledPendingOffersResponse(
    Response response, {
    required bool showSheet,
  }) {
    if (response.statusCode == 200 && response.body != null) {
      final data = PendingOffersResponse.fromJson(
        response.body as Map<String, dynamic>,
      );

      final previousActiveOfferId = _activeOffer?.offerId ?? _shownOfferId;
      final previousActiveOrderId = _activeOffer?.orderId;
      final wasRingingOrSheet = NewOrderAlertHelper.isActive ||
          _offerSheetOpen ||
          previousActiveOfferId != null;

      final rawOffers = data.offers ?? [];
      final rawIds = rawOffers
          .map((o) => o.offerId)
          .whereType<int>()
          .where((id) => id > 0)
          .toSet();
      _scheduledPendingOffers = _filterOffers(rawOffers);
      if (_activeOffer?.offerId != null) {
        for (final offer in _scheduledPendingOffers) {
          if (offer.offerId == _activeOffer!.offerId) {
            _activeOffer!.mergeFrom(offer);
            break;
          }
        }
      }

      if (wasRingingOrSheet &&
          previousActiveOfferId != null &&
          _activeOffer?.isScheduled == true &&
          !_isAccepting &&
          !_isRejecting) {
        final stillOnServer = rawIds.contains(previousActiveOfferId) ||
            _pendingOffers.any((o) => o.offerId == previousActiveOfferId);
        if (stillOnServer) {
          _serverConfirmedOfferIds.add(previousActiveOfferId);
          _offerMissingPollStreak.remove(previousActiveOfferId);
        } else if (!_shouldKeepLiveOfferSheet(
          keepCurrentOffer: data.keepCurrentOffer == true ||
              data.driverBusy == true,
          hasAnyServerOffers: rawIds.isNotEmpty,
          offerId: previousActiveOfferId,
        )) {
          _dismissVanishedLiveOffer(
            offerId: previousActiveOfferId,
            orderId: previousActiveOrderId,
          );
          return;
        } else if (!rawIds.contains(previousActiveOfferId)) {
          update();
          return;
        }
      } else {
        _serverConfirmedOfferIds.addAll(rawIds);
      }

      if (showSheet) {
        _presentNextOfferIfNeeded(showSheet: true);
      } else if (_pendingOffers.isEmpty && _scheduledPendingOffers.isEmpty) {
        unawaited(_handleNoOffersRemaining());
      }
      update();
    }
  }

  bool _shouldKeepLiveOfferSheet({
    required bool keepCurrentOffer,
    required bool hasAnyServerOffers,
    required int offerId,
  }) {
    if (keepCurrentOffer) return true;

    // First ~12s after sheet open: FCM lean → pending-offers enrich race.
    final openedAt = _offerSheetOpenedAt;
    if (openedAt != null &&
        DateTime.now().difference(openedAt) < const Duration(seconds: 12)) {
      return true;
    }

    if (_sheetSoftDismissedOfferIds.contains(offerId) ||
        _timedOutOfferIds.contains(offerId)) {
      return false;
    }

    final missStreak = (_offerMissingPollStreak[offerId] ?? 0) + 1;
    _offerMissingPollStreak[offerId] = missStreak;
    // Other offers present ⇒ server healthy → 1 miss enough for "taken".
    // Empty list ⇒ race/busy → need 2 consecutive misses.
    final requiredMisses = hasAnyServerOffers ? 1 : 2;
    return missStreak < requiredMisses;
  }

  void _dismissVanishedLiveOffer({
    required int offerId,
    int? orderId,
  }) {
    if (_sheetSoftDismissedOfferIds.contains(offerId) ||
        _timedOutOfferIds.contains(offerId)) {
      _pendingPresentOfferId = null;
      _closeOfferSheet();
      _activeOffer = null;
      _shownOfferId = null;
      unawaited(NewOrderAlertHelper.stop());
      return;
    }
    _offerMissingPollStreak.remove(offerId);
    _timedOutOfferIds.add(offerId);
    final wasConfirmed = _serverConfirmedOfferIds.contains(offerId);
    final secondsLeft = _activeOffer?.secondsRemaining ?? 0;
    final likelyTaken = wasConfirmed && secondsLeft > 2;
    onOfferCancelledPush(
      offerId: offerId,
      orderId: orderId,
      showCancelledMessage: likelyTaken,
      cancelReason: likelyTaken ? 'accepted_by_another' : 'expired',
    );
  }

  Future<void> _handleNoOffersRemaining() async {
    if (_isAccepting || _isRejecting) return;

    // Stale "sheet open" flag after unexpected dismiss.
    if (_offerSheetOpen && Get.isBottomSheetOpen != true) {
      _offerSheetOpen = false;
      _shownOfferId = null;
      _pendingPresentOfferId = null;
    }

    final lostOfferId = _activeOffer?.offerId ?? _shownOfferId;
    final lostOrderId = _activeOffer?.orderId;
    final wasShowingOffer = lostOfferId != null ||
        _offerSheetOpen ||
        NewOrderAlertHelper.isActive;

    // Anti-flicker: one empty poll must not kill a live offer sheet/ring.
    if (wasShowingOffer &&
        _consecutiveEmptyOfferPolls < _emptyOfferDismissStreak) {
      return;
    }

    final openedAt = _offerSheetOpenedAt;
    if (wasShowingOffer &&
        openedAt != null &&
        DateTime.now().difference(openedAt) < const Duration(seconds: 12)) {
      return;
    }

    if (wasShowingOffer) {
      if (lostOfferId != null &&
          (_sheetSoftDismissedOfferIds.contains(lostOfferId) ||
              _timedOutOfferIds.contains(lostOfferId))) {
        _pendingPresentOfferId = null;
        _activeOffer = null;
        _shownOfferId = null;
        _closeOfferSheet();
        return;
      }
      onOfferCancelledPush(
        offerId: lostOfferId,
        orderId: lostOrderId,
        showCancelledMessage: lostOfferId != null &&
            _serverConfirmedOfferIds.contains(lostOfferId) &&
            ((_activeOffer?.secondsRemaining ?? 0) > 2),
        cancelReason: (lostOfferId != null &&
                _serverConfirmedOfferIds.contains(lostOfferId) &&
                ((_activeOffer?.secondsRemaining ?? 0) > 2))
            ? 'accepted_by_another'
            : 'expired',
      );
      return;
    }

    if (_pendingPresentOfferId != null) return;

    final inGrace = _offerFetchGraceUntil != null &&
        DateTime.now().isBefore(_offerFetchGraceUntil!);

    if (inGrace && _activeOffer != null && _activeOffer!.offerId != null) {
      _showOfferSheetNow(_activeOffer!);
      return;
    }

    _offerFetchGraceUntil = null;
    _activeOffer = null;
    _shownOfferId = null;
    NewOrderAlertHelper.stop();

    if (Get.isRegistered<OrderController>()) {
      final orderCtrl = Get.find<OrderController>();
      if (!orderCtrl.isNewOrderSheetOpen) {
        await orderCtrl.refreshCurrentOrdersOnly(promptAccept: false);
        if (scheduledDeliveryEnabled) {
          await orderCtrl.refreshScheduledCurrentOrdersOnly(promptAccept: false);
        }
      }
    }
  }

  void _presentNextOfferIfNeeded({required bool showSheet}) {
    if (_isOfferUiSuppressed || _isAccepting || _isRejecting) return;
    final offer = _nextOfferToPresent();
    if (offer == null) {
      if (_pendingOffers.isEmpty && _scheduledPendingOffers.isEmpty) {
        unawaited(_handleNoOffersRemaining());
      }
      return;
    }

    _activeOffer = offer;

    // Clear stale sheet flags so we can open again (bell-only bug).
    if (_offerSheetOpen && Get.isBottomSheetOpen != true) {
      _offerSheetOpen = false;
      _shownOfferId = null;
      _pendingPresentOfferId = null;
    }

    if (isOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      return;
    }

    final sheetVisible = _offerSheetOpen && Get.isBottomSheetOpen == true;
    if (sheetVisible && _shownOfferId == offer.offerId) {
      return;
    }

    if (sheetVisible && _shownOfferId != offer.offerId) {
      _closeOfferSheet(stopAlert: false);
    }
    if (_pendingPresentOfferId == offer.offerId && !sheetVisible) {
      _showOfferSheetNow(offer);
      return;
    }
    if (_pendingPresentOfferId == null || _pendingPresentOfferId != offer.offerId) {
      _presentOfferSheet(offer);
    }
  }

  AssignmentOfferModel? _nextOfferToPresent() {
    for (final offer in _pendingOffers) {
      final id = offer.offerId;
      if (id != null && _sheetSoftDismissedOfferIds.contains(id)) continue;
      if (isOfferAlreadyHandled(offerId: id, orderId: offer.orderId)) {
        continue;
      }
      return offer;
    }
    for (final offer in _scheduledPendingOffers) {
      final id = offer.offerId;
      if (id != null && _sheetSoftDismissedOfferIds.contains(id)) continue;
      if (isOfferAlreadyHandled(offerId: id, orderId: offer.orderId)) {
        continue;
      }
      return offer;
    }
    return null;
  }

  void onOfferPushReceived({
    int? offerId,
    int? orderId,
    Map<String, dynamic>? pushData,
  }) {
    unawaited(openOfferFromNotification(
      offerId: offerId,
      orderId: orderId,
      pushData: pushData,
    ));
  }

  /// Opens the offer sheet immediately from FCM, then enriches via API.
  Future<void> openOfferFromNotification({
    int? offerId,
    int? orderId,
    Map<String, dynamic>? pushData,
    bool requireLiveOnServer = false,
  }) async {
    await ensureInvalidOffersLoaded();

    // Clear stale reject/timeout flags first so a re-offer can open + Accept.
    if (offerId != null) {
      _timedOutOfferIds.remove(offerId);
      _sheetSoftDismissedOfferIds.remove(offerId);
      _dismissedOfferIds.remove(offerId);
      _rejectedOfferUntil.remove(offerId);
    }
    if (orderId != null) {
      _timedOutOrderIds.remove(orderId);
      _dismissedOrderIds.remove(orderId);
    }

    // Still block if this driver already accepted this order/offer.
    if (isOfferAlreadyHandled(offerId: offerId, orderId: orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }
    // Naya FCM offer = re-offer allow (reject/timeout ke baad bhi screen + bell).
    _suppressOfferUiUntil = null;
    await NewOrderAlertHelper.clearMute();
    if (_isAccepting || _isRejecting) {
      NewOrderAlertHelper.stop();
      return;
    }
    armOfferArrivalGrace();
    // Do not clear accepted/invalid for known-dead offers on resume.
    if (offerId != null &&
        !_invalidOfferIds.contains(offerId) &&
        pushData != null &&
        pushData.isNotEmpty) {
      _acceptedOfferIds.remove(offerId);
    }

    // App reopen / stale wake: only show if still in pending-offers.
    if (requireLiveOnServer ||
        pushData == null ||
        pushData.isEmpty) {
      await Future.wait([
        fetchPendingOffers(showSheet: false, forceRefresh: true),
        if (scheduledDeliveryEnabled)
          fetchScheduledPendingOffers(showSheet: false, forceRefresh: true),
      ]);
      final live = _findPendingOffer(offerId: offerId, orderId: orderId);
      if (live == null || live.offerId == null) {
        markOfferInvalid(offerId: offerId, orderId: orderId);
        NewOrderAlertHelper.stop();
        if (orderId != null && orderId > 0) {
        }
        return;
      }
      _upsertPendingOffer(live);
      _presentOrEnrichOffer(live);
      return;
    }

    final sameOfferOpen = offerId != null &&
        (_shownOfferId == offerId ||
            _activeOffer?.offerId == offerId ||
            _pendingPresentOfferId == offerId);
    if (!sameOfferOpen) {
      _resetOfferSheetStateIfNeeded();
    }

    final timeoutFromPush = int.tryParse(
          '${pushData['timeout_seconds'] ?? pushData['seconds_remaining'] ?? ''}',
        ) ??
        offerAcceptTimeoutSeconds;

    // Show popup FIRST from push (even lean payload). Ring only with sheet attempt.
    // Clear small system banner immediately so only the large sheet is tappable.
    unawaited(AppForegroundHelper.dismissOrderWakeHeadsUp());
    if (orderId != null && orderId > 0) {
    }

    final immediate = _resolveImmediateOffer(
      offerId: offerId,
      orderId: orderId,
      pushData: pushData,
      fallbackTimeout: timeoutFromPush,
    );
    if (immediate != null) {
      _upsertPendingOffer(immediate);
      _presentOrEnrichOffer(immediate);
    } else if (offerId != null && offerId > 0) {
      final lean = AssignmentOfferModel(
        offerId: offerId,
        orderId: orderId,
        secondsRemaining: timeoutFromPush,
      );
      _upsertPendingOffer(lean);
      _presentOrEnrichOffer(lean);
    } else {
      _armOfferSheetWatchdog(
        offerId: offerId,
        orderId: orderId,
        timeoutSeconds: timeoutFromPush,
      );
    }

    unawaited(_fetchAndPresentOffer(offerId: offerId, orderId: orderId));
  }

  AssignmentOfferModel? _resolveImmediateOffer({
    int? offerId,
    int? orderId,
    Map<String, dynamic>? pushData,
    int? fallbackTimeout,
  }) {
    final cached = _findPendingOffer(offerId: offerId, orderId: orderId);
    if (cached?.offerId != null) {
      return cached;
    }

    if (pushData != null && pushData.isNotEmpty) {
      final fromPush = AssignmentOfferModel.fromPushData(pushData);
      fromPush.offerId ??= offerId;
      fromPush.orderId ??= orderId;
      fromPush.secondsRemaining ??=
          fallbackTimeout ?? offerAcceptTimeoutSeconds;
      if (fromPush.offerId != null) {
        return fromPush;
      }
    }

    if (offerId != null && offerId > 0) {
      return AssignmentOfferModel(
        offerId: offerId,
        orderId: orderId,
        secondsRemaining: fallbackTimeout ?? offerAcceptTimeoutSeconds,
      );
    }
    return null;
  }

  void _upsertPendingOffer(AssignmentOfferModel offer) {
    final id = offer.offerId;
    if (id == null) return;
    if (isOfferAlreadyHandled(offerId: id, orderId: offer.orderId)) {
      return;
    }
    final list =
        offer.isScheduled ? _scheduledPendingOffers : _pendingOffers;
    final index = list.indexWhere((o) => o.offerId == id);
    if (index >= 0) {
      list[index].mergeFrom(offer);
    } else {
      if (offer.isScheduled) {
        _scheduledPendingOffers = [offer, ..._scheduledPendingOffers];
      } else {
        _pendingOffers = [offer, ..._pendingOffers];
      }
    }
    update();
  }

  void _presentOrEnrichOffer(AssignmentOfferModel resolved) {
    if (resolved.offerId == null) return;

    final alreadyShowing = _offerSheetOpen && _shownOfferId == resolved.offerId;
    final pendingSame = _pendingPresentOfferId == resolved.offerId;

    if (alreadyShowing || pendingSame) {
      final sheetOffer = _activeOffer;
      if (sheetOffer != null && sheetOffer.offerId == resolved.offerId) {
        sheetOffer.mergeFrom(resolved);
      } else {
        _activeOffer = resolved;
      }
      _upsertPendingOffer(resolved);
      update();
      return;
    }

    _presentOfferSheet(resolved);
  }

  void _resetOfferSheetStateIfNeeded() {
    if (!_offerSheetOpen && _pendingPresentOfferId == null) return;
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    _offerSheetOpen = false;
    _pendingPresentOfferId = null;
    _shownOfferId = null;
    _countdownTimer?.cancel();
  }

  AssignmentOfferModel? _findPendingOffer({int? offerId, int? orderId}) {
    for (final offer in [..._pendingOffers, ..._scheduledPendingOffers]) {
      if (offerId != null && offerId > 0 && offer.offerId == offerId) {
        return offer;
      }
      if (orderId != null && orderId > 0 && offer.orderId == orderId) {
        return offer;
      }
    }
    // Only fall back when no specific id was requested.
    if ((offerId == null || offerId <= 0) &&
        (orderId == null || orderId <= 0)) {
      return _nextOfferToPresent();
    }
    return null;
  }

  Future<void> _fetchAndPresentOffer({int? offerId, int? orderId}) async {
    var presented = false;

    Future<void> tryPresentFromCache() async {
      final found = _findPendingOffer(offerId: offerId, orderId: orderId);
      if (found?.offerId == null) return;
      if (isOfferAlreadyHandled(
        offerId: found!.offerId,
        orderId: found.orderId,
      )) {
        return;
      }
      presented = true;
      _presentOrEnrichOffer(found);
    }

    final normal = fetchPendingOffers(showSheet: false, forceRefresh: true)
        .then((_) => tryPresentFromCache());
    final scheduled = scheduledDeliveryEnabled
        ? fetchScheduledPendingOffers(showSheet: false, forceRefresh: true)
            .then((_) => tryPresentFromCache())
        : Future<void>.value();

    await Future.wait([normal, scheduled]);

    if (!presented) {
      await Future.delayed(const Duration(milliseconds: 150));
      await Future.wait([
        fetchPendingOffers(showSheet: false, forceRefresh: true),
        if (scheduledDeliveryEnabled)
          fetchScheduledPendingOffers(showSheet: false, forceRefresh: true),
      ]);
      var found = _findPendingOffer(offerId: offerId, orderId: orderId);
      if (found?.offerId == null &&
          (_shownOfferId == offerId || _activeOffer?.offerId == offerId)) {
        await Future.delayed(const Duration(seconds: 1));
        await Future.wait([
          fetchPendingOffers(showSheet: false, forceRefresh: true),
          if (scheduledDeliveryEnabled)
            fetchScheduledPendingOffers(showSheet: false, forceRefresh: true),
        ]);
        found = _findPendingOffer(offerId: offerId, orderId: orderId);
      }
      if (found?.offerId != null &&
          !isOfferAlreadyHandled(
            offerId: found!.offerId,
            orderId: found.orderId,
          )) {
        _presentOrEnrichOffer(found);
      } else {
        // API confirms offer is gone (taken / expired / rejected elsewhere).
        markOfferInvalid(offerId: offerId, orderId: orderId);
        if (orderId != null && orderId > 0) {
        }
      }
    }
  }

  void _startOfferAlert({
    required int? offerId,
    required int? orderId,
    required int alertSeconds,
    bool forceRestart = false,
    bool wakeApp = false,
  }) {
    if (isOfferAlreadyHandled(offerId: offerId, orderId: orderId)) {
      return;
    }
    if (_isRejecting || _isAccepting) return;

    void onTimeout() {
      final int? activeOfferId = offerId ?? _activeOffer?.offerId;
      final int? activeOrderId = orderId ?? _activeOffer?.orderId;
      if (activeOfferId == null) return;
      if (isOfferAlreadyHandled(offerId: activeOfferId, orderId: activeOrderId)) {
        return;
      }
      if (_isRejecting || _isAccepting) return;
      unawaited(
        NewOrderAlertHelper.start(
          loopUntilStopped: true,
          forceRestart: false,
          onTimeout: onTimeout,
        ),
      );
    }

    final seconds = alertSeconds.clamp(60, 14400);
    if (wakeApp) {
      unawaited(AppForegroundHelper.wakeScreen());
      unawaited(
        AppForegroundHelper.bringToForeground(
          orderId: orderId,
          offerId: offerId,
          type: 'delivery_assignment_offer',
        ),
      );
    }
    unawaited(
      NewOrderAlertHelper.isAlertLive().then((live) {
        if (isOfferAlreadyHandled(offerId: offerId, orderId: orderId)) {
          return;
        }
        if (_isRejecting || _isAccepting) return;
        NewOrderAlertHelper.start(
          maxSeconds: seconds,
          loopUntilStopped: true,
          // Keep ringing if already live; restart only when explicitly asked
          // and nothing is playing.
          forceRestart: forceRestart && !live && !NewOrderAlertHelper.isActive,
          onTimeout: onTimeout,
        );
      }),
    );
    _armOfferSheetWatchdog(
      offerId: offerId,
      orderId: orderId,
      timeoutSeconds: seconds,
    );
  }

  void _armOfferSheetWatchdog({
    int? offerId,
    int? orderId,
    int? timeoutSeconds,
  }) {
    _offerSheetWatchdog?.cancel();
    _offerSheetWatchdog = Timer(const Duration(milliseconds: 900), () {
      unawaited(_reconcileOfferSheetWithAlert(
        offerId: offerId,
        orderId: orderId,
        timeoutSeconds: timeoutSeconds,
      ));
    });
  }

  Future<void> _reconcileOfferSheetWithAlert({
    int? offerId,
    int? orderId,
    int? timeoutSeconds,
  }) async {
    if (isOfferAlreadyHandled(offerId: offerId, orderId: orderId)) {
      NewOrderAlertHelper.stop();
      return;
    }
    final sheetVisible =
        _offerSheetOpen && Get.isBottomSheetOpen == true;
    if (sheetVisible) return;

    final alertLive =
        NewOrderAlertHelper.isActive || await NewOrderAlertHelper.isAlertLive();
    if (!alertLive && _pendingPresentOfferId == null) return;

    // Stale sheet flag after unexpected dismiss.
    if (_offerSheetOpen && Get.isBottomSheetOpen != true) {
      _offerSheetOpen = false;
      _shownOfferId = null;
      _pendingPresentOfferId = null;
    }

    var offer = _findPendingOffer(offerId: offerId, orderId: orderId) ??
        _activeOffer;
    if (offer?.offerId == null && offerId != null && offerId > 0) {
      offer = AssignmentOfferModel(
        offerId: offerId,
        orderId: orderId,
        secondsRemaining: timeoutSeconds ?? offerAcceptTimeoutSeconds,
      );
    }
    if (offer?.offerId == null) {
      if (alertLive) {
        NewOrderAlertHelper.stop();
      }
      return;
    }
    if (_pendingPresentOfferId == offer!.offerId ||
        _activeOffer?.offerId == offer.offerId) {
      _showOfferSheetNow(offer);
      return;
    }
    _presentOfferSheet(offer);
  }

  void onOfferCancelledPush({
    int? offerId,
    int? orderId,
    bool showCancelledMessage = false,
    String? cancelReason,
    String? description,
  }) {
    final alreadyHandled = isOfferAlreadyHandled(
      offerId: offerId,
      orderId: offerId != null ? null : orderId,
    );
    final reason = (cancelReason ?? '').trim().toLowerCase();
    final takenByAnother =
        reason == 'accepted_by_another' || reason == 'taken';

    // Resolve relation BEFORE mutating lists (remove would break matching).
    final matchesActive = (offerId != null &&
            (_activeOffer?.offerId == offerId || _shownOfferId == offerId)) ||
        (orderId != null && _activeOffer?.orderId == orderId);
    final relatedTaken = takenByAnother &&
        (matchesActive ||
            (offerId != null &&
                (_shownOfferId == offerId ||
                    _pendingOffers.any((o) => o.offerId == offerId) ||
                    _scheduledPendingOffers.any((o) => o.offerId == offerId))) ||
            (orderId != null &&
                (_activeOffer?.orderId == orderId ||
                    _pendingOffers.any((o) => o.orderId == orderId) ||
                    _scheduledPendingOffers.any((o) => o.orderId == orderId))));
    final orphanSheet = _offerSheetOpen &&
        offerId == null &&
        orderId == null &&
        _activeOffer == null;

    // must ring). Offer-level invalidation is enough to stop the current sheet.
    _markOfferHandled(offerId: offerId, orderId: null);
    if (orderId != null) {
      _acceptedOfferOrderIds.remove(orderId);
      _timedOutOrderIds.remove(orderId);
      _dismissedOrderIds.remove(orderId);
    }
    NewOrderAlertHelper.muteFor(const Duration(seconds: 3));
    unawaited(NewOrderAlertHelper.stop());
    _bumpOfferUiGeneration();
    _pendingPresentOfferId = null;

    if (offerId != null) {
      _pendingOffers.removeWhere((o) => o.offerId == offerId);
      _scheduledPendingOffers.removeWhere((o) => o.offerId == offerId);
      _timedOutOfferIds.add(offerId);
      _serverConfirmedOfferIds.remove(offerId);
    }
    if (orderId != null) {
      _pendingOffers.removeWhere((o) => o.orderId == orderId);
      _scheduledPendingOffers.removeWhere((o) => o.orderId == orderId);
    }

    // Close only when this cancel is about the open/ringing offer.
    if (matchesActive || relatedTaken || orphanSheet) {
      _closeOfferSheet();
      _shownOfferId = null;
      _activeOffer = null;
    } else if (_pendingOffers.isEmpty &&
        _scheduledPendingOffers.isEmpty &&
        !_offerSheetOpen &&
        _pendingPresentOfferId == null) {
      _activeOffer = null;
      _shownOfferId = null;
    }

    if (showCancelledMessage && !alreadyHandled) {
      final desc = (description ?? '').trim();
      String label;
      if (reason == 'order_cancelled' ||
          reason == 'canceled' ||
          reason == 'cancelled') {
        label = orderId != null
            ? '${'canceled'.tr} — #$orderId'
            : 'canceled'.tr;
      } else if (reason == 'released') {
        label = orderId != null
            ? 'order_released_message'.trParams({'order': '$orderId'})
            : 'order_released_message_generic'.tr;
      } else if (reason == 'expired') {
        label = 'offer_expired_or_responded'.tr;
      } else if (reason == 'accepted_by_another' || reason == 'taken') {
        label = orderId != null
            ? 'order_accepted_by_another_dm'.trParams({'order': '$orderId'})
            : 'order_accepted_by_another_dm_generic'.tr;
      } else if (desc.isNotEmpty) {
        label = desc;
      } else {
        label = orderId != null
            ? 'order_accepted_by_another_dm'.trParams({'order': '$orderId'})
            : 'order_accepted_by_another_dm_generic'.tr;
      }
      showQuikseeSnackBarWidget(label, isError: true);
    }

    update();
    if (!alreadyHandled) {
      unawaited(refreshAllOffers(showSheet: false));
    }
  }

  void _presentOfferSheet(AssignmentOfferModel offer) {
    if (offer.offerId == null) return;
    if (_isAccepting || _isRejecting || _isOfferUiSuppressed) {
      NewOrderAlertHelper.stop();
      return;
    }
    if (_offerSheetOpen &&
        _shownOfferId == offer.offerId &&
        Get.isBottomSheetOpen == true) {
      return;
    }
    // Recover from stale open flag (sheet gone, bell still ringing).
    if (_offerSheetOpen && Get.isBottomSheetOpen != true) {
      _offerSheetOpen = false;
      _shownOfferId = null;
      _pendingPresentOfferId = null;
    }
    if (isOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      NewOrderAlertHelper.stop();
      return;
    }
    if (offer.offerId != null && _timedOutOfferIds.contains(offer.offerId)) {
      NewOrderAlertHelper.stop();
      return;
    }

    final timeout = offerAcceptTimeoutSeconds;
    final remaining = offer.secondsRemaining;
    final startSeconds = (remaining != null && remaining > 0)
        ? remaining.clamp(1, timeout)
        : timeout;
    armOfferArrivalGrace(seconds: startSeconds);
    _offerSheetOpenedAt = DateTime.now();
    _activeOffer = offer;
    _pendingPresentOfferId = offer.offerId;
    offer.secondsRemaining = startSeconds;
    _startCountdown(offer);
    // Fast pending-offers poll while this offer is live (detect accept-by-another).
    if (_pollTimer != null) {
      startPolling();
    }

    final int presentGen = _offerUiGeneration;
    _startOfferAlert(
      offerId: offer.offerId,
      orderId: offer.orderId,
      alertSeconds: startSeconds,
      forceRestart: !_offerSheetOpen,
      wakeApp: false,
    );

    void tryShow() {
      if (presentGen != _offerUiGeneration) return;
      if (_pendingPresentOfferId != offer.offerId &&
          _shownOfferId != offer.offerId) {
        return;
      }
      if (_offerSheetOpen && Get.isBottomSheetOpen == true) return;
      _showOfferSheetNow(offer, presentGen: presentGen);
    }

    Future.microtask(() {
      if (Get.context != null) {
        tryShow();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tryShow();
      });
    });

    // Second chance: agar pehli attempt miss ho to 500ms baad force sheet.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (presentGen != _offerUiGeneration) return;
      if (isOfferAlreadyHandled(
        offerId: offer.offerId,
        orderId: offer.orderId,
      )) {
        NewOrderAlertHelper.stop();
        return;
      }
      if (_timedOutOfferIds.contains(offer.offerId)) {
        NewOrderAlertHelper.stop();
        return;
      }
      if (offer.offerId != null &&
          _sheetSoftDismissedOfferIds.contains(offer.offerId!)) {
        return;
      }
      final sheetVisible =
          _offerSheetOpen && Get.isBottomSheetOpen == true;
      if (sheetVisible && _shownOfferId == offer.offerId) return;
      if (_isAccepting || _isRejecting || _isOfferUiSuppressed) {
        NewOrderAlertHelper.stop();
        return;
      }
      if (_offerSheetOpen && Get.isBottomSheetOpen != true) {
        _offerSheetOpen = false;
        _shownOfferId = null;
        _pendingPresentOfferId = null;
      }
      if (_pendingPresentOfferId == null) {
        _pendingPresentOfferId = offer.offerId;
      }
      _showOfferSheetNow(offer, presentGen: presentGen);
    });
  }

  void _showOfferSheetNow(
    AssignmentOfferModel offer, {
    int? presentGen,
  }) {
    if (presentGen != null && presentGen != _offerUiGeneration) return;
    if (_isAccepting || _isRejecting || _isOfferUiSuppressed) {
      _pendingPresentOfferId = null;
      NewOrderAlertHelper.stop();
      return;
    }
    if (offer.offerId != null &&
        _sheetSoftDismissedOfferIds.contains(offer.offerId!)) {
      _pendingPresentOfferId = null;
      return;
    }
    if (_pendingPresentOfferId != offer.offerId &&
        _shownOfferId != offer.offerId) {
      // Allow reopen when watchdog cleared pending id incorrectly.
      if (_pendingPresentOfferId == null &&
          !_offerSheetOpen &&
          offer.offerId != null) {
        _pendingPresentOfferId = offer.offerId;
      } else if (_pendingPresentOfferId != offer.offerId) {
        return;
      }
    }
    if (Get.context == null) {
      _scheduleOfferPresentationRetry(offer, presentGen: presentGen);
      return;
    }
    // Bump gen first so the closing sheet's whenComplete cannot reopen it.
    if (Get.isBottomSheetOpen == true || _offerSheetOpen) {
      _bumpOfferUiGeneration();
      _forceCloseAllOfferSheets();
    }
    if (_offerSheetOpen && Get.isBottomSheetOpen != true) {
      _offerSheetOpen = false;
      _shownOfferId = null;
    }
    if (isOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      _pendingPresentOfferId = null;
      NewOrderAlertHelper.stop();
      return;
    }
    if (offer.offerId != null && _timedOutOfferIds.contains(offer.offerId)) {
      _pendingPresentOfferId = null;
      NewOrderAlertHelper.stop();
      return;
    }

    final int sheetGen = _offerUiGeneration;
    _pendingPresentOfferId = null;
    _shownOfferId = offer.offerId;
    _offerSheetOpen = true;
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().closeNewOrderActionSheet(stopAlert: false);
    }
    unawaited(AppForegroundHelper.dismissOrderWakeHeadsUp());
    if (offer.orderId != null && offer.orderId! > 0) {
    }
    Get.bottomSheet(
      AssignmentOfferSheet(offer: offer),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
    ).whenComplete(() {
      if (sheetGen != _offerUiGeneration) {
        _offerSheetOpen = false;
        return;
      }
      final int? closedOfferId = offer.offerId;
      final int? closedOrderId = offer.orderId;
      if (_shownOfferId != null &&
          closedOfferId != null &&
          _shownOfferId != closedOfferId) {
        return;
      }
      if (_offerSheetOpen && Get.isBottomSheetOpen == true) {
        return;
      }
      _offerSheetOpen = false;
      if (isOfferAlreadyHandled(
        offerId: closedOfferId,
        orderId: closedOrderId,
      )) {
        _countdownTimer?.cancel();
        _offerSheetWatchdog?.cancel();
        NewOrderAlertHelper.stop();
        return;
      }
      if (_isAccepting || _isRejecting || _isOfferUiSuppressed) {
        _countdownTimer?.cancel();
        _offerSheetWatchdog?.cancel();
        return;
      }
      if (closedOfferId != null &&
          _sheetSoftDismissedOfferIds.contains(closedOfferId)) {
        _countdownTimer?.cancel();
        _offerSheetWatchdog?.cancel();
        NewOrderAlertHelper.stop();
        _shownOfferId = null;
        return;
      }
      if (closedOfferId != null &&
          (_timedOutOfferIds.contains(closedOfferId) ||
              (closedOrderId != null &&
                  _timedOutOrderIds.contains(closedOrderId)))) {
        _countdownTimer?.cancel();
        NewOrderAlertHelper.stop();
        return;
      }
      if (closedOfferId != null &&
          (NewOrderAlertHelper.isActive ||
              _activeOffer?.offerId == closedOfferId)) {
        _scheduleOfferPresentationRetry(offer, presentGen: sheetGen);
        return;
      }
      _countdownTimer?.cancel();
      _shownOfferId = null;
      NewOrderAlertHelper.stop();
    });
  }

  void _scheduleOfferPresentationRetry(
    AssignmentOfferModel offer, {
    int? presentGen,
  }) {
    final orderId = offer.orderId;
    final offerId = offer.offerId;
    if ((orderId == null || orderId <= 0) &&
        (offerId == null || offerId <= 0)) {
      return;
    }
    final int retryGen = presentGen ?? _offerUiGeneration;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (retryGen != _offerUiGeneration) return;
      if (isOfferAlreadyHandled(
        offerId: offerId,
        orderId: orderId,
      )) {
        return;
      }
      if (_isAccepting || _isRejecting || _isOfferUiSuppressed) return;
      if (offerId != null && _sheetSoftDismissedOfferIds.contains(offerId)) {
        return;
      }
      if (_offerSheetOpen && Get.isBottomSheetOpen == true) return;
      if (offerId != null && _timedOutOfferIds.contains(offerId)) return;
      if (_offerSheetOpen && Get.isBottomSheetOpen != true) {
        _offerSheetOpen = false;
        _shownOfferId = null;
        _pendingPresentOfferId = null;
      }
      if (orderId != null && orderId > 0) {
        unawaited(ensureOfferPresentedForOrder(orderId));
      } else if (offer.offerId != null) {
        _presentOfferSheet(offer);
      }
    });
  }

  Future<void> _handleOfferAcceptanceTimeout(int offerId, int? orderId) async {
    if (_handlingTimeoutOfferIds.contains(offerId)) return;
    if (_isAccepting || _isRejecting) return;
    if (isOfferAlreadyHandled(offerId: offerId, orderId: orderId)) {
      await NewOrderAlertHelper.stop();
      return;
    }

    _handlingTimeoutOfferIds.add(offerId);
    try {
      final stillShowing = _activeOffer?.offerId == offerId ||
          _shownOfferId == offerId ||
          _pendingOffers.any((o) => o.offerId == offerId) ||
          _scheduledPendingOffers.any((o) => o.offerId == offerId);
      if (!stillShowing) {
        NewOrderAlertHelper.muteFor(const Duration(seconds: 15));
        await NewOrderAlertHelper.stop();
        _sheetSoftDismissedOfferIds.add(offerId);
        _bumpOfferUiGeneration();
        _forceCloseAllOfferSheets();
        return;
      }

      AssignmentOfferModel? live = _activeOffer;
      if (live?.offerId != offerId) {
        live = _findPendingOffer(offerId: offerId);
      }
      if (live != null) {
        live.secondsRemaining = offerAcceptTimeoutSeconds;
        if (_activeOffer?.offerId == offerId) {
          _activeOffer = live;
        }
        _startCountdown(live);
      }
      _startOfferAlert(
        offerId: offerId,
        orderId: orderId,
        alertSeconds: offerAcceptTimeoutSeconds,
        forceRestart: false,
        wakeApp: false,
      );
    } finally {
      _handlingTimeoutOfferIds.remove(offerId);
      update();
    }
  }

  void _startCountdown(AssignmentOfferModel offer) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (offer.secondsRemaining != null && offer.secondsRemaining! > 0) {
        offer.secondsRemaining = offer.secondsRemaining! - 1;
        update();
      } else {
        timer.cancel();
        final int? offerId = offer.offerId;
        final int? orderId = offer.orderId;
        if (offerId != null) {
          unawaited(_handleOfferAcceptanceTimeout(offerId, orderId));
        }
      }
    });
  }

  void _closeOfferSheet({bool stopAlert = true}) {
    _offerSheetWatchdog?.cancel();
    _offerSheetOpenedAt = null;
    if (stopAlert) {
      NewOrderAlertHelper.stop();
    }
    _forceCloseAllOfferSheets();
  }

  Future<void> onOfferAlertTimedOut({int? offerId, int? orderId}) async {
    final resolvedOfferId = offerId ?? _activeOffer?.offerId;
    if (resolvedOfferId == null) return;
    await _handleOfferAcceptanceTimeout(
      resolvedOfferId,
      orderId ?? _activeOffer?.orderId,
    );
  }

  Future<bool> acceptOffer(int offerId) async {
    if (_isAccepting) return false;

    final matchedOffer = _findPendingOffer(offerId: offerId);
    final bool wasScheduled = matchedOffer?.isScheduled == true ||
        _scheduledPendingOffers.any((o) => o.offerId == offerId);
    final int? orderId = _activeOffer?.orderId ??
        matchedOffer?.orderId ??
        _pendingOffers
            .where((o) => o.offerId == offerId)
            .map((o) => o.orderId)
            .cast<int?>()
            .firstOrNull ??
        _scheduledPendingOffers
            .where((o) => o.offerId == offerId)
            .map((o) => o.orderId)
            .cast<int?>()
            .firstOrNull;

    _countdownTimer?.cancel();
    _offerSheetWatchdog?.cancel();
    _isAccepting = true;
    // Optimistic lock so stale wake / FCM cannot reopen while accept is in flight.
    _markOfferHandled(offerId: offerId, orderId: orderId);
    _suppressOfferUi(seconds: 60);
    // Kill any stacked / delayed popups from other concurrent offers.
    _forceCloseAllOfferSheets();
    await NewOrderAlertHelper.muteFor(const Duration(seconds: 90));
    await NewOrderAlertHelper.stop();
    update();

    try {
      final response = await assignmentRepository.acceptOffer(offerId);
      await NewOrderAlertHelper.muteFor(const Duration(seconds: 90));
      await NewOrderAlertHelper.stop();

      if (response.statusCode == 200 &&
          response.body != null &&
          (response.body['success'] == true || response.body['success'] == 1)) {
        final acceptedOrderId = int.tryParse('${response.body['order_id']}');
        _markOfferHandled(
          offerId: offerId,
          orderId: acceptedOrderId ?? orderId,
        );
        if (acceptedOrderId != null &&
            orderId != null &&
            acceptedOrderId != orderId) {
          _markOfferHandled(offerId: offerId, orderId: orderId);
        }
        _suppressOfferUi(seconds: 60);
        _pendingOffers.removeWhere((o) => o.offerId == offerId);
        _scheduledPendingOffers.removeWhere((o) => o.offerId == offerId);
        if (acceptedOrderId != null) {
          _pendingOffers.removeWhere((o) => o.orderId == acceptedOrderId);
          _scheduledPendingOffers
              .removeWhere((o) => o.orderId == acceptedOrderId);
        }
        if (orderId != null) {
          _pendingOffers.removeWhere((o) => o.orderId == orderId);
          _scheduledPendingOffers.removeWhere((o) => o.orderId == orderId);
        }
        // Remaining offers → Notifications only (no auto popup after accept).
        for (final o in [..._pendingOffers, ..._scheduledPendingOffers]) {
          final id = o.offerId;
          if (id != null) _sheetSoftDismissedOfferIds.add(id);
        }
        markDriverBusy(true);
        _activeOffer = null;
        _shownOfferId = null;
        _handlingTimeoutOfferIds.remove(offerId);
        await NewOrderAlertHelper.muteFor(const Duration(seconds: 90));
        await NewOrderAlertHelper.stop();
        _forceCloseAllOfferSheets();
        if (acceptedOrderId != null && Get.isRegistered<OrderController>()) {
          final orderCtrl = Get.find<OrderController>();
          final orderJson = response.body['order'];
          final confirmed = await orderCtrl.finalizeOfferAccept(
            orderId: acceptedOrderId,
            orderJson: orderJson is Map
                ? Map<String, dynamic>.from(orderJson)
                : null,
            forceScheduled: wasScheduled,
          );
          if (!confirmed) {
            showQuikseeSnackBarWidget(
              'order_accepted_confirm_failed'.tr,
              isError: true,
            );
          }
        }
        if (Get.isRegistered<OrderController>()) {
          final orderCtrl = Get.find<OrderController>();
          if (wasScheduled) {
            orderCtrl.setHomeDeliveryTabIndex(1);
          }
          unawaited(orderCtrl.getCurrentOrders(promptAccept: false));
        }
        unawaited(refreshAllOffers(showSheet: false));
        unawaited(
          Get.find<ProfileController>().getProfile(
            silent: true,
            skipSideEffects: true,
          ),
        );
        update();
        return true;
      }

      _acceptedOfferIds.remove(offerId);
      if (orderId != null) {
        _acceptedOfferOrderIds.remove(orderId);
      }
      _suppressOfferUiUntil = null;
      await NewOrderAlertHelper.clearMute();

      final errorCode = response.body?['error_code']?.toString();
      if (errorCode == 'order_cancelled') {
        _markOfferHandled(offerId: offerId, orderId: orderId);
        _suppressOfferUi(seconds: 30);
        _pendingOffers.removeWhere((o) => o.offerId == offerId);
        _scheduledPendingOffers.removeWhere((o) => o.offerId == offerId);
        _closeOfferSheet();
        showQuikseeSnackBarWidget(
          orderId != null ? '${'canceled'.tr} — #$orderId' : 'canceled'.tr,
          isError: true,
        );
        await refreshAllOffers(showSheet: false);
        update();
        return false;
      }

      if (errorCode == 'accepted_by_another') {
        markOfferInvalid(offerId: offerId, orderId: null);
        if (orderId != null) {
          _acceptedOfferOrderIds.remove(orderId);
          _timedOutOrderIds.remove(orderId);
          _dismissedOrderIds.remove(orderId);
        }
        _suppressOfferUi(seconds: 5);
        _pendingOffers.removeWhere((o) => o.offerId == offerId);
        _scheduledPendingOffers.removeWhere((o) => o.offerId == offerId);
        _closeOfferSheet();
        showQuikseeSnackBarWidget(
          orderId != null
              ? 'order_accepted_by_another_dm'.trParams({'order': '$orderId'})
              : 'order_accepted_by_another_dm_generic'.tr,
          isError: true,
        );
        await refreshAllOffers(showSheet: true);
        update();
        return false;
      }

      final message = response.body?['message']?.toString().toLowerCase() ?? '';
      final takenByAnother = message.contains('already assigned') ||
          message.contains('accepted by another');
      final offerExpired = response.statusCode == 403 ||
          message.contains('expired') ||
          message.contains('already responded');
      if (takenByAnother || offerExpired) {
        markOfferInvalid(offerId: offerId, orderId: null);
        if (orderId != null) {
          _acceptedOfferOrderIds.remove(orderId);
          _timedOutOrderIds.remove(orderId);
          _dismissedOrderIds.remove(orderId);
        }
        _suppressOfferUi(seconds: 3);
        _pendingOffers.removeWhere((o) => o.offerId == offerId);
        _scheduledPendingOffers.removeWhere((o) => o.offerId == offerId);
        _activeOffer = null;
        _shownOfferId = null;
        _closeOfferSheet();
        showQuikseeSnackBarWidget(
          takenByAnother
              ? (orderId != null
                  ? 'order_accepted_by_another_dm'
                      .trParams({'order': '$orderId'})
                  : 'order_accepted_by_another_dm_generic'.tr)
              : 'offer_expired_or_responded'.tr,
          isError: true,
        );
        await refreshAllOffers(showSheet: true);
        update();
        return false;
      }

      ApiChecker.checkApi(response);
      update();
      return false;
    } catch (_) {
      _acceptedOfferIds.remove(offerId);
      if (orderId != null) {
        _acceptedOfferOrderIds.remove(orderId);
      }
      _suppressOfferUiUntil = null;
      await NewOrderAlertHelper.clearMute();
      showQuikseeSnackBarWidget('Accept failed. Please try again.', isError: true);
      return false;
    } finally {
      _isAccepting = false;
      update();
    }
  }

  Future<bool> rejectOffer(
    int offerId, {
    String? reason,
    bool showNextOffer = true,
  }) async {
    if (_isRejecting && _rejectingOfferId == offerId) return false;
    if (_isRejectCooldownActive(offerId)) {
      _closeOfferSheet();
      return true;
    }

    final int? orderId = _activeOffer?.orderId ??
        _pendingOffers
            .where((o) => o.offerId == offerId)
            .map((o) => o.orderId)
            .cast<int?>()
            .firstOrNull ??
        _scheduledPendingOffers
            .where((o) => o.offerId == offerId)
            .map((o) => o.orderId)
            .cast<int?>()
            .firstOrNull;

    _rejectingOfferId = offerId;
    _markOfferDismissed(offerId: offerId, orderId: orderId);
    // Deny must not ring again until admin manual assign (new offer id).
    _suppressOfferUi(seconds: 120);
    NewOrderAlertHelper.muteFor(const Duration(seconds: 20));
    await NewOrderAlertHelper.stop();
    _countdownTimer?.cancel();
    _offerSheetWatchdog?.cancel();
    _pendingOffers.removeWhere((o) => o.offerId == offerId);
    _scheduledPendingOffers.removeWhere((o) => o.offerId == offerId);
    if (orderId != null) {
      _pendingOffers.removeWhere((o) => o.orderId == orderId);
      _scheduledPendingOffers.removeWhere((o) => o.orderId == orderId);
    }
    _activeOffer = null;
    _shownOfferId = null;
    _isRejecting = true;
    _closeOfferSheet();
    update();

    final response = await assignmentRepository.rejectOffer(
      offerId,
      reason: reason ?? 'driver_rejected',
    );
    _isRejecting = false;
    _rejectingOfferId = null;

    final body = response.body;
    final bool success = response.statusCode == 200 &&
        body != null &&
        (body['success'] == true || body['success'] == 1);

    if (success) {
      await NewOrderAlertHelper.stop();
      showQuikseeSnackBarWidget(
        body['message']?.toString() ?? 'offer_rejected'.tr,
        isError: false,
      );
      markDriverBusy(false);
      unawaited(refreshAllOffers(showSheet: false));
      update();
      return true;
    }

    _dismissedOfferIds.remove(offerId);
    _rejectedOfferUntil.remove(offerId);
    if (orderId != null) {
      _dismissedOrderIds.remove(orderId);
      _timedOutOrderIds.remove(orderId);
    }
    _timedOutOfferIds.remove(offerId);
    ApiChecker.checkApi(response);
    update();
    return false;
  }

  /// After deny, poll again so automatic re-assign shows without admin panel click.
  void _scheduleReOfferCatchupPolls() {
    final token = ++_reOfferPollToken;
    for (final seconds in <int>[6, 14, 25]) {
      Future.delayed(Duration(seconds: seconds), () async {
        if (token != _reOfferPollToken) return;
        if (isClosed) return;
        if (_isAccepting || _isRejecting) return;
        if (_driverBusy) return;
        if (_offerSheetOpen && Get.isBottomSheetOpen == true) return;
        _suppressOfferUiUntil = null;
        await NewOrderAlertHelper.clearMute();
        await refreshAllOffers(showSheet: true);
      });
    }
  }
}
