
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/features/withdraw/domain/models/withdraw_model.dart';
import 'package:quiksee/features/withdraw/domain/services/withdraw_service_interface.dart';

class WithdrawController extends GetxController implements GetxService {
  final WithdrawServiceInterface withdrawServiceInterface;
  WithdrawController({required this.withdrawServiceInterface});

  bool _isWithdraw = false;
  bool get isWithdraw => _isWithdraw;
  List<Withdraws> _withdrawList = [];
  List<Withdraws> get withdrawList => _withdrawList;
  bool _isLoading = false;
  bool get isLoading => _isLoading;


  Future<Response> sendWithdrawRequest(String amount, String note) async {
    if (_isWithdraw) {
      return Response(statusCode: 0, statusText: 'in_progress');
    }

    _isWithdraw = true;
    update();
    try {
      final response =
          await withdrawServiceInterface.sendWithdrawRequest(amount: amount, note: note);

      if (response.statusCode == 200) {
        final body = response.body;
        final message = body is Map ? body['message']?.toString() : null;
        final requestedAmount = double.tryParse(amount) ?? 0;
        if (requestedAmount > 0) {
          final profileController = Get.find<ProfileController>();
          profileController.applyWithdrawLocally(requestedAmount);
          profileController.update();
        }
        final navigator = Get.key.currentState;
        if (navigator != null && navigator.canPop()) {
          Get.back();
        }
        showQuikseeSnackBarWidget(
          message != null && message.isNotEmpty
              ? message
              : 'send_withdraw_request'.tr,
          isError: false,
        );
        unawaited(_refreshWalletAfterWithdraw());
      }
      return response;
    } finally {
      _isWithdraw = false;
      update();
    }
  }

  Future<void> _refreshWalletAfterWithdraw() async {
    try {
      // Let /info catch up first so optimistic pending is not overwritten by stale data.
      await Future.delayed(const Duration(seconds: 3));
      await Get.find<ProfileController>()
          .refreshWalletBalances(includeWalletLists: true);
      if (!Get.isRegistered<WalletController>()) return;
      Get.find<WalletController>().selectedItemForFilter(2, fromTop: true);
    } catch (e, stack) {
      debugPrint('_refreshWalletAfterWithdraw error: $e\n$stack');
    }
  }


  Future getWithdrawList(String startDate, String endDate, int offset, String type,
      {bool reload = true, bool fromNotification = false, bool skipProfileRefresh = false}) async {
    if (reload) {
      _withdrawList = [];
    }
    _isLoading = true;
    if (!fromNotification) {
      update();
    }
    try {
      final result = await withdrawServiceInterface.getWithdrawList(
        startDate: startDate,
        endDate: endDate,
        offset: offset,
        type: type,
      );
      _withdrawList = result is List<Withdraws> ? result : [];
    } catch (e, stack) {
      debugPrint('getWithdrawList error: $e\n$stack');
      _withdrawList = [];
    } finally {
      _isLoading = false;
      if (!skipProfileRefresh) {
        try {
          await Get.find<ProfileController>().getProfile(
            silent: true,
            skipSideEffects: true,
          );
        } catch (e, stack) {
          debugPrint('getWithdrawList profile refresh error: $e\n$stack');
        }
      }
      update();
    }
  }


}