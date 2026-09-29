import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class LoginApprovalDialog extends StatefulWidget {
  final String requestId;
  final String? message;

  const LoginApprovalDialog({
    super.key,
    required this.requestId,
    this.message,
  });

  static Future<void> showIfNeeded({
    required String requestId,
    String? message,
  }) async {
    final ctx = Get.context;
    if (ctx == null || requestId.isEmpty) {
      return;
    }

    if (AuthController.activeLoginApprovalRequestId == requestId) {
      return;
    }
    AuthController.activeLoginApprovalRequestId = requestId;

    try {
      await Provider.of<AuthController>(ctx, listen: false).acknowledgePendingLoginApproval();
    } catch (_) {}

    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => LoginApprovalDialog(
        requestId: requestId,
        message: message,
      ),
    );
    if (AuthController.activeLoginApprovalRequestId == requestId) {
      AuthController.activeLoginApprovalRequestId = null;
    }
  }

  @override
  State<LoginApprovalDialog> createState() => _LoginApprovalDialogState();
}

class _LoginApprovalDialogState extends State<LoginApprovalDialog> {
  bool _busy = false;

  Future<void> _resolve(String action) async {
    if (_busy) return;
    setState(() => _busy = true);

    final auth = Provider.of<AuthController>(context, listen: false);

    try {
      final status = await auth.getLoginApprovalStatus(widget.requestId);
      final current = (status?['status'] ?? '').toString().toLowerCase();
      if (current.isNotEmpty && current != 'pending') {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    } catch (_) {

    }

    await auth.resolveLoginApproval(requestId: widget.requestId, action: action);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.message?.trim().isNotEmpty == true
        ? widget.message!
        : (getTranslated('login_approval_request_body', context) ??
            'Somebody is trying to login to your vendor account. Approve or deny?');

    return AlertDialog(
      title: Text(
        getTranslated('login_approval_request_title', context) ??
            'Login approval needed',
        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
      ),
      content: Text(body, style: robotoRegular),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => _resolve('deny'),
          child: Text(
            getTranslated('no', context) ?? 'No',
            style: robotoMedium.copyWith(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => _resolve('approve'),
          child: Text(
            getTranslated('yes', context) ?? 'Yes',
            style: robotoMedium.copyWith(color: QuikseeBrandColors.seeTextGreen),
          ),
        ),
      ],
    );
  }
}
