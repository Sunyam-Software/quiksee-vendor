import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_single_child_list_widget.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee/features/wallet/domain/models/transaction_type_model.dart';
import 'package:quiksee/helper/color_helper.dart';
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/sliver_deligate_widget.dart';
import 'package:quiksee/features/wallet/widgets/deposited_list_view_widget.dart';
import 'package:quiksee/features/wallet/widgets/transaction_list_view_widget.dart';
import 'package:quiksee/features/wallet/widgets/transaction_search_filter_widget.dart';
import 'package:quiksee/features/wallet/widgets/transaction_type_card_widget.dart';
import 'package:quiksee/features/wallet/widgets/wallet_bank_info_widget.dart';
import 'package:quiksee/features/wallet/widgets/wallet_withdraw_send_card_widget.dart';
import 'package:quiksee/features/withdraw/widgets/withdraw_list_view_widget.dart';

class WalletScreen extends StatefulWidget {
  final bool fromNotification;
  final int? selectedIndex;
  final bool fromProfile;

  const WalletScreen({super.key, required this.fromNotification, this.selectedIndex, this.fromProfile = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLeaving = false;

  @override
  void initState() {
    final walletController = Get.find<WalletController>();
    final profileController = Get.find<ProfileController>();

    walletController.selectDate(isUpdate: false);
    walletController.getOrderWiseDeliveryCharge('', '', 1, '', isUpdate: false);
    profileController.refreshWalletBalances(includeWalletLists: true);

    if (widget.fromNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        profileController.refreshWalletBalances(includeWalletLists: true);
        walletController.selectedItemForFilter(
          widget.selectedIndex ?? 0,
          fromTop: true,
          fromNotification: true,
        );
      });
    }

    super.initState();
  }

  Future<void> _leaveWallet() async {
    if (_isLeaving) return;
    _isLeaving = true;

    // Sync first so dashboard shows fresh pending/withdrawable after leave.
    Get.find<ProfileController>().syncDashboardWalletOnReturn();

    // PopScope(canPop: false) blocks Get.back(), so leave with explicit navigation.
    if (widget.fromProfile) {
      Get.off(() => const DashboardScreen(pageIndex: 3));
    } else {
      Get.off(() => const DashboardScreen(pageIndex: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_leaveWallet());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: QuikseeAppBarWidget(title: 'my_wallet'.tr,
          isBack: true,
          onTap: () => unawaited(_leaveWallet()),
        ),
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: SliverDelegateWidget(
                  containerHeight: 200,
                  child: const WalletSendWithdrawCardWidget(),
                ),
              ),

              const SliverToBoxAdapter(
                child: WalletBankInfoWidget(),
              ),

              SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.rememberMeSizeDefault),
                  child: GetBuilder<WalletController>(
                    builder: (walletController) {
                      return GetBuilder<ProfileController>(
                        builder: (profileController) {

                          final profile = profileController.profileModel;

                          final List<TransactionTypeModel> transactionTypes = [
                            TransactionTypeModel(Images.delivery, 'delivery_charge_earned', profile?.totalEarn ?? 0, 0),
                            TransactionTypeModel(Images.withdrawn, 'withdrawn', profile?.totalWithdraw ?? 0, 1),
                            TransactionTypeModel(Images.pendingWithdraw, 'pending_withdrawn', profile?.pendingWithdraw ?? 0, 2),
                            TransactionTypeModel(Images.deposit, 'already_deposited', profile?.totalDeposit ?? 0, 3),
                          ];

                          String title = transactionTypes[walletController.selectedItem].title;

                          return Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              QuikseeSingleChildListWidget(
                                scrollDirection: Axis.horizontal,
                                itemCount: transactionTypes.length,
                                itemBuilder: (int index) {
                                  return GestureDetector(
                                    onTap: () {
                                      walletController.selectedItemForFilter(index, fromTop: true);
                                    },
                                    child: Padding(padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                                      child: TransactionCardWidget(
                                        transactionTypeModel: transactionTypes[index],
                                        selectedIndex: walletController.selectedItem,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const DeliverySearchFilterWidget(fromOrderHistory: false),

                              Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                                child: Text(title.tr,
                                  style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge,
                                    color: (Get.find<ThemeController>().darkTheme ? ColorHelper.blendColors(Colors.white, Theme.of(context).primaryColor, 0.9) : ColorHelper.darken(Theme.of(context).primaryColor, 0.1))),
                                ),
                              ),

                              walletController.selectedItem == 0
                                  ? const TransactionListViewWidget()
                                  : walletController.selectedItem == 3
                                  ? const DepositedListViewWidget()
                                  : const WithdrawListViewWidget(),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}