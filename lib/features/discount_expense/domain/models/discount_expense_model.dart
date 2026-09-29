class DiscountExpenseTotals {
  final double all;
  final double productDiscount;
  final double saleDiscount;
  final double couponDiscount;

  DiscountExpenseTotals({
    this.all = 0,
    this.productDiscount = 0,
    this.saleDiscount = 0,
    this.couponDiscount = 0,
  });

  factory DiscountExpenseTotals.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return DiscountExpenseTotals(
      all: _toDouble(json['all']),
      productDiscount: _toDouble(json['product_discount']),
      saleDiscount: _toDouble(json['sale_discount']),
      couponDiscount: _toDouble(json['coupon_discount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class DiscountExpenseRow {
  final String? date;
  final int? orderId;
  final String? type;
  final String? typeLabel;
  final double amount;
  final String? title;
  final String? code;
  final String? note;
  final int? qty;
  final String? bearer;
  final String? bearerLabel;

  DiscountExpenseRow({
    this.date,
    this.orderId,
    this.type,
    this.typeLabel,
    this.amount = 0,
    this.title,
    this.code,
    this.note,
    this.qty,
    this.bearer,
    this.bearerLabel,
  });

  bool get isAdminSide => (bearer ?? '').toLowerCase() == 'admin';

  factory DiscountExpenseRow.fromJson(Map<String, dynamic> json) {
    return DiscountExpenseRow(
      date: json['date']?.toString(),
      orderId: json['order_id'] is int
          ? json['order_id']
          : int.tryParse('${json['order_id']}'),
      type: json['type']?.toString(),
      typeLabel: json['type_label']?.toString(),
      amount: DiscountExpenseTotals._toDouble(json['amount']),
      title: json['title']?.toString(),
      code: json['code']?.toString(),
      note: json['note']?.toString(),
      qty: json['qty'] is int ? json['qty'] : int.tryParse('${json['qty'] ?? ''}'),
      bearer: json['bearer']?.toString(),
      bearerLabel: json['bearer_label']?.toString(),
    );
  }
}

class DiscountExpenseReportModel {
  final DiscountExpenseTotals totals;
  final List<DiscountExpenseRow> rows;

  DiscountExpenseReportModel({
    required this.totals,
    required this.rows,
  });

  factory DiscountExpenseReportModel.fromJson(Map<String, dynamic> json) {
    final list = json['rows'];
    return DiscountExpenseReportModel(
      totals: DiscountExpenseTotals.fromJson(
        json['totals'] is Map<String, dynamic>
            ? json['totals'] as Map<String, dynamic>
            : null,
      ),
      rows: list is List
          ? list
              .whereType<Map>()
              .map((e) => DiscountExpenseRow.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <DiscountExpenseRow>[],
    );
  }
}
