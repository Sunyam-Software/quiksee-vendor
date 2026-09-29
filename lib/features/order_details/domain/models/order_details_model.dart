import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/domain/models/product_model.dart';

class OrderDetailsModel {
  int? _id;
  int? _orderId;
  int? _productId;
  int? _sellerId;
  Product? _productDetails;
  int? _qty;
  double? _price;
  double? _tax;
  double? _totalTaxAmount;
  double? _discount;
  String? _deliveryStatus;
  String? _paymentStatus;
  String? _createdAt;
  String? _updatedAt;
  int? _shippingMethodId;
  String? _variant;
  OrderModel? _orderModel;
  OrderEditHistory? _latestEditHistory;

  OrderDetailsModel(
      {int? id,
        int? orderId,
        int? productId,
        int? sellerId,
        Product? productDetails,
        int? qty,
        double? price,
        double? tax,
        double? totalTaxAmount,
        double? discount,
        String? deliveryStatus,
        String? paymentStatus,
        String? createdAt,
        String? updatedAt,
        int? shippingMethodId,
        String? variant,
        //List<Variation> variation
        OrderModel? orderModel,
        OrderEditHistory? latestEditHistory,
      }) {
    _id = id;
    _orderId = orderId;
    _productId = productId;
    _sellerId = sellerId;
    _productDetails = productDetails;
    _qty = qty;
    _price = price;
    _tax = tax;
    _totalTaxAmount = totalTaxAmount;
    _discount = discount;
    _deliveryStatus = deliveryStatus;
    _paymentStatus = paymentStatus;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _shippingMethodId = shippingMethodId;
    _variant = variant;
    _orderModel = orderModel;
    _latestEditHistory = latestEditHistory;
  }

  int? get id => _id;
  int? get orderId => _orderId;
  int? get productId => _productId;
  int? get sellerId => _sellerId;
  Product? get productDetails => _productDetails;
  int? get qty => _qty;
  double? get price => _price;
  double? get tax => _tax;
  double? get discount => _discount;
  String? get deliveryStatus => _deliveryStatus;
  String? get paymentStatus => _paymentStatus;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  int? get shippingMethodId => _shippingMethodId;
  String? get variant => _variant;
  OrderModel? get orderModel => _orderModel;
  double? get totalTaxAmount => _totalTaxAmount;
  OrderEditHistory? get latestEditHistory => _latestEditHistory;

  OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _orderId = json['order_id'];
    _productId = json['product_id'];
    _sellerId = json['seller_id'];
    if(json['product_details'] != null) {
      _productDetails = Product.fromJson(json['product_details']);
    }
    _qty = json['qty'];
    _price = double.tryParse(json['price']?.toString() ?? '') ?? 0;
    // Line tax from order_details.tax (API). Do not rely only on total_tax_amount.
    _tax = double.tryParse(json['tax']?.toString() ?? '') ?? 0;
    _totalTaxAmount = double.tryParse(json['total_tax_amount']?.toString() ?? '') ??
        _tax;
    _discount = double.tryParse(json['discount']?.toString() ?? '') ?? 0;
    _deliveryStatus = json['delivery_status'];
    _paymentStatus = json['payment_status'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _shippingMethodId = json['shipping_method_id'];
    _variant = json['variant'];

    if(json['order'] != null) {
      final orderJson = Map<String, dynamic>.from(json['order'] as Map);
      // Detail-level payment_info / amounts override nested order when present.
      if (json['payment_info'] is Map && orderJson['payment_info'] == null) {
        orderJson['payment_info'] = json['payment_info'];
      }
      final nestedAmt = double.tryParse('${orderJson['order_amount'] ?? ''}');
      final detailAmt = double.tryParse('${json['order_amount'] ?? ''}');
      final collectAmt = double.tryParse('${json['collectable_amount'] ?? ''}');
      final amountToCollect = double.tryParse('${json['amount_to_collect'] ?? ''}');
      final bestAmt = [
        nestedAmt,
        detailAmt,
        collectAmt,
        amountToCollect,
      ].whereType<double>().where((v) => v > 0).fold<double?>(null, (best, v) {
        if (best == null || v > best) return v;
        return best;
      });
      if (bestAmt != null) {
        orderJson['order_amount'] = bestAmt;
      }
      if (json['collectable_amount'] != null) {
        orderJson['collectable_amount'] = json['collectable_amount'];
      }
      if (json['amount_to_collect'] != null) {
        orderJson['amount_to_collect'] = json['amount_to_collect'];
      }
      // Hoist discount / fee breakdown so Flutter Payment Info matches admin.
      if (orderJson['payment_info'] is Map) {
        final pi = Map<String, dynamic>.from(orderJson['payment_info'] as Map);
        orderJson['item_discount'] ??= pi['item_discount'];
        orderJson['coupon_discount'] ??= pi['coupon_discount'];
        orderJson['extra_discount'] ??= pi['extra_discount'];
        orderJson['refer_and_earn_discount'] ??=
            pi['refer_and_earn_discount'];
        orderJson['platform_fee'] ??= pi['platform_fee'];
        orderJson['delivery_man_tip'] ??= pi['delivery_man_tip'];
        orderJson['scheduled_delivery_charge'] ??=
            pi['scheduled_delivery_charge'];
        orderJson['extra_incentive_charge'] ??= pi['extra_incentive_charge'];
        orderJson['extra_incentive_label'] ??= pi['extra_incentive_label'];
        orderJson['extra_incentive_rider_share'] ??=
            pi['extra_incentive_rider_share'];
        if (orderJson['extra_incentive_items'] == null &&
            pi['extra_incentive_items'] is List) {
          orderJson['extra_incentive_items'] = pi['extra_incentive_items'];
        }
        if (orderJson['manual_extra_charges'] == null &&
            pi['manual_extra_charges'] is List) {
          orderJson['manual_extra_charges'] = pi['manual_extra_charges'];
        }
        orderJson['order_amount'] ??=
            pi['order_amount'] ?? pi['total_amount'] ?? pi['collectable_amount'];
      }
      // Detail-root fee keys (API sometimes only sets these outside nested order).
      for (final key in [
        'extra_incentive_charge',
        'extra_incentive_label',
        'extra_incentive_rider_share',
        'extra_incentive_items',
        'manual_extra_charges',
        'platform_fee',
        'delivery_man_tip',
        'scheduled_delivery_charge',
        'show_extra_incentive',
      ]) {
        if (json[key] != null && orderJson[key] == null) {
          orderJson[key] = json[key];
        }
      }
      _orderModel = OrderModel.fromJson(orderJson);
    }

    _latestEditHistory = json['latest_edit_history'] != null ? OrderEditHistory.fromJson(json['latest_edit_history']) : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['order_id'] = _orderId;
    data['product_id'] = _productId;
    data['seller_id'] = _sellerId;
    if(_productDetails != null) {
      data['product_details'] = _productDetails!.toJson();
    }
    data['qty'] = _qty;
    data['price'] = _price;
    data['tax'] = _tax;
    data['total_tax_amount'] = _totalTaxAmount;
    data['discount'] = _discount;
    data['delivery_status'] = _deliveryStatus;
    data['payment_status'] = _paymentStatus;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    data['shipping_method_id'] = _shippingMethodId;
    data['variant'] = _variant;
    data['order'] = _orderModel?.toJson();

    return data;
  }
}


class OrderEditHistory {
  int? id;
  int? uId;
  int? orderId;
  String? editBy;
  int? editedUserId;
  String? editedUserName;
  double? orderAmount;
  double? orderDueAmount;
  String? orderDuePaymentStatus;
  OfflinePaymentsEdit? orderDuePaymentInfo;
  String? orderDuePaymentMethod;
  String? orderDueTransactionRef;
  String? orderDuePaymentNote;
  double? orderReturnAmount;
  String? orderReturnPaymentStatus;
  String? orderReturnPaymentMethod;
  OfflinePaymentsEdit? orderReturnPaymentInfo;
  String? orderReturnTransactionRef;
  String? orderReturnPaymentNote;
  String? createdAt;
  String? updatedAt;

  OrderEditHistory(
      {this.id,
        this.uId,
        this.orderId,
        this.editBy,
        this.editedUserId,
        this.editedUserName,
        this.orderAmount,
        this.orderDueAmount,
        this.orderDuePaymentStatus,
        this.orderDuePaymentInfo,
        this.orderDuePaymentMethod,
        this.orderDueTransactionRef,
        this.orderDuePaymentNote,
        this.orderReturnAmount,
        this.orderReturnPaymentStatus,
        this.orderReturnPaymentMethod,
        this.orderReturnPaymentInfo,
        this.orderReturnTransactionRef,
        this.orderReturnPaymentNote,
        this.createdAt,
        this.updatedAt});

  OrderEditHistory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uId = json['u_id'];
    orderId = json['order_id'];
    editBy = json['edit_by'];
    editedUserId = json['edited_user_id'];
    editedUserName = json['edited_user_name'];
    orderAmount = json['order_amount'] != null ? double.tryParse(json['order_amount'].toString()) : 0;
    orderDueAmount =  json['order_due_amount'] != null ? double.tryParse(json['order_due_amount'].toString()) : 0;
    orderDuePaymentStatus = json['order_due_payment_status'];
    orderDuePaymentInfo = json['order_due_payment_info'] != null ? OfflinePaymentsEdit.fromJson(json['order_due_payment_info']) : null;
    orderDuePaymentMethod = json['order_due_payment_method'];
    orderDueTransactionRef = json['order_due_transaction_ref'];
    orderDuePaymentNote = json['order_due_payment_note'];
    orderReturnAmount = json['order_return_amount'] != null ? double.tryParse(json['order_return_amount'].toString()) : 0;
    orderReturnPaymentStatus = json['order_return_payment_status'];
    orderReturnPaymentMethod = json['order_return_payment_method'];
    orderReturnPaymentInfo = json['order_return_payment_info'];
    orderReturnTransactionRef = json['order_return_transaction_ref'];
    orderReturnPaymentNote = json['order_return_payment_note'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['u_id'] = uId;
    data['order_id'] = orderId;
    data['edit_by'] = editBy;
    data['edited_user_id'] = editedUserId;
    data['edited_user_name'] = editedUserName;
    data['order_amount'] = orderAmount;
    data['order_due_amount'] = orderDueAmount;
    data['order_due_payment_status'] = orderDuePaymentStatus;
    data['order_due_payment_info'] = orderDuePaymentInfo;
    data['order_due_payment_method'] = orderDuePaymentMethod;
    data['order_due_transaction_ref'] = orderDueTransactionRef;
    data['order_due_payment_note'] = orderDuePaymentNote;
    data['order_return_amount'] = orderReturnAmount;
    data['order_return_payment_status'] = orderReturnPaymentStatus;
    data['order_return_payment_method'] = orderReturnPaymentMethod;
    data['order_return_payment_info'] = orderReturnPaymentInfo;
    data['order_return_transaction_ref'] = orderReturnTransactionRef;
    data['order_return_payment_note'] = orderReturnPaymentNote;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class OfflinePaymentsEdit {
  List<dynamic>? infoKey;
  List<dynamic>? infoValue;

  OfflinePaymentsEdit(
      {
        this.infoKey,
        this.infoValue,
      });

  OfflinePaymentsEdit.fromJson(Map<String, dynamic> json) {
    infoKey = (json.length>0)? json.entries.map((e)=> e.key).toList():[];
    infoValue = (json.length>0)? json.entries.map((e)=> e.value).toList():[];
  }
}