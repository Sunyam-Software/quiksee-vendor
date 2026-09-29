import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

/// Shows store pickup OTP to the rider (tell store owner to confirm).
class FoodPickupOtpCardWidget extends StatefulWidget {
  final OrderModel? orderModel;
  final bool embedded;
  final bool forceShow;
  const FoodPickupOtpCardWidget({
    super.key,
    this.orderModel,
    this.embedded = false,
    this.forceShow = false,
  });

  @override
  State<FoodPickupOtpCardWidget> createState() =>
      _FoodPickupOtpCardWidgetState();
}

class _FoodPickupOtpCardWidgetState extends State<FoodPickupOtpCardWidget> {
  bool _loading = false;
  String? _fetchedCode;
  String? _lastError;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.orderModel?.isAtStoreForPickupOtp == true) {
        unawaited(_ensureCodeLoaded());
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FoodPickupOtpCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCode =
        (oldWidget.orderModel?.pickupVerificationCode ?? '').trim();
    final newCode = (widget.orderModel?.pickupVerificationCode ?? '').trim();
    if (newCode.isEmpty &&
        oldCode.isEmpty &&
        widget.orderModel?.pickupVerificationStatus != 1 &&
        widget.orderModel?.isAtStoreForPickupOtp == true) {
      unawaited(_ensureCodeLoaded());
    }
  }

  bool _configEnabled() {
    if (!Get.isRegistered<SplashController>()) return false;
    return Get.find<SplashController>().configModel?.foodPickupOtp == 1;
  }

  void _startCooldown([int seconds = 45]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _ensureCodeLoaded({bool resend = false}) async {
    final order = widget.orderModel;
    if (order?.id == null) return;
    if (order!.pickupVerificationStatus == 1) return;
    // Admin assign / confirmed: never mint or show OTP until Reach Store/Hub.
    if (!order.isAtStoreForPickupOtp) return;

    final existing = (order.pickupVerificationCode ?? _fetchedCode ?? '').trim();
    if (!resend && existing.isNotEmpty) return;

    if (!Get.isRegistered<ApiClient>()) return;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _lastError = null;
    });
    try {
      final response = await Get.find<ApiClient>().postData(
        AppConstants.pickupOtpUri,
        {
          'order_id': order.id,
          'resend': resend ? 1 : 0,
        },
      );
      if (response.statusCode == 200 && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body as Map);
        final code = body['pickup_verification_code']?.toString().trim();
        if (code != null && code.isNotEmpty && code != 'null') {
          _fetchedCode = code;
          order.pickupVerificationCode = code;
          order.foodPickupOtpEnabled =
              int.tryParse('${body['food_pickup_otp_enabled'] ?? 1}') ?? 1;
          order.pickupOtpRequired =
              int.tryParse('${body['pickup_otp_required'] ?? 1}') ?? 1;
          order.pickupVerificationStatus =
              int.tryParse('${body['pickup_verification_status'] ?? 0}') ?? 0;
          order.canPickup = int.tryParse('${body['can_pickup'] ?? 0}') ?? 0;
          if (Get.isRegistered<OrderController>()) {
            Get.find<OrderController>().applyPickupOtpFields(order);
          }
          if (Get.isRegistered<OrderDetailsController>()) {
            Get.find<OrderDetailsController>().update();
          }
        } else if (int.tryParse('${body['pickup_verification_status']}') == 1) {
          order.pickupVerificationStatus = 1;
          order.pickupOtpRequired = 0;
          order.canPickup = 1;
          order.pickupVerificationCode = null;
          if (Get.isRegistered<OrderDetailsController>()) {
            Get.find<OrderDetailsController>().markPickupOtpVerified(order.id!);
          }
        } else {
          _lastError = body['message']?.toString() ?? 'OTP not available';
        }
        if (resend) {
          final sent = body['sent_sms'] == true || body['sent_sms'] == 1;
          showQuikseeSnackBarWidget(
            sent
                ? 'otp_sent_successfully'.tr
                : (body['message']?.toString() ?? 'pickup_otp_ready'.tr),
            isError: !sent && code == null,
          );
          if (sent) _startCooldown();
        }
      } else {
        _lastError = 'Could not load Pickup OTP';
        if (resend) {
          showQuikseeSnackBarWidget('otp_sent_failed'.tr);
        }
      }
    } catch (_) {
      _lastError = 'Could not load Pickup OTP';
      if (resend) {
        showQuikseeSnackBarWidget('otp_sent_failed'.tr);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _digitBoxes(BuildContext context, String code) {
    final primary = Theme.of(context).primaryColor;
    final chars = code.split('');
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final ch in chars)
                  Container(
                    width: 36,
                    height: 42,
                    margin: const EdgeInsets.only(right: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      ch,
                      style: rubikBold.copyWith(
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
                          tooltip: 'copied'.tr,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            showQuikseeSnackBarWidget('pickup_otp_copied'.tr, isError: false);
          },
          icon: Icon(Icons.copy_rounded, size: 20, color: primary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (_) {
      return GetBuilder<OrderDetailsController>(builder: (_) {
        final order = widget.orderModel;
        if (order == null) return const SizedBox.shrink();

        final verified = order.pickupVerificationStatus == 1 ||
            (Get.isRegistered<OrderDetailsController>() &&
                Get.find<OrderDetailsController>()
                    .isPickupOtpUnlocked(order.id));
        if (verified) {
          _fetchedCode = null;
          return const SizedBox.shrink();
        }
        final code =
            (order.pickupVerificationCode ?? _fetchedCode ?? '').trim();
        final atStore = order.isAtStoreForPickupOtp;

        // Assigned (even by admin) ≠ at hub/store. Hide digits until Reach.
        if (!atStore) return const SizedBox.shrink();

        final featureOn = order.foodPickupOtpEnabled == 1 ||
            order.pickupOtpRequired == 1 ||
            code.isNotEmpty ||
            _configEnabled() ||
            widget.forceShow;
        if (!featureOn) return const SizedBox.shrink();

        if (code.isEmpty && !_loading) {
          unawaited(_ensureCodeLoaded());
        }

        final primary = Theme.of(context).primaryColor;
        final margin = widget.embedded
            ? EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall)
            : EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall);

        return Container(
          width: double.infinity,
          margin: margin,
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'food_pickup_otp'.tr.toUpperCase(),
                          style: rubikBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_loading && code.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else if (code.isNotEmpty) ...[
                          _digitBoxes(context, code),
                          const SizedBox(height: 8),
                          Text(
                            order.isAdminHubPickup
                                ? (order.pickupOtpHint ??
                                    'Show this OTP to admin hub staff (not the vendor shop).')
                                : 'tell_store_owner_this_otp'.tr,
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              height: 1.3,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: (_loading || _resendCooldown > 0)
                                ? null
                                : () => _ensureCodeLoaded(resend: true),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sms_outlined,
                                    size: 16, color: primary),
                                const SizedBox(width: 4),
                                Text(
                                  _loading
                                      ? 'please_wait'.tr
                                      : 'resend_otp_via_sms'.tr,
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            _lastError ?? 'Loading Pickup OTP…',
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 36,
                          color: primary,
                        ),
                      ),
                      if (_resendCooldown > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'resend_in'
                              .trParams({'time': _formatCooldown(_resendCooldown)}),
                          style: rubikMedium.copyWith(
                            fontSize: 11,
                            color: primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      });
    });
  }

  String _formatCooldown(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
