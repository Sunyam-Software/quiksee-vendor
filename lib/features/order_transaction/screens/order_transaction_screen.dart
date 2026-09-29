import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/features/order_transaction/controllers/order_transaction_controller.dart';
import 'package:quiksee_vendor_app/features/order_transaction/widgets/order_transaction_card_widget.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class OrderTransactionScreen extends StatefulWidget {
  const OrderTransactionScreen({super.key});

  @override
  State<OrderTransactionScreen> createState() => _OrderTransactionScreenState();
}

class _OrderTransactionScreenState extends State<OrderTransactionScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderTransactionController>(context, listen: false).clearFilters(reload: false);
      Provider.of<OrderTransactionController>(context, listen: false).getReport(reset: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        body: Consumer<OrderTransactionController>(
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
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: getTranslated('search_by_order_id', context) ?? 'Search by order id',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (value) {
                            controller.setSearch(value, reload: true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        height: 42,
                        child: QuikseeButtonWidget(
                          btnTxt: getTranslated('search', context) ?? 'Search',
                          onTap: () => controller.setSearch(_searchController.text, reload: true),
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
                          '${getTranslated('total_transactions', context) ?? 'Total Transactions'} ($total)',
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
        ),
      ),
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
