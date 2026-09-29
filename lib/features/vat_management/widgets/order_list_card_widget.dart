import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiksee_vendor_app/features/order_details/screens/order_details_screen.dart';
import 'package:quiksee_vendor_app/features/vat_management/domain/models/gst_tax_helper.dart';
import 'package:quiksee_vendor_app/features/vat_management/domain/models/vat_report_model.dart';
import 'package:quiksee_vendor_app/helper/price_converter.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';

class OrderListCardWidget extends StatelessWidget {
  final OrderTransactions? orderModel;
  const OrderListCardWidget({super.key, this.orderModel});

  bool get _isTaxIncluded =>
      (orderModel?.order?.taxModel ?? '').toLowerCase() == 'include';

  String _taxTypeLabel(BuildContext context) {
    final type = (orderModel?.order?.taxType ?? orderModel?.taxType ?? 'product_wise').toLowerCase();
    return getTranslated(type, context) ?? type.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final created = DateTime.tryParse(orderModel?.createdAt ?? '') ?? DateTime.now();
    final taxItems = GstTaxHelper.taxItemsFrom(orderModel);
    final totalRate = GstTaxHelper.totalRate(taxItems);
    final isPos = (orderModel?.order?.orderType ?? '').toLowerCase() == 'pos';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: QuikseeBrandColors.featuredSectionBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${orderModel?.orderId ?? ''}',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: QuikseeBrandColors.seeTextGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM, yyyy').format(created),
                        style: robotoRegular.copyWith(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPos)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getTranslated('pos', context) ?? 'POS',
                      style: robotoMedium.copyWith(
                        fontSize: 10,
                        color: QuikseeBrandColors.forestGreen,
                      ),
                    ),
                  ),
                Material(
                  color: QuikseeBrandColors.forestGreen,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (orderModel?.orderId == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(orderId: orderModel!.orderId),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labeledValue(
                  context,
                  getTranslated('order_amount_gst_base', context) ?? 'Order Amount (GST Base)',
                  PriceConverter.convertPrice(context, orderModel?.orderAmount),
                ),
                const SizedBox(height: 12),
                Text(
                  getTranslated('gst_type', context) ?? 'GST Type',
                  style: robotoMedium.copyWith(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                if (_isTaxIncluded)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      getTranslated('tax_included', context) ?? 'Tax Included',
                      style: robotoMedium.copyWith(
                        fontSize: 11,
                        color: const Color(0xFF2F6FED),
                      ),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      getTranslated('tax_excluded', context) ?? 'Tax Excluded',
                      style: robotoMedium.copyWith(
                        fontSize: 11,
                        color: const Color(0xFFB26A00),
                      ),
                    ),
                  ),
                Text(
                  _taxTypeLabel(context),
                  style: robotoRegular.copyWith(fontSize: 12, color: Colors.grey.shade800),
                ),
                if (totalRate > 0)
                  Text(
                    '${getTranslated('total', context) ?? 'Total'} (${GstTaxHelper.formatRate(totalRate)}%)',
                    style: robotoRegular.copyWith(fontSize: 12, color: Colors.grey.shade800),
                  ),
                for (final tax in taxItems)
                  Text(
                    GstTaxHelper.taxLineLabel(tax),
                    style: robotoRegular.copyWith(fontSize: 12, color: Colors.grey.shade800),
                  ),
                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Text(
                  getTranslated('gst_amount', context) ?? 'GST Amount',
                  style: robotoMedium.copyWith(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${getTranslated('total', context) ?? 'Total'}: ${PriceConverter.convertPrice(context, orderModel?.tax)}',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: QuikseeBrandColors.seeTextGreen,
                  ),
                ),
                if (taxItems.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${getTranslated('order_tax', context) ?? 'Order Tax'}:',
                    style: robotoMedium.copyWith(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  const SizedBox(height: 2),
                  for (final tax in taxItems)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${GstTaxHelper.taxLineLabel(tax)}: ${PriceConverter.convertPrice(context, tax.taxAmount ?? tax.totalAmount)}',
                        style: robotoRegular.copyWith(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labeledValue(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: robotoMedium.copyWith(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}
