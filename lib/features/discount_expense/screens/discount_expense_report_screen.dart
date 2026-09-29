import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee_vendor_app/common/basewidgets/no_data_screen.dart';
import 'package:quiksee_vendor_app/features/discount_expense/controllers/discount_expense_controller.dart';
import 'package:quiksee_vendor_app/features/discount_expense/domain/models/discount_expense_model.dart';
import 'package:quiksee_vendor_app/features/vat_management/widgets/gst_report_stat_card_widget.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/images.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class DiscountExpenseReportScreen extends StatefulWidget {
  const DiscountExpenseReportScreen({super.key});

  @override
  State<DiscountExpenseReportScreen> createState() => _DiscountExpenseReportScreenState();
}

class _DiscountExpenseReportScreenState extends State<DiscountExpenseReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DiscountExpenseController>(context, listen: false).clearFilters(reload: false);
      Provider.of<DiscountExpenseController>(context, listen: false).getReport(reset: true);
    });
  }

  String _typeLabel(BuildContext context, String key) {
    switch (key) {
      case 'product_discount':
        return getTranslated('product_discount', context) ?? 'Product Discount';
      case 'sale_discount':
        return getTranslated('sale_clearance_discount', context) ?? 'Sale / Clearance';
      case 'coupon_discount':
        return getTranslated('coupon_discount', context) ?? 'Coupon Discount';
      default:
        return getTranslated('all', context) ?? 'All';
    }
  }

  String _bearerSideLabel(BuildContext context, DiscountExpenseRow row) {
    final label = (row.bearerLabel ?? '').trim();
    if (label.isNotEmpty) {
      return '$label side';
    }
    if (row.isAdminSide) {
      return getTranslated('admin_side', context) ?? 'Admin side';
    }
    return getTranslated('vendor_side', context) ?? 'Vendor side';
  }

  String _formatRowDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM yyyy, h:mm a').format(dt);
    } catch (_) {
      return raw;
    }
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
          title: getTranslated('my_discounts_and_sales', context) ?? 'My Discounts & Sales',
          useQuikseeBrandedHeader: true,
        ),
        body: Consumer<DiscountExpenseController>(
          builder: (context, controller, _) {
            final report = controller.report;
            final totals = report?.totals ?? DiscountExpenseTotals();

            return Column(
              children: [
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: DiscountExpenseController.typeKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final key = DiscountExpenseController.typeKeys[index];
                      final selected = controller.selectedType == key;
                      return InkWell(
                        onTap: () => controller.setType(key),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? QuikseeBrandColors.forestGreen
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? QuikseeBrandColors.forestGreen
                                  : Theme.of(context).hintColor.withValues(alpha: 0.3),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _typeLabel(context, key),
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
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
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Row(
                    children: [
                      Expanded(
                        child: GstReportStatCardWidget(
                          image: Images.expenseReportIcon,
                          amount: PriceConverter.convertPrice(context, totals.all),
                          label: getTranslated('total_vendor_expense', context) ?? 'Total Expense',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GstReportStatCardWidget(
                          image: Images.discountAlertIcon,
                          amount: PriceConverter.convertPrice(context, totals.productDiscount),
                          label: getTranslated('product_discount', context) ?? 'Product Discount',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Row(
                    children: [
                      Expanded(
                        child: GstReportStatCardWidget(
                          image: Images.clearanceSaleImage,
                          amount: PriceConverter.convertPrice(context, totals.saleDiscount),
                          label: getTranslated('sale_clearance_discount', context) ?? 'Sale Discount',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GstReportStatCardWidget(
                          image: Images.couponIcon,
                          amount: PriceConverter.convertPrice(context, totals.couponDiscount),
                          label: getTranslated('coupon_discount', context) ?? 'Coupon Discount',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Expanded(
                  child: controller.isLoading && report == null
                      ? const Center(child: CircularProgressIndicator())
                      : (report == null || report.rows.isEmpty)
                          ? const NoDataScreen()
                          : RefreshIndicator(
                              onRefresh: () => controller.getReport(reset: true),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  Dimensions.paddingSizeDefault,
                                  0,
                                  Dimensions.paddingSizeDefault,
                                  Dimensions.paddingSizeDefault,
                                ),
                                itemCount: report.rows.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final row = report.rows[index];
                                  return Container(
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '#${row.orderId ?? ''}',
                                                style: robotoBold.copyWith(
                                                  color: QuikseeBrandColors.forestGreen,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              PriceConverter.convertPrice(context, row.amount),
                                              style: robotoBold.copyWith(
                                                fontSize: Dimensions.fontSizeLarge,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatRowDate(row.date),
                                          style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: QuikseeBrandColors.forestGreen.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                row.typeLabel?.isNotEmpty == true
                                                    ? row.typeLabel!
                                                    : _typeLabel(context, row.type ?? 'all'),
                                                style: robotoMedium.copyWith(
                                                  fontSize: Dimensions.fontSizeSmall,
                                                  color: QuikseeBrandColors.forestGreen,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: row.isAdminSide
                                                    ? Colors.blue.withValues(alpha: 0.12)
                                                    : Colors.orange.withValues(alpha: 0.14),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _bearerSideLabel(context, row),
                                                style: robotoMedium.copyWith(
                                                  fontSize: Dimensions.fontSizeSmall,
                                                  color: row.isAdminSide
                                                      ? Colors.blue.shade800
                                                      : Colors.orange.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if ((row.title ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            row.title!,
                                            style: robotoMedium.copyWith(
                                              fontSize: Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                        ],
                                        if ((row.code ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${getTranslated('code', context) ?? 'Code'}: ${row.code}',
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                        ],
                                        if ((row.note ?? '').isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            row.note!,
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: Theme.of(context).hintColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
