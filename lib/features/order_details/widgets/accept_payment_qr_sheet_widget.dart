import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// COD Accept Payment: show a local UPI QR instantly, then upgrade to Razorpay
/// QR + auto-verify poll when the server responds (or from prefetch cache).
class AcceptPaymentQrSheetWidget extends StatefulWidget {
  final double? amount;
  final int? orderId;

  const AcceptPaymentQrSheetWidget({
    super.key,
    this.amount,
    this.orderId,
  });

  static void prefetch({int? orderId, double? amount}) {
    if (orderId == null || orderId <= 0) return;
    if (!Get.isRegistered<OrderDetailsController>()) return;
    Get.find<OrderDetailsController>().prefetchCodUpiQr(
      orderId,
      collectAmount: amount,
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    double? amount,
    int? orderId,
  }) {
    // Kick / reuse create before sheet animation so QR is often ready on open.
    prefetch(orderId: orderId, amount: amount);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: AcceptPaymentQrSheetWidget(
            amount: amount,
            orderId: orderId,
          ),
        );
      },
    );
  }

  @override
  State<AcceptPaymentQrSheetWidget> createState() =>
      _AcceptPaymentQrSheetWidgetState();
}

class _AcceptPaymentQrSheetWidgetState
    extends State<AcceptPaymentQrSheetWidget> {
  bool _loadingQr = true;
  bool _fetchingRazorpay = false;
  bool _busy = false;
  bool _manualChecking = false;
  bool _paid = false;
  bool _localUpiFallback = false;
  String? _error;
  String? _imageUrl;
  String? _localUpiPayload;
  String? _transactionId;
  double? _qrAmount;
  Timer? _pollTimer;
  bool _pollingInFlight = false;
  bool _pollingActive = false;
  int _pollAttempt = 0;
  bool _pausedBackground = false;

  @override
  void initState() {
    super.initState();
    _pauseCompetingTraffic();
    _bootstrap();
  }

  @override
  void dispose() {
    _stopPolling();
    _resumeCompetingTraffic();
    super.dispose();
  }

  void _pauseCompetingTraffic() {
    if (_pausedBackground) return;
    _pausedBackground = true;
    if (Get.isRegistered<OrderDetailsController>()) {
      Get.find<OrderDetailsController>().setAcceptPaymentSheetOpen(true);
    }
    if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().pauseBackgroundSync();
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().pauseBackgroundOrderPolls();
    }
    if (Get.isRegistered<OrderTransferController>()) {
      Get.find<OrderTransferController>().stopIncomingOfferWatch();
    }
  }

  void _resumeCompetingTraffic() {
    if (!_pausedBackground) return;
    _pausedBackground = false;
    if (Get.isRegistered<OrderDetailsController>()) {
      Get.find<OrderDetailsController>().setAcceptPaymentSheetOpen(false);
    }
    if (Get.isRegistered<AssignmentController>()) {
      Get.find<AssignmentController>().resumeBackgroundSync();
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().resumeBackgroundOrderPolls();
    }
    if (Get.isRegistered<OrderTransferController>()) {
      Get.find<OrderTransferController>().startIncomingOfferWatch();
    }
  }

  String _buildLocalUpiPayload({required double amount, required int orderId}) {
    final am = amount.toStringAsFixed(2);
    final tn = Uri.encodeComponent('QuikSee Order $orderId');
    final pn = Uri.encodeComponent(AppConstants.codUpiPayeeName);
    final pa = Uri.encodeComponent(AppConstants.codUpiVpa);
    return 'upi://pay?pa=$pa&pn=$pn&am=$am&cu=INR&tn=$tn';
  }

  void _useLocalUpiFallback({String? reason}) {
    final orderId = widget.orderId;
    final amount = _qrAmount ?? widget.amount;
    if (orderId == null ||
        orderId <= 0 ||
        amount == null ||
        amount <= 0 ||
        AppConstants.codUpiVpa.trim().isEmpty) {
      setState(() {
        _loadingQr = false;
        _fetchingRazorpay = false;
        _localUpiFallback = false;
        _error = reason?.isNotEmpty == true
            ? reason
            : 'Unable to create UPI QR. Check Razorpay config or try cash.';
      });
      return;
    }

    _stopPolling();
    setState(() {
      _loadingQr = false;
      _fetchingRazorpay = false;
      _localUpiFallback = true;
      _error = null;
      _imageUrl = null;
      _qrAmount = amount;
      _localUpiPayload ??=
          _buildLocalUpiPayload(amount: amount, orderId: orderId);
    });
  }

  Future<void> _bootstrap() async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0) {
      setState(() {
        _loadingQr = false;
        _error = 'invalid_order';
      });
      return;
    }

    final ctrl = Get.find<OrderDetailsController>();

    final cached = ctrl.peekCodUpiQrCache(
      orderId,
      collectAmount: widget.amount,
    );
    if (cached != null) {
      final imageUrl = cached['image_url']?.toString() ??
          cached['qr_image_url']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          _loadingQr = false;
          _fetchingRazorpay = false;
          _localUpiFallback = false;
          _error = null;
          _imageUrl = imageUrl;
          _qrAmount =
              (cached['amount'] as num?)?.toDouble() ?? widget.amount;
        });
        _startPolling();
        return;
      }
    }

    if (ctrl.isCodPaymentCollected(orderId)) {
      _closeSheetPaid();
      return;
    }

    _showPreparingRazorpay();
    if (_error != null) return;

    _startPolling();
    unawaited(_loadRazorpayQr(orderId));
  }

  void _showPreparingRazorpay() {
    setState(() {
      _loadingQr = false;
      _fetchingRazorpay = true;
      _localUpiFallback = false;
      _error = null;
      _imageUrl = null;
      _qrAmount = widget.amount;
    });
  }

  Future<void> _loadRazorpayQr(int orderId) async {
    final ctrl = Get.find<OrderDetailsController>();
    final map = await ctrl.ensureCodUpiQrReady(
      orderId,
      collectAmount: widget.amount,
    );
    if (!mounted || _paid) return;

    if (map == null) {
      _useLocalUpiFallback();
      return;
    }

    await _applyRazorpayQrMap(map);
  }

  Future<void> _applyRazorpayQrMap(Map<String, dynamic> data) async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0) return;

    if (data['status'] == false) {
      final msg = data['message']?.toString();
      _useLocalUpiFallback(reason: msg);
      return;
    }

    if (data['paid'] == true) {
      final ctrl = Get.find<OrderDetailsController>();
      if (!ctrl.isCodPaymentCollected(orderId)) {
        await ctrl.pollCodUpiQrStatus(orderId, showSnack: false);
      }
      if (!mounted) return;
      if (ctrl.isCodPaymentCollected(orderId)) {
        _closeSheetPaid();
      }
      return;
    }

    final imageUrl =
        data['image_url']?.toString() ?? data['qr_image_url']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      final msg = data['message']?.toString();
      _useLocalUpiFallback(reason: msg);
      return;
    }

    if (mounted) {
      unawaited(
        precacheImage(CachedNetworkImageProvider(imageUrl), context),
      );
    }

    setState(() {
      _fetchingRazorpay = false;
      _localUpiFallback = false;
      _imageUrl = imageUrl;
      _qrAmount = (data['amount'] as num?)?.toDouble() ?? widget.amount;
      _error = null;
    });
  }

  Duration _nextPollDelay(int attempt) {
    if (attempt < 120) return const Duration(milliseconds: 300);
    if (attempt < 180) return const Duration(milliseconds: 600);
    return const Duration(milliseconds: 1200);
  }

  void _startPolling() {
    if (_pollingActive || _localUpiFallback || _paid) return;
    _pollingActive = true;
    _pollTimer?.cancel();
    _pollAttempt = 0;
    unawaited(_runPollCycle());
  }

  Future<void> _runPollCycle() async {
    if (!mounted || !_pollingActive || _paid || _localUpiFallback) return;

    _pollAttempt++;
    final ok = await _pollOnce();
    if (!mounted || ok || _paid || _localUpiFallback || !_pollingActive) return;

    _pollTimer?.cancel();
    _pollTimer = Timer(_nextPollDelay(_pollAttempt), () {
      unawaited(_runPollCycle());
    });
  }

  void _stopPolling() {
    _pollingActive = false;
    _pollTimer?.cancel();
  }

  void _closeSheetPaid() {
    if (!mounted || _paid) return;
    _paid = true;
    _stopPolling();
    Navigator.of(context).pop(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showQuikseeSnackBarWidget(
        'payment_received_successfully'.tr,
        isError: false,
      );
    });
  }

  Future<bool> _pollOnce() async {
    if (!mounted ||
        _paid ||
        _pollingInFlight ||
        _localUpiFallback ||
        !_pollingActive ||
        _manualChecking) {
      return false;
    }
    final orderId = widget.orderId;
    if (orderId == null) return false;

    _pollingInFlight = true;
    try {
      final ok = await Get.find<OrderDetailsController>().pollCodUpiQrStatus(
        orderId,
        showSnack: false,
        sync: false,
      );
      if (!mounted) return false;
      if (ok) {
        _closeSheetPaid();
        return true;
      }
      return false;
    } finally {
      _pollingInFlight = false;
    }
  }

  Future<void> _onCollectedCash() async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0 || _busy) return;
    setState(() => _busy = true);
    try {
      final ok =
          await Get.find<OrderDetailsController>().markCodCashCollected(orderId);
      if (!mounted) return;
      if (ok) {
        _stopPolling();
        if (mounted) Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onConfirmLocalUpiReceived() async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0 || _busy) return;
    setState(() => _busy = true);
    try {
      await Get.find<OrderDetailsController>()
          .confirmCodPaymentPaidOptimistic(orderId);
      if (!mounted) return;
      _closeSheetPaid();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onCheckPayment() async {
    final orderId = widget.orderId;
    if (orderId == null || orderId <= 0 || _manualChecking || _paid) return;

    final ctrl = Get.find<OrderDetailsController>();
    if (ctrl.isCodPaymentCollected(orderId)) {
      _closeSheetPaid();
      return;
    }

    setState(() => _manualChecking = true);
    _stopPolling();
    try {
      final ok = await ctrl.forceVerifyCodPayment(orderId);
      if (!mounted) return;
      if (ok) {
        _closeSheetPaid();
      } else {
        showQuikseeSnackBarWidget(
          'upi_payment_not_verified_yet'.tr.isEmpty
              ? 'Payment not verified yet. Ask customer to complete UPI scan, then tap again.'
              : 'upi_payment_not_verified_yet'.tr,
        );
        if (!_paid && !_localUpiFallback) {
          _pollAttempt = 0;
          _startPolling();
        }
      }
    } finally {
      if (mounted) setState(() => _manualChecking = false);
    }
  }

  Widget _buildLocalQrCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: QrImageView(
            data: _localUpiPayload!,
            version: QrVersions.auto,
            size: 240,
            backgroundColor: Colors.white,
          ),
        ),
        SizedBox(height: Dimensions.paddingSizeSmall),
        Text(
          'Pay to ${AppConstants.codUpiPayeeName}\n${AppConstants.codUpiVpa}',
          textAlign: TextAlign.center,
          style: rubikRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQrVisual() {
    if (_fetchingRazorpay && !_localUpiFallback) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
            SizedBox(height: 12),
            Text(
              'Preparing Razorpay QR…',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final useRazorpay =
        !_localUpiFallback && _imageUrl != null && _imageUrl!.isNotEmpty;

    if (useRazorpay) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: CachedNetworkImage(
          imageUrl: _imageUrl!,
          width: 240,
          height: 240,
          fit: BoxFit.contain,
          placeholder: (_, __) => const SizedBox(
            width: 240,
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) {
            if (_localUpiPayload != null && _localUpiPayload!.isNotEmpty) {
              return QrImageView(
                data: _localUpiPayload!,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
              );
            }
            return const SizedBox(
              height: 240,
              child: Center(child: Text('QR image failed')),
            );
          },
        ),
      );
    }

    if (_localUpiPayload != null && _localUpiPayload!.isNotEmpty) {
      return _buildLocalQrCard();
    }

    return const SizedBox.shrink();
  }

  String _statusHint() {
    if (_localUpiFallback) {
      return 'After customer pays, tap “UPI payment received”. Auto-verify needs server QR.';
    }
    if (_fetchingRazorpay) {
      return 'Preparing Razorpay QR — please wait before customer scans.';
    }
    return 'Waiting for UPI… auto-checking every moment after payment.';
  }

  @override
  Widget build(BuildContext context) {
    final amount = _qrAmount ?? widget.amount;
    final hasAmount = amount != null && amount > 0;
    final hasQr = _localUpiFallback
        ? (_localUpiPayload != null && _localUpiPayload!.isNotEmpty)
        : ((_imageUrl != null && _imageUrl!.isNotEmpty) ||
            _fetchingRazorpay);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeLarge + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'accept_payment'.tr,
            style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            _paid
                ? 'payment_received_successfully'.tr
                : 'scan_qr_to_pay'.tr,
            style: rubikRegular.copyWith(
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasAmount) ...[
            SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              PriceConverter.convertPrice(amount),
              style: rubikBold.copyWith(
                color: Theme.of(context).primaryColor,
                fontSize: Dimensions.fontSizeExtraLarge,
              ),
            ),
          ],
          SizedBox(height: Dimensions.paddingSizeLarge),
          if (_loadingQr)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            )
          else if (_error != null && !hasQr)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    (_error == 'qr_create_failed')
                        ? 'Unable to create UPI QR. Check Razorpay config or try cash.'
                        : _error!,
                    textAlign: TextAlign.center,
                    style: rubikRegular.copyWith(color: Colors.red),
                  ),
                  SizedBox(height: Dimensions.paddingSizeDefault),
                  TextButton(
                    onPressed: _busy ? null : _bootstrap,
                    child: const Text('Retry QR'),
                  ),
                ],
              ),
            )
          else
            _buildQrVisual(),
          if (_transactionId != null && _transactionId!.isNotEmpty) ...[
            SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'Txn: $_transactionId',
              style: rubikRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
          SizedBox(height: Dimensions.paddingSizeDefault),
          if (!_paid)
            Text(
              _statusHint(),
              style: rubikRegular.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: Dimensions.fontSizeSmall,
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: Dimensions.paddingSizeLarge),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            )
          else ...[
            if (!_paid &&
                !_localUpiFallback &&
                _imageUrl != null &&
                _imageUrl!.isNotEmpty)
              QuikseeButtonWidget(
                btnTxt: _manualChecking
                    ? 'Checking payment…'
                    : 'Check payment status',
                onTap: _manualChecking ? null : _onCheckPayment,
              ),
            if (!_paid && _localUpiFallback && hasQr) ...[
              QuikseeButtonWidget(
                btnTxt: 'UPI payment received',
                onTap: _onConfirmLocalUpiReceived,
              ),
              SizedBox(height: Dimensions.paddingSizeSmall),
            ],
            if (!_paid) ...[
              if (!_localUpiFallback)
                SizedBox(height: Dimensions.paddingSizeSmall),
              QuikseeButtonWidget(
                btnTxt: 'Collected cash instead',
                isShowBorder: true,
                onTap: _onCollectedCash,
              ),
            ],
            SizedBox(height: Dimensions.paddingSizeSmall),
            QuikseeButtonWidget(
              btnTxt: 'close'.tr,
              isShowBorder: true,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ],
      ),
    );
  }
}
