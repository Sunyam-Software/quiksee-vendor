class TransactionModel {
  int? _id;
  int? _sellerId;
  int? _adminId;
  double? _amount;
  String? _transactionNote;
  int? _approved;
  String? _createdAt;
  String? _updatedAt;
  int? _withdrawalMethodId;
  Map<String, dynamic>? _withdrawalMethodFields;
  String? _type;
  int? _orderId;

  TransactionModel(
      {int? id,
        int? sellerId,
        int? adminId,
        double? amount,
        String? transactionNote,
        int? approved,
        String? createdAt,
        String? updatedAt,
        String? type,
        int? orderId}) {
    _id = id;
    _sellerId = sellerId;
    _adminId = adminId;
    _amount = amount;
    _transactionNote = transactionNote;
    _approved = approved;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _type = type;
    _orderId = orderId;
  }

  int? get id => _id;
  int? get sellerId => _sellerId;
  int? get adminId => _adminId;
  double? get amount => _amount;
  String? get transactionNote => _transactionNote;
  int? get approved => _approved;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  int? get withdrawalMethodId => _withdrawalMethodId;
  Map<String, dynamic>? get withdrawalMethodFields => _withdrawalMethodFields;
  String? get type => _type;
  int? get orderId => _orderId;
  bool get isOrderEarning => _type == 'order_earning';
  bool get isWithdrawRequest => !isOrderEarning;

  TransactionModel.fromJson(Map<String, dynamic> json) {
    _id = int.tryParse('${json['id'] ?? ''}');
    _sellerId = int.tryParse('${json['seller_id'] ?? ''}');
    _adminId = json['admin_id'] == null ? null : int.tryParse('${json['admin_id']}');
    _amount = double.tryParse('${json['amount'] ?? 0}') ?? 0;
    _transactionNote = json['transaction_note']?.toString();
    _approved = int.tryParse('${json['approved'] ?? 0}') ?? 0;
    _createdAt = json['created_at']?.toString();
    _updatedAt = json['updated_at']?.toString();
    _withdrawalMethodId = json['withdrawal_method_id'] == null
        ? null
        : int.tryParse('${json['withdrawal_method_id']}');
    _withdrawalMethodFields = (json['withdrawal_method_fields'] != null && json['withdrawal_method_fields'] is! String)
        ? Map<String, dynamic>.from(json['withdrawal_method_fields'])
        : null;
    _type = json['type']?.toString() ??
        (json['order_id'] != null ? 'order_earning' : 'withdraw');
    _orderId = json['order_id'] == null ? null : int.tryParse('${json['order_id']}');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['seller_id'] = _sellerId;
    data['admin_id'] = _adminId;
    data['amount'] = _amount;
    data['transaction_note'] = _transactionNote;
    data['approved'] = _approved;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    data['withdrawal_method_id'] = _withdrawalMethodId;
    data['withdrawal_method_fields'] = _withdrawalMethodFields;
    data['type'] = _type;
    data['order_id'] = _orderId;
    return data;
  }
}