class OrderTransactionRow {
  final int orderId;
  final String customerName;
  final int? customerId;
  final int isGuest;
  final double totalProductAmount;
  final double productDiscount;
  final String? productDiscountBearer;
  final String productDiscountSide;
  final double saleDiscount;
  final String? saleDiscountBearer;
  final String saleDiscountSide;
  final double couponDiscount;
  final String? couponDiscountBearer;
  final String couponDiscountSide;
  final double discountedAmount;
  final double tax;
  final double shippingCharge;
  final double orderAmount;
  final double vendorDiscount;
  final double adminCommission;
  final double vendorNetIncome;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveredBy;

  OrderTransactionRow({
    required this.orderId,
    required this.customerName,
    this.customerId,
    this.isGuest = 0,
    this.totalProductAmount = 0,
    this.productDiscount = 0,
    this.productDiscountBearer,
    this.productDiscountSide = '',
    this.saleDiscount = 0,
    this.saleDiscountBearer,
    this.saleDiscountSide = '',
    this.couponDiscount = 0,
    this.couponDiscountBearer,
    this.couponDiscountSide = '',
    this.discountedAmount = 0,
    this.tax = 0,
    this.shippingCharge = 0,
    this.orderAmount = 0,
    this.vendorDiscount = 0,
    this.adminCommission = 0,
    this.vendorNetIncome = 0,
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.deliveredBy = '',
  });

  factory OrderTransactionRow.fromJson(Map<String, dynamic> json) {
    return OrderTransactionRow(
      orderId: int.tryParse('${json['order_id'] ?? 0}') ?? 0,
      customerName: '${json['customer_name'] ?? ''}',
      customerId: json['customer_id'] == null ? null : int.tryParse('${json['customer_id']}'),
      isGuest: int.tryParse('${json['is_guest'] ?? 0}') ?? 0,
      totalProductAmount: _toDouble(json['total_product_amount']),
      productDiscount: _toDouble(json['product_discount']),
      productDiscountBearer: json['product_discount_bearer']?.toString(),
      productDiscountSide: '${json['product_discount_side'] ?? ''}',
      saleDiscount: _toDouble(json['sale_discount']),
      saleDiscountBearer: json['sale_discount_bearer']?.toString(),
      saleDiscountSide: '${json['sale_discount_side'] ?? ''}',
      couponDiscount: _toDouble(json['coupon_discount']),
      couponDiscountBearer: json['coupon_discount_bearer']?.toString(),
      couponDiscountSide: '${json['coupon_discount_side'] ?? ''}',
      discountedAmount: _toDouble(json['discounted_amount']),
      tax: _toDouble(json['tax']),
      shippingCharge: _toDouble(json['shipping_charge']),
      orderAmount: _toDouble(json['order_amount']),
      vendorDiscount: _toDouble(json['vendor_discount']),
      adminCommission: _toDouble(json['admin_commission']),
      vendorNetIncome: _toDouble(json['vendor_net_income']),
      paymentMethod: '${json['payment_method'] ?? ''}',
      paymentStatus: '${json['payment_status'] ?? ''}',
      deliveredBy: '${json['delivered_by'] ?? ''}',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  bool get hasProductDiscount => productDiscount > 0;
  bool get hasSaleDiscount => saleDiscount > 0;
  bool get hasCouponDiscount => couponDiscount > 0;
}

class OrderTransactionReportModel {
  final int totalSize;
  final List<OrderTransactionRow> transactions;
  final double totalAdminCommission;
  final double totalSellerAmount;
  final double totalOrderAmount;
  final double totalTax;
  final double totalVendorNetIncome;

  OrderTransactionReportModel({
    required this.totalSize,
    required this.transactions,
    this.totalAdminCommission = 0,
    this.totalSellerAmount = 0,
    this.totalOrderAmount = 0,
    this.totalTax = 0,
    this.totalVendorNetIncome = 0,
  });

  factory OrderTransactionReportModel.fromJson(Map<String, dynamic> json) {
    final list = json['transactions'];
    final totals = json['totals'] is Map ? Map<String, dynamic>.from(json['totals'] as Map) : <String, dynamic>{};
    return OrderTransactionReportModel(
      totalSize: int.tryParse('${json['total_size'] ?? 0}') ?? 0,
      totalAdminCommission: _num(totals['admin_commission']),
      totalSellerAmount: _num(totals['seller_amount']),
      totalOrderAmount: _num(totals['order_amount']),
      totalTax: _num(totals['tax']),
      totalVendorNetIncome: _num(totals['vendor_net_income']),
      transactions: list is List
          ? list
              .whereType<Map>()
              .map((e) => OrderTransactionRow.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <OrderTransactionRow>[],
    );
  }

  static double _num(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
