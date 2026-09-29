import 'package:quiksee_vendor_app/features/vat_management/domain/models/vat_report_model.dart';

class GstTaxHelper {
  static List<TaxItem> taxItemsFrom(OrderTransactions? tx) {
    final items = <TaxItem>[];
    for (final group in tx?.vatAmountFormats?.allVatGroups ?? []) {
      items.addAll(group.data ?? []);
    }
    if (items.isNotEmpty) return items;

    for (final tax in tx?.orderTaxes ?? []) {
      items.add(TaxItem(
        name: tax.taxName ?? tax.tax?.name ?? 'GST',
        taxRate: tax.taxRate ?? tax.tax?.taxRate,
        totalAmount: tax.beforeTaxAmount,
        taxAmount: tax.taxAmount,
      ));
    }
    return items;
  }

  static double totalRate(List<TaxItem> items) {
    return items.fold<double>(0, (sum, item) => sum + (item.taxRate ?? 0));
  }

  static String taxLineLabel(TaxItem tax) {
    final rate = tax.taxRate ?? 0;
    final formatted = formatRate(rate);
    final name = tax.name.trim();
    if (name.contains('(') && name.contains('%')) return name;
    if (RegExp(r'\d').hasMatch(name)) return '$name ($formatted%)';
    return '$name $formatted ($formatted%)';
  }

  static String formatRate(double rate) {
    if (rate == rate.roundToDouble()) return rate.toInt().toString();
    final text = rate.toStringAsFixed(2);
    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
