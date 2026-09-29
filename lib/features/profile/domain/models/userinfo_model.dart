import 'package:quiksee/data/models/image_full_url.dart';
import 'package:quiksee/features/assignment/domain/models/assignment_settings_model.dart';

class UserInfoModel {
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? image;
  ImageFullUrl? imageFullUrl;
  String? identityNumber;
  String? identityType;
  List<dynamic>? identityImage;
  List<ImageFullUrl>? identityImageFullUrl;
  int? isOnline;
  bool isAccountActive = true;
  String? createdAt;
  String? updatedAt;
  double? withdrawableBalance;
  double? currentBalance;
  double? cashInHand;
  double? pendingWithdraw;
  double? totalWithdraw;
  double? totalEarn;
  int? completedDelivery;
  int? totalDelivery;
  int? pauseDelivery;
  int? pendingDelivery;
  double? totalDeposit;
  String? countryCode;
  String? address;
  String? bankName;
  String? branch;
  String? branchAddress;
  String? accountNo;
  String? ifscCode;
  String? holderName;
  bool? autoAssignEnabled;
  int? dailyOrderLimit;
  int? dailyOrderLimitDefault;
  int? activeOrdersCount;
  int? pendingOffersCount;
  double? lastLatitude;
  double? lastLongitude;
  String? lastLocationAt;
  String? assignmentMode;
  AssignmentSettingsModel? assignmentSettings;
  DeliveryAreasSummary? deliveryAreasSummary;

  UserInfoModel(
      {this.id,
        this.fName,
        this.lName,
        this.phone,
        this.email,
        this.image,
        this.imageFullUrl,
        this.identityNumber,
        this.identityType,
        this.identityImage,
        this.identityImageFullUrl,
        this.isOnline,
        this.isAccountActive = true,
        this.createdAt,
        this.updatedAt,
        this.withdrawableBalance,
        this.currentBalance,
        this.cashInHand,
        this.pendingWithdraw,
        this.totalWithdraw,
        this.totalEarn,
        this.completedDelivery,
        this.totalDelivery,
        this.pauseDelivery,
        this.pendingDelivery,
        this.totalDeposit,
        this.address,
        this.countryCode,
        this.bankName,
        this.branch,
        this.branchAddress,
        this.accountNo,
        this.ifscCode,
        this.holderName,
        this.autoAssignEnabled,
        this.dailyOrderLimit,
        this.dailyOrderLimitDefault,
        this.activeOrdersCount,
        this.pendingOffersCount,
        this.lastLatitude,
        this.lastLongitude,
        this.lastLocationAt,
        this.assignmentMode,
        this.assignmentSettings,
        this.deliveryAreasSummary,
      });

  UserInfoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    fName = json['f_name'];
    lName = json['l_name'];
    phone = json['phone'];
    email = json['email'];
    image = json['image'];
    isOnline = int.tryParse('${json['is_online']}') ?? 0;
    if (json.containsKey('is_active')) {
      final active = json['is_active'];
      isAccountActive =
          active == true || active == 1 || active.toString() == '1';
    } else {
      isAccountActive = true;
    }
    identityNumber = json['identity_number'];
    identityType = json['identity_type'];
    if(json['identity_image'] is !String){
      identityImage = [];
      //identityImage = jsonDecode(json['identity_image']);
    }
    if (json['identity_images_full_url'] != null) {
      identityImageFullUrl = <ImageFullUrl>[];
      json['identity_images_full_url'].forEach((v) {
        identityImageFullUrl!.add(ImageFullUrl.fromJson(v));
      });
    } else {
      identityImageFullUrl = [];
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if(json['withdrawable_balance'] != null){
      try{
        withdrawableBalance = json['withdrawable_balance'].toDouble();
      }catch(e){
        withdrawableBalance = double.parse(json['withdrawable_balance']);
      }

    }else{
      withdrawableBalance = 0;
    }
    if(json['current_balance'] != null){
      try{
        currentBalance = json['current_balance'].toDouble();
      }catch(e){
        currentBalance = double.parse(json['current_balance']);
      }
    }else{
      currentBalance = 0;
    }
    if(json['cash_in_hand'] != null){
      try{
        cashInHand = json['cash_in_hand'].toDouble();
      }catch(e){
        cashInHand = double.parse(json['cash_in_hand']);
      }
    }else{
      cashInHand = 0;
    }
    if(json['pending_withdraw'] != null){
      try{
        pendingWithdraw = json['pending_withdraw'].toDouble();
      }catch(e){
        pendingWithdraw = double.parse(json['pending_withdraw']);
      }
    }else{
      pendingWithdraw = 0;
    }
    if(json['total_withdraw'] != null){
      try{
        totalWithdraw = json['total_withdraw'].toDouble();
      }catch(e){
        totalWithdraw = double.parse(json['total_withdraw']);
      }
    }else{
      totalWithdraw = 0;
    }

    if (json['total_earn'] != null) {
      try {
        totalEarn = json['total_earn'].toDouble();
      } catch (_) {
        totalEarn = double.tryParse('${json['total_earn']}') ?? 0;
      }
    } else {
      totalEarn = 0;
    }
    if(json['completed_delivery'] != null){
      completedDelivery = json['completed_delivery'];
    }else{
      completedDelivery = 0;
    }
    if(json['total_delivery'] != null){
      totalDelivery = json['total_delivery'];
    }else{
      totalDelivery = 0;
    }
    if(json['pause_delivery'] != null){
      pauseDelivery = json['pause_delivery'];
    }else{
      pauseDelivery = 0;
    }
    if(json['pending_delivery'] != null){
      pendingDelivery = json['pending_delivery'];
    }else{
      pendingDelivery = 0;
    }
    if(json['total_deposit'] != null){
      try{
        totalDeposit = json['total_deposit'].toDouble();
      }catch(e){
        totalDeposit = double.parse(json['total_deposit']);
      }
    }else{
      totalDeposit = 0;
    }
    countryCode = json['country_code'];
    if(json['address'] != null){
      address = json['address'];
    }else{
      address = '';
    }

    if(json['bank_name'] != null){
      bankName = json['bank_name'];
    }
    if(json['branch'] != null){
      branch = json['branch'];
    }
    branchAddress = _readBankString(json, ['branch_address', 'branchAddress']);
    if(json['account_no'] != null){
      accountNo = json['account_no'];
    }
    ifscCode = _readBankString(json, ['ifsc_code', 'ifsc', 'IFSC_code']);
    if(json['holder_name'] != null){
      holderName = json['holder_name'];
    }

    if (json['bank_info'] is Map) {
      final bankInfo = Map<String, dynamic>.from(json['bank_info'] as Map);
      bankName ??= _readBankString(bankInfo, ['bank_name', 'bankName']);
      branch ??= _readBankString(bankInfo, ['branch']);
      branchAddress ??=
          _readBankString(bankInfo, ['branch_address', 'branchAddress']);
      accountNo ??= _readBankString(bankInfo, ['account_no', 'accountNo']);
      ifscCode ??= _readBankString(bankInfo, ['ifsc_code', 'ifsc', 'IFSC_code']);
      holderName ??= _readBankString(bankInfo, ['holder_name', 'holderName']);
    }

    if (json['image_full_url'] != null) {
      try {
        imageFullUrl = ImageFullUrl.fromJson(json['image_full_url']);
      } catch (_) {
        imageFullUrl = null;
      }
    }

    autoAssignEnabled = json['auto_assign_enabled'] == true ||
        json['auto_assign_enabled'] == 1 ||
        json['auto_assign_enabled']?.toString() == '1';
    dailyOrderLimit = int.tryParse('${json['daily_order_limit']}');
    dailyOrderLimitDefault =
        int.tryParse('${json['daily_order_limit_default']}');
    activeOrdersCount = int.tryParse('${json['active_orders_count']}');
    pendingOffersCount = int.tryParse('${json['pending_offers_count']}');
    lastLatitude = double.tryParse('${json['last_latitude']}');
    lastLongitude = double.tryParse('${json['last_longitude']}');
    lastLocationAt = json['last_location_at']?.toString();
    assignmentMode = json['assignment_mode']?.toString();
    if (json['assignment_settings'] is Map) {
      try {
        assignmentSettings = AssignmentSettingsModel.fromJson(
          Map<String, dynamic>.from(json['assignment_settings'] as Map),
        );
      } catch (_) {}
    }
    if (json['delivery_areas_summary'] is Map) {
      try {
        deliveryAreasSummary = DeliveryAreasSummary.fromJson(
          Map<String, dynamic>.from(json['delivery_areas_summary'] as Map),
        );
      } catch (_) {}
    }
  }

  static String? _readBankString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

}
