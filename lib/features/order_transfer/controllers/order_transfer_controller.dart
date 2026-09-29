import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_transfer/domain/models/transfer_candidate_model.dart';
import 'package:quiksee/features/order_transfer/domain/models/transfer_offer_model.dart';
import 'package:quiksee/features/order_transfer/domain/repositories/order_transfer_repository.dart';
import 'package:quiksee/features/order_transfer/widgets/transfer_offer_sheet.dart';
import 'package:quiksee/features/order_transfer/widgets/transfer_waiting_sheet.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/helper/new_order_alert_helper.dart';

class OrderTransferController extends GetxController {
  final OrderTransferRepository repository;

  OrderTransferController({required this.repository});

  List<TransferCandidateModel> _candidates = [];
  List<TransferCandidateModel> get candidates => _candidates;

  bool _loadingCandidates = false;
  bool get loadingCandidates => _loadingCandidates;

  bool _requesting = false;
  bool get requesting => _requesting;

  bool _responding = false;
  bool get responding => _responding;

  bool _cancelling = false;
  bool get cancelling => _cancelling;

  TransferOfferModel? _activeIncomingOffer;
  TransferOfferModel? get activeIncomingOffer => _activeIncomingOffer;
  bool get hasActiveIncomingOffer =>
      _activeIncomingOffer != null || _incomingSheetOpen;

  TransferOfferModel? _pendingOutgoingOffer;
  TransferOfferModel? get pendingOutgoingOffer => _pendingOutgoingOffer;

  int? _outgoingOrderId;
  int? get outgoingOrderId => _outgoingOrderId;

  Timer? _outgoingPollTimer;
  Timer? _incomingTickTimer;
  Timer? _incomingStatusPollTimer;
  Timer? _incomingSheetWatchdog;
  Timer? _incomingPresentRetryTimer;
  bool _incomingSheetOpen = false;
  int? _shownIncomingOfferId;
  int? _pendingPresentOfferId;
  int _incomingUiGeneration = 0;
  bool _outgoingTerminalNotified = false;
  bool _outgoingPollInFlight = false;
  bool _incomingStatusPollInFlight = false;
  DateTime? _outgoingExpiresAt;
  final Set<int> _handledIncomingOfferIds = <int>{};
  final Set<int> _handledIncomingOrderIds = <int>{};
  final Set<int> _locallyDoneTransferOrderIds = <int>{};
  Timer? _incomingWatchTimer;

  int get offerTimeoutSeconds {
    if (Get.isRegistered<AssignmentController>()) {
      return Get.find<AssignmentController>()
              .settings
              ?.orderTransferTimeoutSeconds ??
          40;
    }
    return 40;
  }

  bool isIncomingOfferAlreadyHandled({int? offerId, int? orderId}) {
    if (offerId != null &&
        offerId > 0 &&
        _handledIncomingOfferIds.contains(offerId)) {
      return true;
    }
    if (orderId != null &&
        orderId > 0 &&
        _handledIncomingOrderIds.contains(orderId)) {
      return true;
    }
    return false;
  }

  /// True when this offer is already ringing / sheet open (or about to).
  bool isIncomingOfferLive({int? offerId}) {
    if (offerId == null || offerId <= 0) return false;
    if (_pendingPresentOfferId == offerId) return true;
    if (_shownIncomingOfferId == offerId &&
        (_incomingSheetOpen || Get.isBottomSheetOpen == true)) {
      return true;
    }
    if (_activeIncomingOffer?.offerId == offerId &&
        (NewOrderAlertHelper.isActive ||
            _incomingSheetOpen ||
            _pendingPresentOfferId == offerId)) {
      return true;
    }
    return false;
  }

  /// Mark this offer closed so poll/FCM cannot ring it again.
  /// Pass [blockOrder] only after successful accept. Deny/timeout must NOT
  /// (new offer_id), and that new offer must still be shown.
  void _markIncomingHandled({
    int? offerId,
    int? orderId,
    bool blockOrder = false,
  }) {
    if (offerId != null && offerId > 0) {
      _handledIncomingOfferIds.add(offerId);
    }
    if (blockOrder && orderId != null && orderId > 0) {
      _handledIncomingOrderIds.add(orderId);
    }
  }

  Future<void> _closeOfferOnServer(int offerId, String action) async {
    try {
      await repository.respond(offerId: offerId, action: action);
    } catch (_) {}
  }

  bool isOrderTransferDoneLocally(int? orderId) {
    if (orderId == null || orderId <= 0) return false;
    return _locallyDoneTransferOrderIds.contains(orderId);
  }

  /// Hide Transfer button immediately after NEW rider accepts (before list API).
  void markOrderTransferAcceptedLocally(int? orderId) {
    if (orderId == null || orderId <= 0) return;
    _locallyDoneTransferOrderIds.add(orderId);
    if (_pendingOutgoingOffer?.orderId == orderId) {
      _pendingOutgoingOffer = null;
      _outgoingOrderId = null;
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().markOrderTransferDone(orderId);
    }
    if (Get.isRegistered<OrderDetailsController>()) {
      final details = Get.find<OrderDetailsController>();
      final lines = details.orderDetails;
      if (lines != null) {
        for (final line in lines) {
          final o = line.orderModel;
          if (o?.id == orderId) {
            o!.orderTransferAlreadyDone = 1;
            o.orderTransferLocked = 1;
          }
        }
        details.update();
      }
    }
    update();
  }

  /// Fast poll safety net for old phones that miss / delay FCM.
  void startIncomingOfferWatch() {
    _incomingWatchTimer?.cancel();
    _incomingWatchTimer =
        Timer.periodic(const Duration(seconds: 4), (_) {
      if (hasActiveIncomingOffer) {
        unawaited(pollPendingIncoming(presentIfFound: false));
        return;
      }
      unawaited(pollPendingIncoming(presentIfFound: true));
    });
    unawaited(pollPendingIncoming(presentIfFound: true));
  }

  void stopIncomingOfferWatch() {
    _incomingWatchTimer?.cancel();
    _incomingWatchTimer = null;
  }

  void resetSessionForLogout() {
    stopIncomingOfferWatch();
    _stopOutgoingPoll();
    _incomingTickTimer?.cancel();
    _incomingTickTimer = null;
    _stopIncomingStatusPoll();
    _incomingSheetWatchdog?.cancel();
    _incomingSheetWatchdog = null;
    _incomingPresentRetryTimer?.cancel();
    _incomingPresentRetryTimer = null;

    _candidates = [];
    _loadingCandidates = false;
    _requesting = false;
    _responding = false;
    _cancelling = false;
    _activeIncomingOffer = null;
    _pendingOutgoingOffer = null;
    _outgoingOrderId = null;
    _outgoingExpiresAt = null;
    _incomingSheetOpen = false;
    _shownIncomingOfferId = null;
    _pendingPresentOfferId = null;
    _incomingUiGeneration++;
    _outgoingTerminalNotified = false;
    _outgoingPollInFlight = false;
    _incomingStatusPollInFlight = false;
    _handledIncomingOfferIds.clear();
    _handledIncomingOrderIds.clear();
    _locallyDoneTransferOrderIds.clear();
    _recentOutgoing = [];

    try {
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
    } catch (_) {}
    unawaited(NewOrderAlertHelper.stop());
    update();
  }

  Future<bool> loadCandidates(int orderId) async {
    _loadingCandidates = true;
    _candidates = [];
    update();
    try {
      final response = await repository.getCandidates(orderId);
      if (response.statusCode == 200 && response.body is Map) {
        final body = response.body as Map;
        final list = body['candidates'];
        if (list is List) {
          _candidates = list
              .whereType<Map>()
              .map((e) => TransferCandidateModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .where((c) => c.id > 0)
              .toList();
        }
        _loadingCandidates = false;
        update();
        if (body['success'] == false) {
          showQuikseeSnackBarWidget(
            body['message']?.toString() ?? 'transfer_failed'.tr,
          );
          return false;
        }
        return true;
      }
      final msg = response.body is Map
          ? (response.body as Map)['message']?.toString()
          : null;
      showQuikseeSnackBarWidget(msg ?? 'transfer_failed'.tr);
      return false;
    } catch (_) {
      showQuikseeSnackBarWidget('transfer_failed'.tr);
      return false;
    } finally {
      _loadingCandidates = false;
      update();
    }
  }

  Future<bool> requestTransfer({
    required int orderId,
    required int toDeliveryManId,
    String? reason,
  }) async {
    if (_requesting) return false;
    _requesting = true;
    update();
    try {
      final response = await repository.requestTransfer(
        orderId: orderId,
        toDeliveryManId: toDeliveryManId,
        reason: reason,
      );
      if (response.statusCode == 200 && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        if (body['success'] == true) {
          _outgoingOrderId = orderId;
          _pendingOutgoingOffer = TransferOfferModel.fromJson(body);
          _pendingOutgoingOffer!.orderId ??= orderId;
          _pendingOutgoingOffer!.expiresIn ??= offerTimeoutSeconds;
          _outgoingTerminalNotified = false;
          update();
          return true;
        }
        showQuikseeSnackBarWidget(
          body['message']?.toString() ?? 'transfer_failed'.tr,
        );
        return false;
      }
      final msg = response.body is Map
          ? (response.body as Map)['message']?.toString()
          : null;
      showQuikseeSnackBarWidget(msg ?? 'transfer_failed'.tr);
      return false;
    } catch (_) {
      showQuikseeSnackBarWidget('transfer_failed'.tr);
      return false;
    } finally {
      _requesting = false;
      update();
    }
  }

  void startOutgoingWaitUi({
    required VoidCallback onAccepted,
    required VoidCallback onRejectedOrExpired,
  }) {
    _outgoingPollTimer?.cancel();
    final offer = _pendingOutgoingOffer;
    if (offer?.offerId == null) return;

    _outgoingTerminalNotified = false;
    final timeoutSec = offer!.expiresIn ?? offerTimeoutSeconds;
    _outgoingExpiresAt =
        DateTime.now().add(Duration(seconds: timeoutSec < 1 ? 1 : timeoutSec));

    Get.bottomSheet(
      TransferWaitingSheet(
        offer: offer,
        onCancel: () async {
          final ok = await cancelOutgoing();
          if (ok) {
            if (Get.isBottomSheetOpen == true) Get.back();
            onRejectedOrExpired();
          }
        },
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
    );

    _outgoingPollTimer =
        Timer.periodic(const Duration(seconds: 2), (_) async {
      final id = _pendingOutgoingOffer?.offerId;
      if (id == null || _outgoingPollInFlight) return;

      // Local deadline: confirm with server. Never fake-expire while the
      // like an auto-retry.
      final deadline = _outgoingExpiresAt;
      if (deadline != null && DateTime.now().isAfter(deadline)) {
        _outgoingPollInFlight = true;
        try {
          final response = await repository.getStatus(id);
          if (response.statusCode == 200 && response.body is Map) {
            final body = Map<String, dynamic>.from(response.body as Map);
            final status = (body['status'] ?? '').toString().toLowerCase();
            final expiresIn = int.tryParse('${body['expires_in'] ?? ''}') ?? 0;
            if (status == 'pending' && expiresIn > 0) {
              _pendingOutgoingOffer?.expiresIn = expiresIn;
              _outgoingExpiresAt = DateTime.now()
                  .add(Duration(seconds: expiresIn));
              update();
              return;
            }
            if (status == 'accepted') {
              _stopOutgoingPoll();
              if (Get.isBottomSheetOpen == true) Get.back();
              _notifyOutgoingTerminal('transfer_accepted_toast'.tr,
                  isError: false);
              markOrderTransferAcceptedLocally(
                _pendingOutgoingOffer?.orderId ?? _outgoingOrderId,
              );
              onAccepted();
              _clearOutgoing();
              return;
            }
            if (status == 'rejected' ||
                status == 'expired' ||
                status == 'cancelled' ||
                (status == 'pending' && expiresIn <= 0)) {
              _stopOutgoingPoll();
              if (Get.isBottomSheetOpen == true) Get.back();
              _notifyOutgoingTerminal(
                status == 'rejected'
                    ? 'transfer_rejected_toast'.tr
                    : (status == 'cancelled'
                        ? 'transfer_cancelled_toast'.tr
                        : 'transfer_expired_toast'.tr),
              );
              onRejectedOrExpired();
              _clearOutgoing();
              update();
              return;
            }
          }
        } catch (_) {
        } finally {
          _outgoingPollInFlight = false;
        }
        return;
      }

      _outgoingPollInFlight = true;
      try {
        final response = await repository.getStatus(id);
        if (response.statusCode != 200 || response.body is! Map) return;
        final body = Map<String, dynamic>.from(response.body as Map);
        final status = (body['status'] ?? '').toString().toLowerCase();
        final expiresIn = int.tryParse('${body['expires_in'] ?? ''}');
        if (expiresIn != null) {
          _pendingOutgoingOffer?.expiresIn = expiresIn;
          _outgoingExpiresAt =
              DateTime.now().add(Duration(seconds: expiresIn < 0 ? 0 : expiresIn));
          update();
        }
        if (status == 'accepted') {
          _stopOutgoingPoll();
          if (Get.isBottomSheetOpen == true) Get.back();
          _notifyOutgoingTerminal('transfer_accepted_toast'.tr, isError: false);
          markOrderTransferAcceptedLocally(
            _pendingOutgoingOffer?.orderId ?? _outgoingOrderId,
          );
          onAccepted();
          _clearOutgoing();
        } else if (status == 'rejected' ||
            status == 'expired' ||
            status == 'cancelled') {
          _stopOutgoingPoll();
          if (Get.isBottomSheetOpen == true) Get.back();
          _notifyOutgoingTerminal(
            status == 'rejected'
                ? 'transfer_rejected_toast'.tr
                : (status == 'expired'
                    ? 'transfer_expired_toast'.tr
                    : 'transfer_cancelled_toast'.tr),
          );
          onRejectedOrExpired();
          _clearOutgoing();
          update();
        }
      } catch (_) {
      } finally {
        _outgoingPollInFlight = false;
      }
    });
  }

  void _notifyOutgoingTerminal(String message, {bool isError = true}) {
    if (_outgoingTerminalNotified) return;
    _outgoingTerminalNotified = true;
    showQuikseeSnackBarWidget(message, isError: isError);
  }

  Future<bool> cancelOutgoing() async {
    final id = _pendingOutgoingOffer?.offerId;
    if (id == null) return true;
    if (_cancelling) return false;
    _cancelling = true;
    update();
    try {
      final response = await repository.cancel(id);
      if (response.statusCode == 200 &&
          response.body is Map &&
          (response.body as Map)['success'] == true) {
        _stopOutgoingPoll();
        _clearOutgoing();
        showQuikseeSnackBarWidget('transfer_cancelled_toast'.tr, isError: false);
        return true;
      }
      final msg = response.body is Map
          ? (response.body as Map)['message']?.toString()
          : null;
      showQuikseeSnackBarWidget(msg ?? 'transfer_failed'.tr);
      return false;
    } catch (_) {
      showQuikseeSnackBarWidget('transfer_failed'.tr);
      return false;
    } finally {
      _cancelling = false;
      update();
    }
  }

  void _stopOutgoingPoll() {
    _outgoingPollTimer?.cancel();
    _outgoingPollTimer = null;
  }

  void _clearOutgoing() {
    _pendingOutgoingOffer = null;
    _outgoingOrderId = null;
    _outgoingExpiresAt = null;
    update();
  }

  Future<void> openIncomingFromNotification({
    int? offerId,
    int? orderId,
    Map<String, dynamic>? pushData,
    bool requireLiveOnServer = true,
  }) async {
    TransferOfferModel offer;
    if (pushData != null) {
      offer = TransferOfferModel.fromJson(pushData);
      if ((offer.offerId == null || offer.offerId! <= 0) &&
          (int.tryParse('${pushData['offer_id'] ?? ''}') ?? 0) <= 0) {
        offer = TransferOfferModel.fromPushData(pushData);
      }
    } else {
      offer = TransferOfferModel(offerId: offerId, orderId: orderId);
    }
    if ((offer.offerId == null || offer.offerId! <= 0) && offerId != null) {
      offer.offerId = offerId;
    }
    if ((offer.orderId == null || offer.orderId! <= 0) && orderId != null) {
      offer.orderId = orderId;
    }
    if (offer.offerId == null || offer.offerId! <= 0) return;

    if (isIncomingOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      await _stopIncomingAlert(orderId: offer.orderId, offerId: offer.offerId);
      return;
    }

    if (isIncomingOfferLive(offerId: offer.offerId)) {
      _activeIncomingOffer ??= offer;
      if ((offer.expiresIn ?? 0) > 0) {
        _activeIncomingOffer!.expiresIn = offer.expiresIn;
      }
      update();
      _startIncomingAlert(_activeIncomingOffer ?? offer, fresh: false);
      return;
    }

    // Deny / timeout / stale FCM must not ring again. Only a still-pending
    // server offer (or a brand-new offer_id from a manual Transfer) may show.
    if (requireLiveOnServer) {
      try {
        final response = await repository.getStatus(offer.offerId!);
        if (response.statusCode != 200 || response.body is! Map) {
          return;
        }
        final body = Map<String, dynamic>.from(response.body as Map);
        final status = (body['status'] ?? '').toString().toLowerCase();
        if (status.isNotEmpty && status != 'pending') {
          _markIncomingHandled(offerId: offer.offerId, orderId: null);
          await _stopIncomingAlert(
            orderId: offer.orderId ?? int.tryParse('${body['order_id'] ?? ''}'),
            offerId: offer.offerId,
          );
          return;
        }
        final refreshed = TransferOfferModel.fromJson(body);
        refreshed.storeName ??= offer.storeName;
        refreshed.fromRiderName ??= offer.fromRiderName;
        if (refreshed.tipAmount < offer.tipAmount) {
          refreshed.tipAmount = offer.tipAmount;
        }
        if (refreshed.deliverymanCharge < offer.deliverymanCharge) {
          refreshed.deliverymanCharge = offer.deliverymanCharge;
        }
        if (refreshed.expectedIncentive < offer.expectedIncentive) {
          refreshed.expectedIncentive = offer.expectedIncentive;
        }
        // Live getStatus wins. Copy FCM lines only when server sent no
        // incentive at all (old backend without extra_incentive_items).
        if (refreshed.incentiveItems.isEmpty &&
            offer.incentiveItems.isNotEmpty &&
            refreshed.expectedIncentive <= 0) {
          refreshed.incentiveItems = offer.incentiveItems;
        }
        refreshed.incentiveLabel ??= offer.incentiveLabel;
        if ((refreshed.expectedTotalOverride == null ||
                refreshed.expectedTotalOverride! <= 0) &&
            offer.expectedTotalOverride != null &&
            offer.expectedTotalOverride! > 0) {
          refreshed.expectedTotalOverride = offer.expectedTotalOverride;
        }
        offer = refreshed;
      } catch (_) {
        return;
      }
    }

    if (isIncomingOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      await _stopIncomingAlert(orderId: offer.orderId, offerId: offer.offerId);
      return;
    }

    final liveExpires = offer.expiresIn ?? 0;
    if (liveExpires <= 0) {
      final status = (offer.status ?? '').toLowerCase();
      if (status.isNotEmpty && status != 'pending') {
        _markIncomingHandled(offerId: offer.offerId, orderId: null);
        await _stopIncomingAlert(orderId: offer.orderId, offerId: offer.offerId);
        return;
      }
      offer.expiresIn = offerTimeoutSeconds;
    }

    _activeIncomingOffer = offer;
    update();
    _startIncomingAlert(offer, fresh: true);
    _presentIncomingSheet(offer);
  }

  /// Poll server for a pending transfer offer (covers missed push / no sheet).
  Future<void> pollPendingIncoming({bool presentIfFound = true}) async {
    // Free bandwidth while COD Accept Payment QR is verifying UPI.
    if (Get.isRegistered<OrderDetailsController>() &&
        Get.find<OrderDetailsController>().isAcceptPaymentSheetOpen) {
      return;
    }
    try {
      final response = await repository.pendingIncoming();
      if (response.statusCode != 200 || response.body is! Map) return;
      final body = Map<String, dynamic>.from(response.body as Map);
      if ((body['has_offer'] ?? 0) != 1 && body['has_offer'] != true) return;
      final offerMap = body['offer'];
      if (offerMap is! Map) return;
      final offer =
          TransferOfferModel.fromJson(Map<String, dynamic>.from(offerMap));
      if (offer.offerId == null || offer.offerId! <= 0) return;
      if (offer.offerId != null &&
          offer.offerId! > 0 &&
          _handledIncomingOfferIds.contains(offer.offerId)) {
        // A new manual Transfer creates a new offer_id and is not in this set.
        unawaited(_closeOfferOnServer(offer.offerId!, 'timeout'));
        return;
      }
      if (isIncomingOfferAlreadyHandled(
        offerId: offer.offerId,
        orderId: offer.orderId,
      )) {
        return;
      }
      if (!presentIfFound) return;
      if (isIncomingOfferLive(offerId: offer.offerId)) {
        return;
      }
      await openIncomingFromNotification(
        offerId: offer.offerId,
        orderId: offer.orderId,
        pushData: Map<String, dynamic>.from(offerMap),
        requireLiveOnServer: false,
      );
    } catch (_) {}
  }

  List<Map<String, dynamic>> _recentOutgoing = [];
  List<Map<String, dynamic>> get recentOutgoing => _recentOutgoing;

  Future<void> loadRecentOutgoing() async {
    try {
      final response = await repository.recentOutgoing(limit: 5);
      if (response.statusCode == 200 && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        final items = body['items'];
        if (items is List) {
          _recentOutgoing = items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          update();
        }
      }
    } catch (_) {}
  }

  void _presentIncomingSheet(TransferOfferModel offer) {
    if (offer.offerId == null) return;
    if (isIncomingOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      unawaited(_stopIncomingAlert(
        orderId: offer.orderId,
        offerId: offer.offerId,
      ));
      return;
    }

    if (_incomingSheetOpen &&
        _shownIncomingOfferId == offer.offerId &&
        Get.isBottomSheetOpen == true) {
      // Keep sheet; re-assert ring/vibrate (same as assignment offer).
      _startIncomingAlert(offer, fresh: false);
      return;
    }

    if (_pendingPresentOfferId == offer.offerId ||
        (_activeIncomingOffer?.offerId == offer.offerId &&
            _incomingSheetOpen)) {
      _activeIncomingOffer = offer;
      _startIncomingAlert(offer, fresh: false);
      return;
    }

    // Recover stale open flag (sheet gone, bell still ringing).
    if (_incomingSheetOpen && Get.isBottomSheetOpen != true) {
      _incomingSheetOpen = false;
      _shownIncomingOfferId = null;
    }

    _pendingPresentOfferId = offer.offerId;
    _activeIncomingOffer = offer;
    _startIncomingTick();
    _startIncomingStatusPoll();
    _startIncomingAlert(offer, fresh: true);
    _armIncomingSheetWatchdog(offer);

    final int presentGen = ++_incomingUiGeneration;

    void tryShow() {
      if (presentGen != _incomingUiGeneration) return;
      if (_pendingPresentOfferId != offer.offerId &&
          _shownIncomingOfferId != offer.offerId) {
        return;
      }
      if (_incomingSheetOpen &&
          _shownIncomingOfferId == offer.offerId &&
          Get.isBottomSheetOpen == true) {
        return;
      }
      _showIncomingSheetNow(offer, presentGen: presentGen);
    }

    Future.microtask(() {
      if (Get.context != null || Get.key.currentContext != null) {
        tryShow();
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => tryShow());
    });

    _incomingPresentRetryTimer?.cancel();
    _incomingPresentRetryTimer = Timer(const Duration(milliseconds: 450), () {
      if (presentGen != _incomingUiGeneration) return;
      if (_incomingSheetOpen &&
          _shownIncomingOfferId == offer.offerId &&
          Get.isBottomSheetOpen == true) {
        return;
      }
      tryShow();
    });
  }

  void _armIncomingSheetWatchdog(TransferOfferModel offer) {
    _incomingSheetWatchdog?.cancel();
    _incomingSheetWatchdog = Timer(const Duration(milliseconds: 900), () {
      unawaited(_reconcileIncomingSheetWithAlert(offer));
    });
  }

  Future<void> _reconcileIncomingSheetWithAlert(TransferOfferModel offer) async {
    if (isIncomingOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      await _stopIncomingAlert(
        orderId: offer.orderId,
        offerId: offer.offerId,
      );
      return;
    }
    if (_activeIncomingOffer == null ||
        _activeIncomingOffer?.offerId != offer.offerId) {
      return;
    }
    final sheetVisible = _incomingSheetOpen &&
        _shownIncomingOfferId == offer.offerId &&
        Get.isBottomSheetOpen == true;
    if (sheetVisible) return;

    final alertLive =
        NewOrderAlertHelper.isActive || await NewOrderAlertHelper.isAlertLive();
    if (!alertLive && _pendingPresentOfferId == null) return;

    if (_incomingSheetOpen && Get.isBottomSheetOpen != true) {
      _incomingSheetOpen = false;
      if (_shownIncomingOfferId == offer.offerId) {
        _shownIncomingOfferId = null;
      }
    }

    final live = _activeIncomingOffer;
    if (live == null || live.offerId == null) {
      if (alertLive) await NewOrderAlertHelper.stop();
      return;
    }
    if (isIncomingOfferAlreadyHandled(
      offerId: live.offerId,
      orderId: live.orderId,
    )) {
      await _stopIncomingAlert(orderId: live.orderId, offerId: live.offerId);
      return;
    }
    if (!_incomingSheetOpen || Get.isBottomSheetOpen != true) {
      _pendingPresentOfferId = live.offerId;
      _showIncomingSheetNow(live, presentGen: _incomingUiGeneration);
    }
  }

  void _showIncomingSheetNow(
    TransferOfferModel offer, {
    required int presentGen,
  }) {
    if (presentGen != _incomingUiGeneration) return;
    if (offer.offerId == null) return;
    if (isIncomingOfferAlreadyHandled(
      offerId: offer.offerId,
      orderId: offer.orderId,
    )) {
      _pendingPresentOfferId = null;
      unawaited(_stopIncomingAlert(
        orderId: offer.orderId,
        offerId: offer.offerId,
      ));
      return;
    }

    final ctx = Get.context ?? Get.key.currentContext;
    if (ctx == null) {
      _incomingPresentRetryTimer?.cancel();
      _incomingPresentRetryTimer =
          Timer(const Duration(milliseconds: 350), () {
        if (presentGen != _incomingUiGeneration) return;
        _showIncomingSheetNow(offer, presentGen: presentGen);
      });
      return;
    }

    if (Get.isBottomSheetOpen == true &&
        _shownIncomingOfferId != null &&
        _shownIncomingOfferId != offer.offerId) {
      Get.back();
    }

    if (_incomingSheetOpen &&
        _shownIncomingOfferId == offer.offerId &&
        Get.isBottomSheetOpen == true) {
      _pendingPresentOfferId = null;
      return;
    }

    _pendingPresentOfferId = null;
    _shownIncomingOfferId = offer.offerId;
    _incomingSheetOpen = true;
    _activeIncomingOffer = offer;

    unawaited(AppForegroundHelper.dismissOrderWakeHeadsUp());
    if (offer.orderId != null && offer.orderId! > 0) {
    }

    Get.bottomSheet(
      TransferOfferSheet(offer: offer),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
    ).whenComplete(() {
      if (presentGen != _incomingUiGeneration) {
        return;
      }
      final closedId = offer.offerId;
      if (_shownIncomingOfferId != null &&
          closedId != null &&
          _shownIncomingOfferId != closedId) {
        return;
      }
      if (_incomingSheetOpen && Get.isBottomSheetOpen == true) {
        return;
      }
      _incomingSheetOpen = false;
      if (_shownIncomingOfferId == closedId) {
        _shownIncomingOfferId = null;
      }

      if (_responding) return;
      if (isIncomingOfferAlreadyHandled(
        offerId: closedId,
        orderId: offer.orderId,
      )) {
        unawaited(_stopIncomingAlert(
          orderId: offer.orderId,
          offerId: closedId,
        ));
        return;
      }

      // reopen. Do NOT expire the offer; that cut the bell after ~2s.
      if (closedId != null &&
          _activeIncomingOffer?.offerId == closedId &&
          !_responding) {
        unawaited(() async {
          if (await NewOrderAlertHelper.isMuted()) return;
          _pendingPresentOfferId = closedId;
          _startIncomingAlert(offer, fresh: false);
        }());
        Future.delayed(const Duration(milliseconds: 400), () async {
          if (presentGen != _incomingUiGeneration) return;
          if (_responding) return;
          if (await NewOrderAlertHelper.isMuted()) return;
          if (isIncomingOfferAlreadyHandled(
            offerId: closedId,
            orderId: offer.orderId,
          )) {
            return;
          }
          if (_incomingSheetOpen && Get.isBottomSheetOpen == true) return;
          _showIncomingSheetNow(offer, presentGen: presentGen);
        });
        return;
      }

      _incomingTickTimer?.cancel();
      _incomingTickTimer = null;
      _stopIncomingStatusPoll();
    });
  }

  Future<void> _stopIncomingAlert({
    int? orderId,
    int? offerId,
    Duration mute = const Duration(seconds: 90),
  }) async {
    await NewOrderAlertHelper.muteFor(mute, offerId: offerId);
    await NewOrderAlertHelper.stop();
    if (orderId != null && orderId > 0) {
    }
  }

  /// re-kicks must never clear post-accept mute (ignoreMute: false).
  void _startIncomingAlert(TransferOfferModel offer, {bool fresh = false}) {
    final offerId = offer.offerId;
    if (offerId == null || offerId <= 0) return;
    if (_responding) return;
    if (isIncomingOfferAlreadyHandled(
      offerId: offerId,
      orderId: offer.orderId,
    )) {
      unawaited(_stopIncomingAlert(
        orderId: offer.orderId,
        offerId: offerId,
      ));
      return;
    }

    unawaited(() async {
      if (_responding) return;
      if (isIncomingOfferAlreadyHandled(
        offerId: offerId,
        orderId: offer.orderId,
      )) {
        return;
      }
      // fresh:true may clear post-accept mute for a *different* offer_id only.
      if (!fresh) {
        if (await NewOrderAlertHelper.isMuted()) return;
      } else {
        final cleared =
            await NewOrderAlertHelper.clearMuteIfNewOffer(offerId);
        if (!cleared && await NewOrderAlertHelper.isMuted()) return;
      }

      final alertLive = await NewOrderAlertHelper.isAlertLive();
      if (!fresh && (NewOrderAlertHelper.isActive || alertLive)) {
        await NewOrderAlertHelper.start(
          loopUntilStopped: true,
          forceRestart: false,
          ignoreMute: false,
        );
        return;
      }

      await NewOrderAlertHelper.start(
        loopUntilStopped: true,
        forceRestart: fresh || (!alertLive && !NewOrderAlertHelper.isActive),
        ignoreMute: false,
      );
    }());
  }

  void _startIncomingTick() {
    _incomingTickTimer?.cancel();
    _incomingTickTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      final offer = _activeIncomingOffer;
      if (offer == null) return;
      final left = offer.expiresIn ?? 0;
      if (left <= 0) {
        // Hard audio stop is in NewOrderAlertHelper (90s). Poll dismisses when expired.
        return;
      }
      offer.expiresIn = left - 1;
      update();
    });
  }

  void _startIncomingStatusPoll() {
    _incomingStatusPollTimer?.cancel();
    _incomingStatusPollTimer =
        Timer.periodic(const Duration(seconds: 2), (_) async {
      final offer = _activeIncomingOffer;
      final id = offer?.offerId;
      if (id == null || _incomingStatusPollInFlight || _responding) return;
      _incomingStatusPollInFlight = true;
      try {
        final response = await repository.getStatus(id);
        if (response.statusCode != 200 || response.body is! Map) return;
        final body = Map<String, dynamic>.from(response.body as Map);
        final status = (body['status'] ?? '').toString().toLowerCase();
        final expiresIn = int.tryParse('${body['expires_in'] ?? ''}');
        if (expiresIn != null && status == 'pending') {
          offer?.expiresIn = expiresIn;
          update();
          if (expiresIn <= 0) {
            await _closeIncomingAsExpired();
            return;
          }
          if (!_responding && offer != null) {
            _startIncomingAlert(offer, fresh: false);
          }
        }
        if (status.isNotEmpty && status != 'pending') {
          await _dismissIncomingResolved(
            status: status,
            offerId: id,
            orderId: offer?.orderId,
          );
        }
      } catch (_) {
      } finally {
        _incomingStatusPollInFlight = false;
      }
    });
  }

  void _stopIncomingStatusPoll() {
    _incomingStatusPollTimer?.cancel();
    _incomingStatusPollTimer = null;
  }

  Future<void> _closeIncomingAsExpired() async {
    if (_responding) return;
    final offer = _activeIncomingOffer;
    if (offer?.offerId != null &&
        _handledIncomingOfferIds.contains(offer!.offerId)) {
      return;
    }
    _incomingUiGeneration++;
    _pendingPresentOfferId = null;
    _incomingTickTimer?.cancel();
    _incomingTickTimer = null;
    _stopIncomingStatusPoll();
    _incomingSheetWatchdog?.cancel();
    _incomingPresentRetryTimer?.cancel();
    _markIncomingHandled(offerId: offer?.offerId, orderId: null);
    if (offer?.offerId != null && offer!.offerId! > 0) {
      unawaited(_closeOfferOnServer(offer.offerId!, 'timeout'));
    }
    await _stopIncomingAlert(
      orderId: offer?.orderId,
      offerId: offer?.offerId,
    );
    _activeIncomingOffer = null;
    if (Get.isBottomSheetOpen == true) Get.back();
    update();
    showQuikseeSnackBarWidget('transfer_expired_toast'.tr);
  }

  Future<void> _dismissIncomingResolved({
    required String status,
    int? offerId,
    int? orderId,
  }) async {
    if (offerId != null &&
        offerId > 0 &&
        _handledIncomingOfferIds.contains(offerId) &&
        _activeIncomingOffer == null) {
      return;
    }
    _incomingUiGeneration++;
    _pendingPresentOfferId = null;
    _markIncomingHandled(offerId: offerId, orderId: null);
    _stopIncomingStatusPoll();
    _incomingTickTimer?.cancel();
    _incomingTickTimer = null;
    _incomingSheetWatchdog?.cancel();
    _incomingPresentRetryTimer?.cancel();
    await _stopIncomingAlert(orderId: orderId, offerId: offerId);
    _activeIncomingOffer = null;
    if (Get.isBottomSheetOpen == true) Get.back();
    update();
    if (status == 'accepted') {
      showQuikseeSnackBarWidget(
        orderId != null
            ? 'order_accepted_by_another_dm'.trParams({'order': '$orderId'})
            : 'order_accepted_by_another_dm_generic'.tr,
      );
    } else if (status == 'cancelled') {
      showQuikseeSnackBarWidget('transfer_cancelled_toast'.tr);
    } else if (status == 'expired') {
      showQuikseeSnackBarWidget('transfer_expired_toast'.tr);
    } else if (status == 'rejected') {
      // Own reject already toasted in respondIncoming.
    }
  }

  void onIncomingOfferCancelledPush({
    int? offerId,
    int? orderId,
    String? reason,
  }) {
    final active = _activeIncomingOffer;
    final matchesOffer = offerId != null &&
        offerId > 0 &&
        active?.offerId != null &&
        active!.offerId == offerId;
    final matchesOrder = orderId != null &&
        orderId > 0 &&
        active?.orderId != null &&
        active!.orderId == orderId;
    final matches = matchesOffer ||
        matchesOrder ||
        (active == null && (offerId != null || orderId != null));

    if (offerId != null &&
        offerId > 0 &&
        _handledIncomingOfferIds.contains(offerId) &&
        active == null) {
      return;
    }

    _incomingUiGeneration++;
    _pendingPresentOfferId = null;
    _markIncomingHandled(offerId: offerId, orderId: null);
    unawaited(_stopIncomingAlert(orderId: orderId, offerId: offerId));
    _incomingSheetWatchdog?.cancel();
    _incomingPresentRetryTimer?.cancel();

    if (!matches && active != null) return;

    _stopIncomingStatusPoll();
    _incomingTickTimer?.cancel();
    _incomingTickTimer = null;
    _activeIncomingOffer = null;
    if (Get.isBottomSheetOpen == true && _incomingSheetOpen) {
      Get.back();
    }
    update();
    if (reason == 'taken' || reason == 'accepted_by_another') {
      showQuikseeSnackBarWidget(
        orderId != null
            ? 'order_accepted_by_another_dm'.trParams({'order': '$orderId'})
            : 'order_accepted_by_another_dm_generic'.tr,
      );
    }
  }

  Future<void> respondIncoming(String action) async {
    final offer = _activeIncomingOffer;
    final id = offer?.offerId;
    if (id == null || _responding) return;

    _responding = true;
    _incomingUiGeneration++;
    _pendingPresentOfferId = null;
    _incomingSheetWatchdog?.cancel();
    _incomingPresentRetryTimer?.cancel();
    _incomingTickTimer?.cancel();
    _incomingTickTimer = null;
    _stopIncomingStatusPoll();

    _markIncomingHandled(
      offerId: id,
      orderId: offer?.orderId,
      blockOrder: action == 'accept',
    );

    await _stopIncomingAlert(
      orderId: offer?.orderId,
      offerId: id,
    );
    update();

    var settled = false;
    try {
      final response = await repository.respond(offerId: id, action: action);
      if (response.statusCode == 200 && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        if (body['success'] == true) {
          _incomingUiGeneration++;
          _markIncomingHandled(
            offerId: id,
            orderId: offer?.orderId,
            blockOrder: action == 'accept',
          );
          await _stopIncomingAlert(
            orderId: offer?.orderId,
            offerId: id,
          );
          _activeIncomingOffer = null;
          _incomingSheetOpen = false;
          _shownIncomingOfferId = null;
          if (Get.isBottomSheetOpen == true) Get.back();
          if (action == 'accept') {
            final acceptedOrderId = offer?.orderId ??
                int.tryParse('${body['order_id'] ?? ''}');
            Map<String, dynamic>? orderJson;
            final rawOrder = body['order'];
            if (rawOrder is Map) {
              orderJson = Map<String, dynamic>.from(rawOrder);
            } else if (acceptedOrderId != null && acceptedOrderId > 0) {
              // "go to store" (confirmed) or Reach Store button reappears.
              orderJson = {
                'id': acceptedOrderId,
                'order_status': 'reached_restaurant',
                'store_wait_started_at':
                    DateTime.now().toIso8601String(),
                'store_wait_active': 1,
                'store_wait_enabled': 1,
                'order_transfer_received': 1,
                'order_transfer_already_done': 1,
                'order_transfer_from_name': offer?.fromRiderName,
                'order_transfer_from_id': offer?.fromDeliveryManId,
                'expected_tip': offer?.tipAmount,
                'deliveryman_charge': offer?.deliverymanCharge,
                if ((offer?.storeName ?? '').trim().isNotEmpty)
                  'seller': {
                    'shop': {'name': offer!.storeName},
                  },
              };
            }
            if (acceptedOrderId != null &&
                acceptedOrderId > 0 &&
                Get.isRegistered<OrderController>()) {
              if (orderJson != null) {
                final status =
                    (orderJson['order_status'] ?? '').toString().toLowerCase();
                if (status == 'confirmed' ||
                    status.isEmpty ||
                    status == 'null') {
                  // Never land transfer takeover on "go to store".
                  orderJson['order_status'] = 'reached_restaurant';
                }
                orderJson['order_transfer_received'] = 1;
                orderJson['store_wait_active'] = 1;
                orderJson['store_wait_enabled'] = 1;
                if ((orderJson['store_wait_started_at'] ?? '')
                    .toString()
                    .trim()
                    .isEmpty) {
                  orderJson['store_wait_started_at'] =
                      DateTime.now().toIso8601String();
                }
              }
              await Get.find<OrderController>().mergeAcceptedOrder(
                orderId: acceptedOrderId,
                orderJson: orderJson,
              );
              if (Get.isRegistered<OrderDetailsController>()) {
                Get.find<OrderDetailsController>()
                    .markReachedRestaurantLocally(acceptedOrderId);
              }
            }
            if (Get.isRegistered<AssignmentController>()) {
              Get.find<AssignmentController>().markDriverBusy(true);
            }
            showQuikseeSnackBarWidget(
              'transfer_you_accepted'.tr,
              isError: false,
            );
            // Background sync for full details (addresses, ETA, etc.).
            unawaited(_refreshOrdersAfterAccept(acceptedOrderId));
          } else {
            showQuikseeSnackBarWidget(
              'transfer_you_rejected'.tr,
              isError: false,
            );
          }
          update();
          settled = true;
          return;
        }
        // Already taken / cancelled by someone else.
        final code = body['code']?.toString();
        if (code == 'already_resolved' ||
            (body['message']?.toString() ?? '')
                .toLowerCase()
                .contains('already')) {
          await _dismissIncomingResolved(
            status: 'accepted',
            offerId: id,
            orderId: offer?.orderId,
          );
          return;
        }
        showQuikseeSnackBarWidget(
          body['message']?.toString() ?? 'transfer_failed'.tr,
        );
        return;
      }
      final msg = response.body is Map
          ? (response.body as Map)['message']?.toString()
          : null;
        showQuikseeSnackBarWidget(msg ?? 'transfer_failed'.tr);
    } catch (_) {
      showQuikseeSnackBarWidget('transfer_failed'.tr);
    } finally {
      _responding = false;
      if (settled) return;
      _handledIncomingOfferIds.remove(id);
      if (action == 'accept' &&
          offer?.orderId != null &&
          offer!.orderId! > 0) {
        _handledIncomingOrderIds.remove(offer.orderId);
      }
      await NewOrderAlertHelper.clearMute(clearOfferId: true);
      final live = _activeIncomingOffer;
      if (live != null && live.offerId == id) {
        _startIncomingTick();
        _startIncomingStatusPoll();
        _startIncomingAlert(live, fresh: false);
      }
      update();
    }
  }

  Future<void> _refreshOrdersAfterAccept(int? orderId) async {
    if (Get.isRegistered<OrderController>()) {
      await Get.find<OrderController>().refreshCurrentOrdersOnly(
        force: true,
        promptAccept: false,
      );
    }
    if (orderId != null &&
        orderId > 0 &&
        Get.isRegistered<OrderDetailsController>() &&
        Get.context != null) {
      unawaited(Get.find<OrderDetailsController>().getOrderDetails(
        '$orderId',
        Get.context!,
        silent: true,
      ));
    }
  }

  Future<void> handleOutgoingAcceptedPush({
    int? orderId,
    String? toRiderName,
  }) async {
    _stopOutgoingPoll();
    await _stopIncomingAlert(orderId: orderId);
    if (Get.isBottomSheetOpen == true) Get.back();
    _notifyOutgoingTerminal('transfer_accepted_toast'.tr, isError: false);
    markOrderTransferAcceptedLocally(orderId);
    _clearOutgoing();
    unawaited(loadRecentOutgoing());
    if (Get.isRegistered<OrderController>()) {
      if (orderId != null && orderId > 0) {
        unawaited(
          Get.find<OrderController>().onAssignedOrderReleasedPush(
            orderId: orderId,
          ),
        );
      } else {
        unawaited(Get.find<OrderController>().refreshCurrentOrdersOnly(
          force: true,
          promptAccept: false,
        ));
      }
    }
    final idLabel = (orderId != null && orderId > 0) ? '#$orderId' : '';
    final toLabel = (toRiderName ?? '').trim();
    final message = toLabel.isNotEmpty
        ? 'Order $idLabel transferred to $toLabel'
        : 'Order $idLabel transferred';
    if (Get.context != null) {
      await Get.dialog(
        AlertDialog(
          title: Text('order_transferred'.tr),
          content: Text(
            message,
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('ok'.tr),
            ),
          ],
        ),
        barrierDismissible: true,
      );
    }
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  @override
  void onClose() {
    stopIncomingOfferWatch();
    _stopOutgoingPoll();
    _incomingTickTimer?.cancel();
    _stopIncomingStatusPoll();
    _incomingSheetWatchdog?.cancel();
    _incomingPresentRetryTimer?.cancel();
    super.onClose();
  }
}
