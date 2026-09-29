import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_binding.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_helper.dart';
import 'package:quiksee/features/order_transfer/screens/transfer_candidates_screen.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// Countdown after Reach Store; Poke when prep overdue.
/// After packing/ready: hide poke and show extra time past prep deadline.
class StoreWaitPokeCardWidget extends StatefulWidget {
  final OrderModel? orderModel;
  final bool embedded;

  const StoreWaitPokeCardWidget({
    super.key,
    this.orderModel,
    this.embedded = false,
  });

  @override
  State<StoreWaitPokeCardWidget> createState() =>
      _StoreWaitPokeCardWidgetState();
}

class _StoreWaitPokeCardWidgetState extends State<StoreWaitPokeCardWidget> {
  Timer? _tick;
  bool _poking = false;
  int _remainingSeconds = 0;
  int _overdueSeconds = 0;
  int _overdue = 0;
  int _canPoke = 0;
  int _pokeCount = 0;
  int _pokeMax = 3;
  String? _deadlineAt;
  String? _nextPokeAt;
  bool _active = false;
  bool _showExtra = false;
  bool _packed = false;
  bool _didRefreshOnOverdue = false;

  @override
  void initState() {
    super.initState();
    _syncFromOrder(widget.orderModel);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.isRegistered<AssignmentController>()) {
        await Get.find<AssignmentController>().loadAssignmentSettings();
        if (mounted) setState(() {});
      }
      unawaited(_refreshFromApi());
    });
  }

  @override
  void didUpdateWidget(covariant StoreWaitPokeCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderModel?.id != widget.orderModel?.id ||
        oldWidget.orderModel?.storeWaitActive !=
            widget.orderModel?.storeWaitActive ||
        oldWidget.orderModel?.storeWaitDeadlineAt !=
            widget.orderModel?.storeWaitDeadlineAt ||
        oldWidget.orderModel?.vendorReadyAt !=
            widget.orderModel?.vendorReadyAt ||
        oldWidget.orderModel?.orderStatus != widget.orderModel?.orderStatus ||
        oldWidget.orderModel?.storeWaitOverdueSeconds !=
            widget.orderModel?.storeWaitOverdueSeconds) {
      _syncFromOrder(widget.orderModel);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool _isPacked(OrderModel? order) {
    if (order == null) return _packed;
    if ((order.storeWaitPacked ?? 0) == 1) return true;
    final ready = (order.vendorReadyAt ?? '').trim();
    if (ready.isNotEmpty && ready != 'null') return true;
    final status = (order.orderStatus ?? '').toLowerCase();
    return status == 'processing';
  }

  bool _hasWaitStart(OrderModel? order) {
    final raw = (order?.storeWaitStartedAt ?? '').trim();
    return raw.isNotEmpty && raw != 'null';
  }

  void _syncFromOrder(OrderModel? order) {
    if (order == null) {
      _active = false;
      _showExtra = false;
      _packed = false;
      return;
    }
    _packed = _isPacked(order);
    final status = (order.orderStatus ?? '').toLowerCase().trim();
    // Only infer active from start-time when already at store.
    // confirmed + started_at must NOT auto-activate (en-route false positive).
    _active = order.storeWaitActive == 1 ||
        (!_packed && status == 'reached_restaurant' && _hasWaitStart(order));
    _showExtra = order.storeWaitShowExtra == 1 ||
        (_packed && (order.storeWaitOverdueSeconds ?? 0) > 0) ||
        (!_packed && _active);
    _deadlineAt = order.storeWaitDeadlineAt;
    _remainingSeconds = order.storeWaitRemainingSeconds ?? 0;
    _overdueSeconds = order.storeWaitOverdueSeconds ?? 0;
    _overdue = order.storeWaitOverdue ?? 0;
    _canPoke = order.canPoke ?? 0;
    _pokeCount = order.pokeCount ?? 0;
    _pokeMax = order.pokeMax ?? 3;
    _nextPokeAt = order.nextPokeAt;
    _recomputeRemaining();
  }

  bool _isCooldownActive() {
    if (_nextPokeAt == null || _nextPokeAt!.isEmpty) return false;
    try {
      return DateTime.parse(_nextPokeAt!).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Also unlock when Transfer is available (same long-wait window) so Poke
  /// does not disappear while Transfer button is shown.
  bool _canPokeLocally({
    required bool overdue,
    bool transferUnlocked = false,
  }) {
    if (_packed) return false;
    if (!overdue && !transferUnlocked) return false;
    if (_pokeCount >= _pokeMax) return false;
    if (_isCooldownActive()) return false;
    return true;
  }

  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'null') return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  void _recomputeRemaining() {
    final order = widget.orderModel;
    final packed = _isPacked(order);
    _packed = packed;

    // (that unlocks poke instantly because start == "deadline").
    final deadline = _parseTime(_deadlineAt);
    if (deadline == null) {
      if (!packed && order?.storeWaitRemainingSeconds != null) {
        final remaining = order!.storeWaitRemainingSeconds!;
        _remainingSeconds = remaining < 0 ? 0 : remaining;
      }
      if ((order?.storeWaitOverdue ?? 0) == 1) {
        _overdue = 1;
        _overdueSeconds =
            order?.storeWaitOverdueSeconds ?? _overdueSeconds;
      }
      return;
    }

    if (packed) {
      // Freeze at packing / vendor ready time (or server overdue seconds).
      final ready = _parseTime(order?.vendorReadyAt);
      final end = ready ?? DateTime.now();
      final extra = end.difference(deadline).inSeconds;
      _remainingSeconds = 0;
      _overdue = 1;
      _overdueSeconds = extra > 0
          ? extra
          : (order?.storeWaitOverdueSeconds ?? _overdueSeconds);
      if (_overdueSeconds < 0) _overdueSeconds = 0;
      _showExtra = _overdueSeconds > 0;
      return;
    }

    if (!_active &&
        order?.storeWaitActive != 1 &&
        !_hasWaitStart(order)) {
      return;
    }

    final secs = deadline.difference(DateTime.now()).inSeconds;
    final wasOverdue = _overdue == 1;
    _remainingSeconds = secs > 0 ? secs : 0;
    _overdue = secs <= 0 ? 1 : 0;
    _overdueSeconds = secs < 0 ? -secs : 0;
    _showExtra = _overdue == 1 && _overdueSeconds > 0;
    if (_overdue == 1 && !wasOverdue) {
      _didRefreshOnOverdue = false;
    }
  }

  void _onTick() {
    if (!mounted) return;
    final order = widget.orderModel;
    final status = (order?.orderStatus ?? '').toLowerCase();
    if (status == 'out_for_delivery' ||
        status == 'arrived_at_customer' ||
        status == 'delivered' ||
        status == 'canceled' ||
        status == 'cancelled' ||
        status == 'failed' ||
        status == 'returned') {
      return;
    }
    final packed = _isPacked(order);
    // Packed: rebuild so Transfer can unlock at 40s, but do not recompute
    // extra time with DateTime.now() (that made +mm:ss keep growing).
    if (packed) {
      setState(() {});
      return;
    }
    if (!_active &&
        order?.storeWaitActive != 1 &&
        !_hasWaitStart(order)) {
      return;
    }
    setState(() {
      _recomputeRemaining();
    });
    // Time just finished → refresh server meta + unlock poke immediately.
    if (_overdue == 1 && !_didRefreshOnOverdue) {
      _didRefreshOnOverdue = true;
      unawaited(_refreshFromApi());
    }
  }

  void _applyMeta(Map<String, dynamic> body, OrderModel order) {
    order.storeWaitEnabled =
        int.tryParse('${body['store_wait_enabled'] ?? ''}') ??
            order.storeWaitEnabled;
    order.storeWaitActive =
        int.tryParse('${body['store_wait_active'] ?? ''}') ??
            order.storeWaitActive;
    order.storeWaitStartedAt =
        body['store_wait_started_at']?.toString() ?? order.storeWaitStartedAt;
    order.storeWaitDeadlineAt =
        body['store_wait_deadline_at']?.toString() ?? order.storeWaitDeadlineAt;
    order.storeWaitRemainingSeconds =
        int.tryParse('${body['store_wait_remaining_seconds'] ?? ''}') ??
            order.storeWaitRemainingSeconds;
    order.storeWaitOverdue =
        int.tryParse('${body['store_wait_overdue'] ?? ''}') ??
            order.storeWaitOverdue;
    order.storeWaitOverdueSeconds =
        int.tryParse('${body['store_wait_overdue_seconds'] ?? ''}') ??
            order.storeWaitOverdueSeconds;
    final savedExtra =
        int.tryParse('${body['store_wait_extra_seconds'] ?? ''}');
    if (savedExtra != null) {
      order.storeWaitOverdueSeconds = savedExtra;
    }
    order.storeWaitShowExtra =
        int.tryParse('${body['store_wait_show_extra'] ?? ''}') ??
            order.storeWaitShowExtra;
    order.storeWaitPacked =
        int.tryParse('${body['store_wait_packed'] ?? ''}') ??
            order.storeWaitPacked;
    final readyAt = body['vendor_ready_at']?.toString();
    if (readyAt != null && readyAt.isNotEmpty && readyAt != 'null') {
      order.vendorReadyAt = readyAt;
    }
    order.canPoke =
        int.tryParse('${body['can_poke'] ?? ''}') ?? order.canPoke;
    order.pokeCount =
        int.tryParse('${body['poke_count'] ?? ''}') ?? order.pokeCount;
    order.pokeMax =
        int.tryParse('${body['poke_max'] ?? ''}') ?? order.pokeMax;
    order.nextPokeAt =
        body['next_poke_at']?.toString() ?? order.nextPokeAt;
    order.storeLastPokeAt =
        body['store_last_poke_at']?.toString() ?? order.storeLastPokeAt;
    final transferEnabledRaw = body['order_transfer_enabled'];
    if (transferEnabledRaw != null) {
      final transferEnabled = int.tryParse('$transferEnabledRaw');
      final hasFullTransferMeta =
          body.containsKey('order_transfer_unlock_mode') ||
              body.containsKey('order_transfer_unlocked') ||
              body.containsKey('order_transfer_after_reach_seconds');
      // Ignore a stub enabled=0 that would hide Transfer after the 40s unlock.
      if (transferEnabled == 1 ||
          hasFullTransferMeta ||
          (order.orderTransferEnabled ?? 0) != 1) {
        order.orderTransferEnabled = transferEnabled;
      }
    }
    final alreadyDone = int.tryParse('${body['order_transfer_already_done'] ?? ''}');
    if (alreadyDone != null) {
      order.orderTransferAlreadyDone = alreadyDone;
    }
    final locked = int.tryParse('${body['order_transfer_locked'] ?? ''}');
    if (locked != null) {
      order.orderTransferLocked = locked;
    }
    final unlockMode = body['order_transfer_unlock_mode']?.toString();
    if (unlockMode != null && unlockMode.isNotEmpty && unlockMode != 'null') {
      order.orderTransferUnlockMode = unlockMode;
    }
    order.orderTransferAfterReachSeconds = int.tryParse(
            '${body['order_transfer_after_reach_seconds'] ?? ''}') ??
        order.orderTransferAfterReachSeconds;
    order.orderTransferOnlyAfterPrepOverdue = int.tryParse(
            '${body['order_transfer_only_after_prep_overdue'] ?? ''}') ??
        order.orderTransferOnlyAfterPrepOverdue;
    order.orderTransferOnlyAfterReachStore = int.tryParse(
            '${body['order_transfer_only_after_reach_store'] ?? ''}') ??
        order.orderTransferOnlyAfterReachStore;
    order.orderTransferBlockAfterPackaging = int.tryParse(
            '${body['order_transfer_block_after_packaging'] ?? ''}') ??
        order.orderTransferBlockAfterPackaging;
    order.orderTransferBlockAfterPickup = int.tryParse(
            '${body['order_transfer_block_after_pickup'] ?? ''}') ??
        order.orderTransferBlockAfterPickup;
    order.orderTransferBlockOutForDelivery = int.tryParse(
            '${body['order_transfer_block_out_for_delivery'] ?? ''}') ??
        order.orderTransferBlockOutForDelivery;
    order.orderTransferReceived = int.tryParse(
            '${body['order_transfer_received'] ?? ''}') ??
        order.orderTransferReceived;
    order.orderTransferFromId = int.tryParse(
            '${body['order_transfer_from_id'] ?? ''}') ??
        order.orderTransferFromId;
    final fromName = body['order_transfer_from_name']?.toString();
    if (fromName != null && fromName.isNotEmpty && fromName != 'null') {
      order.orderTransferFromName = fromName;
    }
    order.orderTransferToId = int.tryParse(
            '${body['order_transfer_to_id'] ?? ''}') ??
        order.orderTransferToId;
    final toName = body['order_transfer_to_name']?.toString();
    if (toName != null && toName.isNotEmpty && toName != 'null') {
      order.orderTransferToName = toName;
    }
    _nextPokeAt = order.nextPokeAt;
    _syncFromOrder(order);
  }

  Future<void> _refreshFromApi() async {
    final order = widget.orderModel;
    if (order?.id == null || !Get.isRegistered<ApiClient>()) return;
    try {
      final response = await Get.find<ApiClient>().getData(
        '${AppConstants.storeWaitUri}?order_id=${order!.id}',
      );
      if (response.statusCode == 200 && response.body is Map && mounted) {
        final body = Map<String, dynamic>.from(response.body as Map);
        setState(() => _applyMeta(body, order));
        if (Get.isRegistered<OrderDetailsController>()) {
          Get.find<OrderDetailsController>().update();
        }
        if (Get.isRegistered<OrderController>()) {
          Get.find<OrderController>().update();
        }
      }
    } catch (_) {}
  }

  Future<void> _poke() async {
    final order = widget.orderModel;
    if (order?.id == null || _poking || _packed) return;
    if (!Get.isRegistered<ApiClient>()) return;
    setState(() => _poking = true);
    try {
      final response = await Get.find<ApiClient>().postData(
        AppConstants.storeWaitPokeUri,
        {'order_id': order!.id},
      );
      if (response.statusCode == 200 && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        if (mounted) setState(() => _applyMeta(body, order));
        final ok = body['success'] == true || body['success'] == 1;
        showQuikseeSnackBarWidget(
          body['message']?.toString() ??
              (ok ? 'store_poked_successfully'.tr : 'poke_failed'.tr),
          isError: !ok,
        );
        if (Get.isRegistered<OrderDetailsController>()) {
          Get.find<OrderDetailsController>().update();
        }
      } else {
        String msg = 'poke_failed'.tr;
        if (response.body is Map) {
          msg = (response.body as Map)['message']?.toString() ?? msg;
        }
        showQuikseeSnackBarWidget(msg);
      }
    } catch (_) {
      showQuikseeSnackBarWidget('poke_failed'.tr);
    } finally {
      if (mounted) setState(() => _poking = false);
    }
  }

  String _formatMmSs(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final m = safe ~/ 60;
    final s = safe % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildCard(BuildContext context, OrderTransferController? transferCtrl) {
        final order = widget.orderModel;
        if (order == null) return const SizedBox.shrink();

        final status = (order.orderStatus ?? '').toLowerCase();
        final terminal = status == 'out_for_delivery' ||
            status == 'arrived_at_customer' ||
            status == 'delivered' ||
            status == 'canceled' ||
            status == 'cancelled' ||
            status == 'failed' ||
            status == 'returned';
        if (terminal) return const SizedBox.shrink();

        final packed = _isPacked(order);
        final waitStarted = _hasWaitStart(order);
        // reached_restaurant: start time alone is enough (API may omit active=1).
        // confirmed: only if server says active (don't show timer while en-route).
        final waitingActive = !packed &&
            ((status == 'reached_restaurant' &&
                    (order.storeWaitActive == 1 || _active || waitStarted)) ||
                (status == 'confirmed' &&
                    (order.storeWaitActive == 1 || _active)));
        final showExtraPhase = packed &&
            waitStarted &&
            ((order.storeWaitShowExtra == 1) ||
                (order.storeWaitOverdueSeconds ?? _overdueSeconds) > 0 ||
                _showExtra);

        if (waitingActive || packed) {
          _deadlineAt = order.storeWaitDeadlineAt ?? _deadlineAt;
          _canPoke = order.canPoke ?? _canPoke;
          _pokeCount = order.pokeCount ?? _pokeCount;
          _pokeMax = order.pokeMax ?? _pokeMax;
          _nextPokeAt = order.nextPokeAt ?? _nextPokeAt;
          if ((order.storeWaitOverdueSeconds ?? 0) > 0 && packed) {
            _overdueSeconds = order.storeWaitOverdueSeconds!;
          }
          _recomputeRemaining();
        }

        final overdue = _overdue == 1 ||
            order.storeWaitOverdue == 1 ||
            _overdueSeconds > 0;
        final extraSeconds = _overdueSeconds > 0
            ? _overdueSeconds
            : (order.storeWaitOverdueSeconds ?? 0);
        final settings = Get.isRegistered<AssignmentController>()
            ? Get.find<AssignmentController>().settings
            : null;
        final pendingOutgoing = transferCtrl?.pendingOutgoingOffer;
        final waitingTransferAccept = pendingOutgoing != null &&
            pendingOutgoing.orderId != null &&
            pendingOutgoing.orderId == order.id &&
            (pendingOutgoing.expiresIn ?? 0) > 0;
        final transferDoneLocally =
            (order.orderTransferAlreadyDone ?? 0) == 1 ||
                (order.orderTransferLocked ?? 0) == 1 ||
                (transferCtrl?.isOrderTransferDoneLocally(order.id) ?? false);
        final showTransfer = transferCtrl != null &&
            !waitingTransferAccept &&
            !transferDoneLocally &&
            OrderTransferHelper.canShowTransfer(
              order,
              settings: settings,
              overdueOverride: overdue,
            );
        final transferBaseOk = transferCtrl != null &&
            !transferDoneLocally &&
            OrderTransferHelper.canShowTransferBase(
              order,
              settings: settings,
            );
        final transferSecondsLeft = OrderTransferHelper.secondsUntilUnlock(
          order,
          settings: settings,
          overdueOverride: overdue,
        );
        final showCard = waitingActive ||
            showExtraPhase ||
            showTransfer ||
            waitingTransferAccept ||
            (transferBaseOk && transferSecondsLeft > 0);
        if (!showCard) return const SizedBox.shrink();
        // Map: hide extra-time copy, but keep Transfer while still allowed.
        if (widget.embedded &&
            showExtraPhase &&
            !showTransfer &&
            !waitingTransferAccept &&
            !(transferBaseOk && transferSecondsLeft > 0)) {
          return const SizedBox.shrink();
        }
        // Hide poke after packing; keep Transfer while waiting / packed.
        final showPoke = !packed &&
            (overdue || showTransfer || waitingTransferAccept);
        final canPokeNow = _canPokeLocally(
          overdue: overdue,
          transferUnlocked: showTransfer || waitingTransferAccept,
        );
        final margin = widget.embedded
            ? EdgeInsets.only(bottom: Dimensions.paddingSizeSmall)
            : EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall);

        final showingExtra = packed || (overdue && extraSeconds > 0);
        const orange = Color(0xFFF57C00);
        final compact = showingExtra;
        return Container(
          width: double.infinity,
          margin: margin,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : Dimensions.paddingSizeDefault,
            vertical: compact ? 8 : Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            border: Border.all(
              color: orange.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (showingExtra
                                  ? (packed
                                      ? 'prep_extra_time_after_packing'.tr
                                      : 'prep_extra_time'.tr)
                                  : 'waiting_for_food_prep'.tr)
                              .toUpperCase(),
                          style: rubikBold.copyWith(
                            color: orange,
                            fontSize: compact ? 11 : Dimensions.fontSizeSmall,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 8),
                        Row(
                          children: [
                            Icon(
                              showingExtra
                                  ? Icons.more_time
                                  : Icons.soup_kitchen_outlined,
                              color: orange.withValues(alpha: 0.85),
                              size: compact ? 18 : 28,
                            ),
                            SizedBox(width: compact ? 6 : 10),
                            Text(
                              showingExtra
                                  ? '+${_formatMmSs(extraSeconds)}'
                                  : _formatMmSs(_remainingSeconds),
                              style: rubikBold.copyWith(
                                fontSize: compact ? 22 : 34,
                                letterSpacing: compact ? 1 : 2,
                                height: 1,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 2 : 6),
                        Text(
                          showingExtra
                              ? 'prep_extra_time_hint'.tr
                              : 'food_ready_countdown_hint'.tr,
                          style: rubikRegular.copyWith(
                            fontSize: compact ? 11 : Dimensions.fontSizeSmall,
                            color: Colors.black54,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: compact ? 36 : 56,
                    height: compact ? 36 : 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(compact ? 10 : 14),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      size: compact ? 20 : 32,
                      color: orange,
                    ),
                  ),
                ],
              ),
              if (showPoke ||
                  showTransfer ||
                  waitingTransferAccept ||
                  (transferBaseOk && transferSecondsLeft > 0)) ...[
                SizedBox(height: compact ? 8 : 12),
                Row(
                  children: [
                    if (showPoke) ...[
                      Tooltip(
                        message: _poking
                            ? 'please_wait'.tr
                            : (_pokeCount >= _pokeMax
                                ? 'poke_limit_reached'.tr
                                : (_isCooldownActive()
                                    ? 'poke_cooldown_active'.tr
                                    : 'poke_store'.tr)),
                        child: Material(
                          color: (_poking || !canPokeNow)
                              ? Colors.grey.shade400
                              : orange,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: (_poking || !canPokeNow) ? null : _poke,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: _poking
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.notifications_active_outlined,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      if (showTransfer ||
                          waitingTransferAccept ||
                          (transferBaseOk && transferSecondsLeft > 0))
                        const SizedBox(width: 10),
                    ],
                    if (waitingTransferAccept)
                      Tooltip(
                        message: 'waiting_for_rider_response'.tr,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.hourglass_top,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (showTransfer)
                      Expanded(
                        child: Tooltip(
                          message: 'transfer_order'.tr,
                          child: Material(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () {
                                final id = order.id;
                                if (id == null || id <= 0) return;
                                if (!OrderTransferBinding.ensure()) {
                                  showQuikseeSnackBarWidget(
                                      'transfer_failed'.tr);
                                  return;
                                }
                                Get.to(() =>
                                    TransferCandidatesScreen(orderId: id));
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 48,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'transfer_order'.tr,
                                      style: rubikMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: Dimensions.fontSizeSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (transferBaseOk && transferSecondsLeft > 0)
                      Tooltip(
                        message: 'Transfer in ${transferSecondsLeft}s',
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          child: Text(
                            '${transferSecondsLeft}s',
                            style: rubikBold.copyWith(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (showPoke && _pokeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'poke_count_label'.trParams(
                          {'count': '$_pokeCount', 'max': '$_pokeMax'}),
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Fenix can recreate OrderTransferController after dispose while the
    OrderTransferBinding.ensure();

    return GetBuilder<OrderDetailsController>(builder: (_) {
      // Timer/poke must show even if transfer DI is missing.
      if (!Get.isRegistered<OrderTransferController>()) {
        return _buildCard(context, null);
      }
      return GetBuilder<OrderTransferController>(builder: (transferCtrl) {
        return _buildCard(context, transferCtrl);
      });
    });
  }
}
