import 'package:quiksee_vendor_app/data/model/image_full_url.dart';

class ProfileInfoModel {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? image;
  ImageFullUrl? imageFullUrl;
  String? email;
  String? password;
  String? status;
  String? rememberToken;
  String? createdAt;
  String? updatedAt;
  String? bankName;
  String? branch;
  String? branchAddress;
  String? accountNo;
  String? ifscCode;
  String? accountType;
  String? holderName;
  String? authToken;
  double? salesCommissionPercentage;
  String? gst;
  int? productCount;
  int? posActive;
  int? ordersCount;
  Wallet? wallet;
  double? minimumOrderAmount;
  double? freeOverDeliveryAmount;
  int? freeOverDeliveryAmountStatus;

  ProfileInfoModel(
      {this.id,
        this.fName,
        this.lName,
        this.phone,
        this.image,
        this.imageFullUrl,
        this.email,
        this.password,
        this.status,
        this.rememberToken,
        this.createdAt,
        this.updatedAt,
        this.bankName,
        this.branch,
        this.branchAddress,
        this.accountNo,
        this.ifscCode,
        this.accountType,
        this.holderName,
        this.authToken,
        this.salesCommissionPercentage,
        this.gst,
        this.posActive,
        this.productCount,
        this.ordersCount,
        this.wallet,
        this.minimumOrderAmount,
        this.freeOverDeliveryAmount,
        this.freeOverDeliveryAmountStatus
      });

  bool get hasDisplayName {
    final bool hasFirst = fName != null && fName!.trim().isNotEmpty;
    final bool hasLast = lName != null && lName!.trim().isNotEmpty;
    return hasFirst || hasLast;
  }

  String displayName({String fallback = ''}) {
    final parts = <String>[
      if (fName != null && fName!.trim().isNotEmpty) fName!.trim(),
      if (lName != null && lName!.trim().isNotEmpty) lName!.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    if (holderName != null && holderName!.trim().isNotEmpty) {
      return holderName!.trim();
    }
    return fallback;
  }

  String displayPhone() => phone?.trim() ?? '';

  String displaySubtitle() {
    if (displayPhone().isNotEmpty) {
      return displayPhone();
    }
    return email?.trim() ?? '';
  }

  ProfileInfoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    image = json['image'];
    email = json['email'];
    password = json['password'];
    status = json['status'];
    rememberToken = json['remember_token'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    bankName = json['bank_name'];
    branch = json['branch'];
    branchAddress = json['branch_address'];
    accountNo = json['account_no'];
    ifscCode = json['ifsc_code'];
    accountType = json['account_type'];
    holderName = json['holder_name'];
    authToken = json['auth_token'];
    if(json['sales_commission_percentage']!=null){
      try{
        salesCommissionPercentage = (json['sales_commission_percentage']).toDouble();
      }catch(e){
        salesCommissionPercentage = double.parse(json['sales_commission_percentage'].toString());
      }

    }
    if(json['gst']!=null){
      gst = json['gst'];
    }
    posActive = json['pos_status'] != null
        ? int.tryParse(json['pos_status'].toString()) ?? 0
        : 0;
    productCount = json['product_count'];
    ordersCount = json['orders_count'];
    wallet =
    json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null;
    if(json['minimum_order_amount'] != null){
      try{
        minimumOrderAmount = json['minimum_order_amount'].toDouble();
      }catch(e){
        minimumOrderAmount = double.parse(json['minimum_order_amount'].toString());
      }
    }else{
      minimumOrderAmount = 0;
    }
    if(json['free_delivery_over_amount'] != null){
      try{
        freeOverDeliveryAmount = json['free_delivery_over_amount'].toDouble();
      }catch(e){
        freeOverDeliveryAmount = double.parse(json['free_delivery_over_amount'].toString());
      }
    }else{
      freeOverDeliveryAmount = 0;
    }

    if(json['free_delivery_status'] != null){
      try{
        freeOverDeliveryAmountStatus = json['free_delivery_status'];
      }catch(e){
        freeOverDeliveryAmountStatus = int.parse(json['free_delivery_status'].toString());
      }
    }else{
      freeOverDeliveryAmountStatus = 0;
    }

    imageFullUrl = json['image_full_url'] != null
        ? ImageFullUrl.fromJson(json['image_full_url'])
        : null;
  }

  String displayAccountType() {
    final normalized = accountType?.trim().toLowerCase() ?? '';
    if (normalized == 'saving' || normalized == 'savings') {
      return 'Saving';
    }
    if (normalized == 'current') {
      return 'Current';
    }
    return accountType?.trim() ?? '';
  }

  bool get isBankInfoComplete {
    return _hasValue(bankName) &&
        _hasValue(accountNo) &&
        _hasValue(holderName) &&
        _hasValue(ifscCode) &&
        _hasValue(accountType);
  }

  static bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

}

class Wallet {
  int? id;
  double? totalEarning;
  double? lifetimeEarning;
  double? withdrawn;
  String? createdAt;
  String? updatedAt;
  double? commissionGiven;
  double? pendingWithdraw;
  double? deliveryChargeEarned;
  double? collectedCash;
  double? totalTaxCollected;

  Wallet(
      {this.id,
        this.totalEarning,
        this.lifetimeEarning,
        this.withdrawn,
        this.createdAt,
        this.updatedAt,
        this.commissionGiven,
        this.pendingWithdraw,
        this.deliveryChargeEarned,
        this.collectedCash,
        this.totalTaxCollected});

  double get earnedAmount {
    if (lifetimeEarning != null) return lifetimeEarning!;
    return (totalEarning ?? 0) + (withdrawn ?? 0) + (pendingWithdraw ?? 0);
  }

  Wallet.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    totalEarning = _toDouble(json['total_earning']);
    withdrawn = _toDouble(json['withdrawn']);
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    commissionGiven = _toDouble(json['commission_given']);
    pendingWithdraw = _toDouble(json['pending_withdraw']);
    deliveryChargeEarned = _toDouble(json['delivery_charge_earned']);
    collectedCash = _toDouble(json['collected_cash']);
    totalTaxCollected = _toDouble(json['total_tax_collected']);
    if (json['lifetime_earning'] != null) {
      lifetimeEarning = _toDouble(json['lifetime_earning']);
    } else {
      lifetimeEarning = (totalEarning ?? 0) + (withdrawn ?? 0) + (pendingWithdraw ?? 0);
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['total_earning'] = totalEarning;
    data['lifetime_earning'] = lifetimeEarning ?? earnedAmount;
    data['withdrawn'] = withdrawn;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['commission_given'] = commissionGiven;
    data['pending_withdraw'] = pendingWithdraw;
    data['delivery_charge_earned'] = deliveryChargeEarned;
    data['collected_cash'] = collectedCash;
    data['total_tax_collected'] = totalTaxCollected;
    return data;
  }
}
