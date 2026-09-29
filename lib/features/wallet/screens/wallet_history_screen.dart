import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/features/order_transaction/controllers/order_transaction_controller.dart';
import 'package:quiksee_vendor_app/features/order_transaction/widgets/order_transaction_card_widget.dart';
import 'package:quiksee_vendor_app/features/transaction/controllers/transaction_controller.dart';
import 'package:quiksee_vendor_app/features/transaction/screens/transaction_screen.dart';
import 'package:quiksee_vendor_app/features/transaction/widgets/transaction_shimmer_widget.dart';
import 'package:quiksee_vendor_app/features/transaction/widgets/transaction_widget.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class WalletHistoryScreen extends StatefulWidget {
  final int initialTabIndex;
  const WalletHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _orderSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTabIndex.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderTransactionController>(context, listen: false).clearFilters(reload: false);
      Provider.of<OrderTransactionController>(context, listen: false).getReport(reset: true);
      Provider.of<TransactionController>(context, listen: false).getTransactionList(context, 'all', '', '');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: QuikseeBrandColors.forestGreen,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: QuikseeAppBarWidget(
          title: getTranslated('total_transactions', context) ?? 'Total Transactions',
          useQuikseeBrandedHeader: true,
        ),
        body: Column(
          children: [
            Container(
              color: Theme.of(context).cardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: QuikseeBrandColors.forestGreen,
                unselectedLabelColor: Theme.of(context).hintColor,
                indicatorColor: QuikseeBrandColors.forestGreen,
                labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                unselectedLabelStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                tabs: [
                  Tab(text: getTranslated('order_details', context) ?? 'Order Details'),
                  Tab(text: getTranslated('withdrawal_transactions', context) ?? 'Withdrawal'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrderDetailsTab(searchController: _orderSearchController),
                  const _WithdrawalTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailsTab extends StatelessWidget {
  final TextEditingController searchController;
  const _OrderDetailsTab({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderTransactionController>(
      builder: (context, controller, _) {
        final rows = controller.report?.transactions ?? [];
        final total = controller.report?.totalSize ?? 0;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeDefault,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: getTranslated('search_by_order_id', context) ?? 'Search by order id',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (value) => controller.setSearch(value, reload: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 42,
                    child: QuikseeButtonWidget(
                      btnTxt: getTranslated('search', context) ?? 'Search',
                      onTap: () => controller.setSearch(searchController.text, reload: true),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: controller.startDate == null
                          ? (getTranslated('from', context) ?? 'From')
                          : controller.displayDateFormat.format(controller.startDate!),
                      onTap: () => controller.selectDate('start', context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateChip(
                      label: controller.endDate == null
                          ? (getTranslated('to', context) ?? 'To')
                          : controller.displayDateFormat.format(controller.endDate!),
                      onTap: () => controller.selectDate('end', context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: QuikseeButtonWidget(
                      btnTxt: getTranslated('filter', context) ?? 'Filter',
                      onTap: () => controller.getReport(reset: true),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${getTranslated('order_details', context) ?? 'Order Details'} ($total)',
                      style: robotoMedium.copyWith(color: Theme.of(context).hintColor),
                    ),
                    if ((controller.report?.totalAdminCommission ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${getTranslated('commission_given', context) ?? 'Commission Given'}: ${PriceConverter.convertPriceForWithdraw(context, controller.report!.totalAdminCommission)}',
                        style: robotoBold.copyWith(
                          color: QuikseeBrandColors.forestGreen,
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: controller.isLoading && controller.report == null
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                      ? const NoDataScreen()
                      : RefreshIndicator(
                          onRefresh: () => controller.getReport(reset: true),
                          child: ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, index) => OrderTransactionCardWidget(row: rows[index]),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _WithdrawalTab extends StatelessWidget {
  const _WithdrawalTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionController>(
      builder: (context, transactionProvider, child) {
        return Column(
          children: [
            SizedBox(
              height: 65,
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: const [
                  TransactionTypeButton(text: 'all', index: 0),
                  TransactionTypeButton(text: 'pending', index: 1),
                  TransactionTypeButton(text: 'approved', index: 2),
                  TransactionTypeButton(text: 'denied', index: 3),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                0,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: transactionProvider.filterStartDate == null
                          ? (getTranslated('from', context) ?? 'From')
                          : transactionProvider.displayDateFormat.format(transactionProvider.filterStartDate!),
                      onTap: () => transactionProvider.pickFilterDate(context, 'start'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateChip(
                      label: transactionProvider.filterEndDate == null
                          ? (getTranslated('to', context) ?? 'To')
                          : transactionProvider.displayDateFormat.format(transactionProvider.filterEndDate!),
                      onTap: () => transactionProvider.pickFilterDate(context, 'end'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 40,
                    child: QuikseeButtonWidget(
                      btnTxt: getTranslated('filter', context) ?? 'Filter',
                      onTap: () => transactionProvider.applyDateFilter(context),
                    ),
                  ),
                ],
              ),
            ),
            if (transactionProvider.filterStartDate != null || transactionProvider.filterEndDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => transactionProvider.clearDateFilters(reload: true, context: context),
                  child: Text(
                    getTranslated('clear', context) ?? 'Clear dates',
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: transactionProvider.transactionList != null
                  ? transactionProvider.transactionList!.isNotEmpty
                      ? RefreshIndicator(
                          onRefresh: () => transactionProvider.applyDateFilter(context),
                          child: ListView.builder(
                            itemCount: transactionProvider.transactionList!.length,
                            itemBuilder: (context, index) => TransactionWidget(
                              transactionModel: transactionProvider.transactionList![index],
                            ),
                          ),
                        )
                      : const NoDataScreen()
                  : const TransactionShimmerWidget(),
            ),
          ],
        );
      },
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).cardColor,
        ),
        child: Text(label, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
      ),
    );
  }
}
