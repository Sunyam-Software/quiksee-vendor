import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee_vendor_app/features/order_transaction/controllers/order_transaction_controller.dart';
import 'package:quiksee_vendor_app/features/order_transaction/widgets/wallet_order_transaction_list_widget.dart';
import 'package:quiksee_vendor_app/features/profile/controllers/profile_controller.dart';
import 'package:quiksee_vendor_app/features/transaction/controllers/transaction_controller.dart';
import 'package:quiksee_vendor_app/features/transaction/widgets/transaction_widget.dart';
import 'package:quiksee_vendor_app/features/wallet/controllers/wallet_controller.dart';
import 'package:quiksee_vendor_app/features/wallet/screens/wallet_history_screen.dart';
import 'package:quiksee_vendor_app/features/wallet/widgets/wallet_card_widget.dart';
import 'package:quiksee_vendor_app/features/wallet/widgets/withdraw_balance_widget.dart';
import 'package:quiksee_vendor_app/helper/color_helper.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class WalletScreen extends StatefulWidget {
  final bool fromNotification;
  const WalletScreen({super.key, this.fromNotification = false});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  int _historyTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<ProfileController>(context, listen: false).getSellerInfo();
      if (!mounted) return;
      await Provider.of<WalletController>(context, listen: false).getPaymentInfoList();
      if (!mounted) return;
      await Provider.of<OrderTransactionController>(context, listen: false).getReport(reset: true, limit: 10);
      if (!mounted) return;
      await Provider.of<TransactionController>(context, listen: false).getTransactionList(context, 'all', '', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (widget.fromNotification) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
            builder: (BuildContext context) => const DashboardScreen(),
          ), (route) => false);
        } else {
          if (!didPop) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: QuikseeAppBarWidget(
          useQuikseeBrandedHeader: true,
          title: getTranslated('wallet', context),
          onBackPressed: () {
            if (widget.fromNotification) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (BuildContext context) => const DashboardScreen()));
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<ProfileController>(context, listen: false).getSellerInfo();
            await Provider.of<OrderTransactionController>(context, listen: false).getReport(reset: true, limit: 10);
            await Provider.of<TransactionController>(context, listen: false).getTransactionList(context, 'all', '', '');
          },
          color: Theme.of(context).cardColor,
          backgroundColor: Theme.of(context).primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: Column(children: [
                    Consumer<ProfileController>(
                      builder: (context, seller, child) {
                        return seller.userInfoModel == null
                            ? const SizedBox()
                            : Column(children: [
                                const WithdrawBalanceWidget(),
                                Container(
                                  margin: const EdgeInsets.all(Dimensions.fontSizeSmall).copyWith(right: 0, top: Dimensions.paddingSizeDefault),
                                  height: 76,
                                  child: ListView(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      WalletCardWidget(
                                        amount: PriceConverter.convertPriceForWithdraw(
                                          context,
                                          seller.userInfoModel!.wallet?.withdrawn ?? 0,
                                        ),
                                        title: '${getTranslated('withdrawn', context)}',
                                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                                      ),
                                      WalletCardWidget(
                                        amount: PriceConverter.convertPriceForWithdraw(
                                          context,
                                          seller.userInfoModel!.wallet?.pendingWithdraw ?? 0,
                                        ),
                                        title: '${getTranslated('pending_withdrawn', context)}',
                                        color: Theme.of(context).colorScheme.surfaceTint,
                                      ),
                                      Consumer<OrderTransactionController>(
                                        builder: (context, orderTx, _) {
                                          final walletCommission = seller.userInfoModel!.wallet?.commissionGiven ?? 0;
                                          final commissionTotal = orderTx.report != null
                                              ? orderTx.report!.totalAdminCommission
                                              : walletCommission;
                                          return WalletCardWidget(
                                            amount: PriceConverter.convertPriceForWithdraw(context, commissionTotal),
                                            title: '${getTranslated('commission_given', context)}',
                                            color: ColorHelper.darken(Theme.of(context).colorScheme.tertiary, 0.1),
                                          );
                                        },
                                      ),
                                      WalletCardWidget(
                                        amount: PriceConverter.convertPriceForWithdraw(
                                          context,
                                          seller.userInfoModel!.wallet?.deliveryChargeEarned ?? 0,
                                        ),
                                        title: '${getTranslated('delivery_charge_earned', context)}',
                                        color: ColorHelper.darken(Theme.of(context).colorScheme.outline, 0.18),
                                      ),
                                      WalletCardWidget(
                                        amount: PriceConverter.convertPriceForWithdraw(
                                          context,
                                          seller.userInfoModel!.wallet?.collectedCash ?? 0,
                                        ),
                                        title: '${getTranslated('collected_cash', context)}',
                                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                                      ),
                                      WalletCardWidget(
                                        amount: PriceConverter.convertPriceForWithdraw(
                                          context,
                                          seller.userInfoModel!.wallet?.totalTaxCollected ?? 0,
                                        ),
                                        title: '${getTranslated('total_collected_tax', context)}',
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                      },
                    ),
                    _HistoryTabBar(
                      selectedIndex: _historyTabIndex,
                      onChanged: (index) => setState(() => _historyTabIndex = index),
                      onViewAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WalletHistoryScreen(initialTabIndex: _historyTabIndex),
                        ),
                      ),
                    ),
                    if (_historyTabIndex == 0)
                      const WalletOrderTransactionListWidget(limit: 10)
                    else
                      const _WalletWithdrawPreviewList(limit: 10),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onViewAll;

  const _HistoryTabBar({
    required this.selectedIndex,
    required this.onChanged,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeMedium,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeMedium,
        Dimensions.paddingSizeSmall,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniTab(
                  label: getTranslated('order_details', context) ?? 'Order Details',
                  selected: selectedIndex == 0,
                  onTap: () => onChanged(0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniTab(
                  label: getTranslated('withdrawal_transactions', context) ?? 'Withdrawal',
                  selected: selectedIndex == 1,
                  onTap: () => onChanged(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getTranslated('view_all', context)!,
                    style: robotoBold.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeVeryTiny),
                  Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onSecondary, size: Dimensions.paddingSize),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? QuikseeBrandColors.forestGreen : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? QuikseeBrandColors.forestGreen
                : Theme.of(context).hintColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }
}

class _WalletWithdrawPreviewList extends StatelessWidget {
  final int limit;
  const _WalletWithdrawPreviewList({this.limit = 10});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionController>(
      builder: (context, provider, _) {
        if (provider.transactionList == null) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          );
        }
        if (provider.transactionList!.isEmpty) {
          return const NoDataScreen();
        }
        final count = provider.transactionList!.length.clamp(0, limit);
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          itemBuilder: (context, index) => TransactionWidget(
            transactionModel: provider.transactionList![index],
          ),
        );
      },
    );
  }
}
