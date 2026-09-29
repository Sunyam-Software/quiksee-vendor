import 'package:quiksee/data/models/image_full_url.dart';
import 'package:quiksee/features/chat/domain/enums/vacation_duration_type.dart';

class ConfigModel {
  int? _systemDefaultCurrency;
  bool? _digitalPayment;
  BaseUrls? _baseUrls;
  StaticUrls? _staticUrls;
  String? _aboutUs;
  String? _privacyPolicy;
  List<Faq>? _faq;
  String? _termsConditions;
  List<CurrencyList>? _currencyList;
  String? _currencySymbolPosition;
  bool? _maintenanceMode;
  List<String>? _language;
  List<Colors>? _colors;
  List<String>? _unit;
  String? _shippingMethod;
  String? _currencyModel;
  bool? _emailVerification;
  bool? _phoneVerification;
  String? _countryCode;
  List<SocialLogin>? _socialLogin;
  String? _forgotPasswordVerification;
  String? _companyPhone;
  String? _companyEmail;
  int? _decimalPointSetting;
  String? _companyLogo;
  ImageFullUrl? _companyLogoImage;
  String? _companyIcon;
  int? imageUpload;
  int? orderVerification;
  int? foodPickupOtp;
  int? _mapApiStatus;
  DefaultLocation? defaultLocation;
  ImageFullUrl? companyFavIcon;
  MaintenanceMode? maintenanceModeData;
  int? decimalPointSettings;
  String? serverUploadMaxFileSize;
  InHouseVacationAdd? _inHouseTemporaryClose;
  InHouseVacationAdd? _inHouseVacationAdd;
  InHouseShop? _inHouseShop;
  DeliveryManAppVersionControl? _deliveryManAppVersionControl;
  int? systemImageFileUploadMaxSize;
  int? systemGeneralFileUploadMaxSize;


  ConfigModel(
      {int? systemDefaultCurrency,
        bool? digitalPayment,
        BaseUrls? baseUrls,
        StaticUrls? staticUrls,
        String? aboutUs,
        String? privacyPolicy,
        List<Faq>? faq,
        String? termsConditions,
        List<CurrencyList>? currencyList,
        String? currencySymbolPosition,
        bool? maintenanceMode,
        List<String>? language,
        List<Colors>? colors,
        List<String>? unit,
        String? shippingMethod,
        String? currencyModel,
        bool? emailVerification,
        bool? phoneVerification,
        String? countryCode,
        List<SocialLogin>? socialLogin,
        String? forgotPasswordVerification,
        String? companyPhone,
        String? companyEmail,
        int? decimalPointSetting,
        String? companyLogo,
        ImageFullUrl? companyLogoImage,
        String? companyIcon,
        int? imageUpload,
        int? orderVerification,
        this.foodPickupOtp,
        int? mapApiStatus,
        InHouseVacationAdd? inhouseTemporaryClose,
        InHouseVacationAdd? inhouseVacationAdd,
        InHouseShop? inHouseShop,
        DeliveryManAppVersionControl? deliveryManAppVersionControl,
      }) {
    _systemDefaultCurrency = systemDefaultCurrency;
    _digitalPayment = digitalPayment;
    _baseUrls = baseUrls;
    _staticUrls = staticUrls;
    _aboutUs = aboutUs;
    _privacyPolicy = privacyPolicy;
    _faq = faq;
    _termsConditions = termsConditions;
    _currencyList = currencyList;
    _currencySymbolPosition = currencySymbolPosition;
    _maintenanceMode = maintenanceMode;
    _language = language;
    _colors = colors;
    _unit = unit;
    _shippingMethod = shippingMethod;
    _currencyModel = currencyModel;
    _emailVerification = emailVerification;
    _phoneVerification = phoneVerification;
    _countryCode = countryCode;
    _socialLogin = socialLogin;
    _forgotPasswordVerification = forgotPasswordVerification;
    if (companyPhone != null) {
      _companyPhone = companyPhone;
    }
    if (companyEmail != null) {
      _companyEmail = companyEmail;
    }
    _decimalPointSetting = decimalPointSetting;
    _companyLogo = companyLogo;
    _companyLogoImage = companyLogoImage;
    _companyIcon = companyIcon;
    this.imageUpload;
    this.orderVerification;
    _mapApiStatus = mapApiStatus;
    defaultLocation;
    companyFavIcon;
    maintenanceModeData;
    decimalPointSettings;
    serverUploadMaxFileSize;
    _inHouseTemporaryClose = inhouseTemporaryClose;
    _inHouseVacationAdd = inhouseVacationAdd;
    _inHouseShop = inHouseShop;
    _deliveryManAppVersionControl = deliveryManAppVersionControl;
    systemImageFileUploadMaxSize;
    systemGeneralFileUploadMaxSize;
  }

  int? get systemDefaultCurrency => _systemDefaultCurrency;
  bool? get digitalPayment => _digitalPayment;
  BaseUrls? get baseUrls => _baseUrls;
  StaticUrls? get staticUrls => _staticUrls;
  String? get aboutUs => _aboutUs;
  String? get privacyPolicy => _privacyPolicy;
  List<Faq>? get faq => _faq;
  String? get termsConditions => _termsConditions;
  List<CurrencyList>? get currencyList => _currencyList;
  String? get currencySymbolPosition => _currencySymbolPosition;
  bool? get maintenanceMode => _maintenanceMode;
  List<String>? get language => _language;
  List<Colors>? get colors => _colors;
  List<String>? get unit => _unit;
  String? get shippingMethod => _shippingMethod;
  String? get currencyModel => _currencyModel;
  bool? get emailVerification => _emailVerification;
  bool? get phoneVerification => _phoneVerification;
  String? get countryCode =>_countryCode;
  List<SocialLogin>? get socialLogin => _socialLogin;
  String? get forgotPasswordVerification => _forgotPasswordVerification;
  String? get companyPhone => _companyPhone;
  String? get companyEmail => _companyEmail;
  int? get decimalPointSetting => _decimalPointSetting;
  String? get companyLogo => _companyLogo;
  ImageFullUrl? get companyLogoImage => _companyLogoImage;
  String? get companyIcon => _companyIcon;
  int? get mapApiStatus => _mapApiStatus;
  InHouseVacationAdd? get inHouseTemporaryClose => _inHouseTemporaryClose;
  InHouseVacationAdd? get inHouseVacationAdd => _inHouseVacationAdd;
  InHouseShop? get inHouseShop => _inHouseShop;
  DeliveryManAppVersionControl? get deliveryManAppVersionControl => _deliveryManAppVersionControl;


  ConfigModel.fromJson(Map<String, dynamic> json) {
    _systemDefaultCurrency = json['system_default_currency'];
    _digitalPayment = json['digital_payment'];
    _baseUrls = json['base_urls'] != null
        ? BaseUrls.fromJson(json['base_urls'])
        : null;
    _staticUrls = json['static_urls'] != null
        ? StaticUrls.fromJson(json['static_urls'])
        : null;
    _aboutUs = json['about_us'];
    _privacyPolicy = json['privacy_policy'];
   if (json['faq'] != null) {
      _faq = [];
      json['faq'].forEach((v) {_faq!.add(Faq.fromJson(v));
      });
    }
    _termsConditions = json['terms_&_conditions'];
    if (json['currency_list'] != null) {
      _currencyList = [];
      json['currency_list'].forEach((v) {_currencyList!.add(CurrencyList.fromJson(v));
      });
    }
    _currencySymbolPosition = json['currency_symbol_position'];
    // _maintenanceMode = json['maintenance_mode'];
    _language = json['language'].cast<String>();
    if (json['colors'] != null) {
      _colors = [];
      json['colors'].forEach((v) {_colors!.add(Colors.fromJson(v));
      });
    }

    _unit = json['unit'].cast<String>();
    _shippingMethod = json['shipping_method'];
    _currencyModel = json['currency_model'];
    _emailVerification = json['email_verification'];
    _phoneVerification = json['phone_verification'];
    _countryCode = json['country_code'];
    if (json['social_login'] != null) {
      _socialLogin = [];
      json['social_login'].forEach((v) { _socialLogin!.add(SocialLogin.fromJson(v)); });
    }
    _forgotPasswordVerification = json['deliveryman_forgot_password_method'];
    _companyPhone = json['company_phone'].toString();
    _companyEmail = json['company_email'];
    if(json['decimal_point_settings'] != null && json['decimal_point_settings'] != "" ){
      _decimalPointSetting = int.parse(json['decimal_point_settings'].toString());
    }
    //_companyLogo =json['company_logo']??'';
    _companyLogoImage = json['company_logo'] != null
        ? ImageFullUrl.fromJson(json['company_logo'])
        : null;

    //_companyIcon = json['company_fav_icon'] ?? '';
    if(json['upload_picture_on_delivery'] != null){
      try{
        imageUpload = json['upload_picture_on_delivery'];
      }catch(e){
        imageUpload = int.parse(json['upload_picture_on_delivery'].toString());
      }
    }
    if(json['order_verification'] != null){
      try{
        orderVerification = json['order_verification'];
      }catch(e){
        orderVerification = int.parse(json['order_verification'].toString());
      }
    }
    if (json['food_pickup_otp'] != null) {
      foodPickupOtp = int.tryParse('${json['food_pickup_otp']}') ?? 0;
    }
    _mapApiStatus = int.parse(json['map_api_status'].toString());

    defaultLocation = json['default_location'] != null
        ? DefaultLocation.fromJson(json['default_location'])
        : null;

    companyFavIcon = json['company_fav_icon'] != null
      ? ImageFullUrl.fromJson(json['company_fav_icon'])
      : null;

    maintenanceModeData = json['maintenance_mode'] != null ? MaintenanceMode.fromJson(json['maintenance_mode']) : null;

    decimalPointSettings = int.tryParse(json['decimal_point_settings'].toString());

    serverUploadMaxFileSize = json['server_upload_max_filesize'];

    if (json['inhouse_temporary_close'] != null) {
      _inHouseTemporaryClose = InHouseVacationAdd.fromJson(json['inhouse_temporary_close']);
    } else {
      _inHouseTemporaryClose = null;
    }

    if (json['inhouse_vacation_add'] != null) {
      _inHouseVacationAdd = InHouseVacationAdd.fromJson(json['inhouse_vacation_add']);
    } else {
      _inHouseVacationAdd = null;
    }

    if(json['in_house_shop'] != null){
      _inHouseShop = InHouseShop.fromJson(json['in_house_shop']);
    } else {
      _inHouseShop = null;
    }

    if(json['delivery_man_app_version_control'] != null){
      _deliveryManAppVersionControl = DeliveryManAppVersionControl.fromJson(json['delivery_man_app_version_control']);
    } else{
      _deliveryManAppVersionControl = null;
    }

    systemImageFileUploadMaxSize = int.tryParse(json['system_image_file_upload_max_size'].toString());
    systemGeneralFileUploadMaxSize = int.tryParse(json['system_general_file_upload_max_size'].toString());

  }
}

class BaseUrls {
  String? _productImageUrl;
  String? _productThumbnailUrl;
  String? _brandImageUrl;
  String? _customerImageUrl;
  String? _bannerImageUrl;
  String? _categoryImageUrl;
  String? _reviewImageUrl;
  String? _sellerImageUrl;
  String? _shopImageUrl;
  String? _notificationImageUrl;
  String? _deliverymanImageUrl;

  BaseUrls(
      {String? productImageUrl,
        String? productThumbnailUrl,
        String? brandImageUrl,
        String? customerImageUrl,
        String? bannerImageUrl,
        String? categoryImageUrl,
        String? reviewImageUrl,
        String? sellerImageUrl,
        String? shopImageUrl,
        String? notificationImageUrl,
        String? deliverymanImageUrl,
      }) {
    _productImageUrl = productImageUrl;
    _productThumbnailUrl = productThumbnailUrl;
    _brandImageUrl = brandImageUrl;
    _customerImageUrl = customerImageUrl;
    _bannerImageUrl = bannerImageUrl;
    _categoryImageUrl = categoryImageUrl;
    _reviewImageUrl = reviewImageUrl;
    _sellerImageUrl = sellerImageUrl;
    _shopImageUrl = shopImageUrl;
    _notificationImageUrl = notificationImageUrl;
    _deliverymanImageUrl = deliverymanImageUrl;
  }

  String? get productImageUrl => _productImageUrl;
  String? get productThumbnailUrl => _productThumbnailUrl;
  String? get brandImageUrl => _brandImageUrl;
  String? get customerImageUrl => _customerImageUrl;
  String? get bannerImageUrl => _bannerImageUrl;
  String? get categoryImageUrl => _categoryImageUrl;
  String? get reviewImageUrl => _reviewImageUrl;
  String? get sellerImageUrl => _sellerImageUrl;
  String? get shopImageUrl => _shopImageUrl;
  String? get notificationImageUrl => _notificationImageUrl;
  String? get deliverymanImageUrl => _deliverymanImageUrl;


  BaseUrls.fromJson(Map<String, dynamic> json) {
    _productImageUrl = json['product_image_url'];
    _productThumbnailUrl = json['product_thumbnail_url'];
    _brandImageUrl = json['brand_image_url'];
    _customerImageUrl = json['customer_image_url'];
    _bannerImageUrl = json['banner_image_url'];
    _categoryImageUrl = json['category_image_url'];
    _reviewImageUrl = json['review_image_url'];
    _sellerImageUrl = json['seller_image_url'];
    _shopImageUrl = json['shop_image_url'];
    _notificationImageUrl = json['notification_image_url'];
    _deliverymanImageUrl = json['delivery_man_image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_image_url'] = _productImageUrl;
    data['product_thumbnail_url'] = _productThumbnailUrl;
    data['brand_image_url'] = _brandImageUrl;
    data['customer_image_url'] = _customerImageUrl;
    data['banner_image_url'] = _bannerImageUrl;
    data['category_image_url'] = _categoryImageUrl;
    data['review_image_url'] = _reviewImageUrl;
    data['seller_image_url'] = _sellerImageUrl;
    data['shop_image_url'] = _shopImageUrl;
    data['notification_image_url'] = _notificationImageUrl;
    data['delivery_man_image_url'] = _deliverymanImageUrl;
    return data;
  }
}

class StaticUrls {
  String? _contactUs;
  String? _brands;
  String? _categories;
  String? _customerAccount;

  StaticUrls(
      {String? contactUs,
        String? brands,
        String? categories,
        String? customerAccount}) {
    _contactUs = contactUs;
    _brands = brands;
    _categories = categories;
    _customerAccount = customerAccount;
  }

  String? get contactUs => _contactUs;
  String? get brands => _brands;
  String? get categories => _categories;
  String? get customerAccount => _customerAccount;


  StaticUrls.fromJson(Map<String, dynamic> json) {
    _contactUs = json['contact_us'];
    _brands = json['brands'];
    _categories = json['categories'];
    _customerAccount = json['customer_account'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['contact_us'] = _contactUs;
    data['brands'] = _brands;
    data['categories'] = _categories;
    data['customer_account'] = _customerAccount;
    return data;
  }
}

class SocialLogin {
  String? _loginMedium;
  bool? _status;

  SocialLogin({String? loginMedium, bool? status}) {
    _loginMedium = loginMedium;
    _status = status;
  }

  String? get loginMedium => _loginMedium;
  bool? get status => _status;

  SocialLogin.fromJson(Map<String, dynamic> json) {
    _loginMedium = json['login_medium'];
    _status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['login_medium'] = _loginMedium;
    data['status'] = _status;
    return data;
  }
}

class Faq {
  int? _id;
  String? _question;
  String? _answer;
  int? _ranking;
  int? _status;
  String? _createdAt;
  String? _updatedAt;

  Faq(
      {int? id,
        String? question,
        String? answer,
        int? ranking,
        int? status,
        String? createdAt,
        String? updatedAt}) {
    _id = id;
    _question = question;
    _answer = answer;
    _ranking = ranking;
    _status = status;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  int? get id => _id;
  String? get question => _question;
  String? get answer => _answer;
  int? get ranking => _ranking;
  int? get status => _status;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;


  Faq.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _question = json['question'];
    _answer = json['answer'];
    _ranking = json['ranking'];
    _status = json['status'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['question'] = _question;
    data['answer'] = _answer;
    data['ranking'] = _ranking;
    data['status'] = _status;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    return data;
  }
}

class CurrencyList {
  int? _id;
  String? _name;
  String? _symbol;
  String? _code;
  double? _exchangeRate;
  String? _createdAt;
  String? _updatedAt;

  CurrencyList(
      {int? id,
        String? name,
        String? symbol,
        String? code,
        double? exchangeRate,
        int? status,
        String? createdAt,
        String? updatedAt}) {
    _id = id;
    _name = name;
    _symbol = symbol;
    _code = code;
    _exchangeRate = exchangeRate;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  int? get id => _id;
  String? get name => _name;
  String? get symbol => _symbol;
  String? get code => _code;
  double? get exchangeRate => _exchangeRate;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;


  CurrencyList.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _symbol = json['symbol'];
    _code = json['code'];
    if(json['exchange_rate'] != null){
      try{
        _exchangeRate = json['exchange_rate'].toDouble();
      }catch(e){
        _exchangeRate = double.parse(json['exchange_rate'].toString());
      }
    }

    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

}

class Colors {
  int? _id;
  String? _name;
  String? _code;
  String? _createdAt;
  String? _updatedAt;

  Colors(
      {int? id, String? name, String? code, String? createdAt, String? updatedAt}) {
    _id = id;
    _name = name;
    _code = code;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  int? get id => _id;
  String? get name => _name;
  String? get code => _code;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;


  Colors.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _name = json['name'];
    _code = json['code'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = _id;
    data['name'] = _name;
    data['code'] = _code;
    data['created_at'] = _createdAt;
    data['updated_at'] = _updatedAt;
    return data;
  }
}


class DefaultLocation {
  String? lat;
  String? lng;

  DefaultLocation({this.lat, this.lng});

  DefaultLocation.fromJson(Map<String, dynamic> json) {
    lat = json['lat']?.toString();
    lng = json['lng']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}


class MaintenanceMode {
  int? maintenanceStatus;
  SelectedMaintenanceSystem? selectedMaintenanceSystem;
  MaintenanceMessages? maintenanceMessages;
  MaintenanceTypeAndDuration? maintenanceTypeAndDuration;

  MaintenanceMode(
      {this.maintenanceStatus,
        this.selectedMaintenanceSystem,
        this.maintenanceMessages, this.maintenanceTypeAndDuration});

  MaintenanceMode.fromJson(Map<String, dynamic> json) {
    maintenanceStatus = int.tryParse(json['maintenance_status'].toString());
    selectedMaintenanceSystem = json['selected_maintenance_system'] != null
        ? SelectedMaintenanceSystem.fromJson(
        json['selected_maintenance_system'])
        : null;
    maintenanceMessages = json['maintenance_messages'] != null
        ? MaintenanceMessages.fromJson(json['maintenance_messages'])
        : null;

    maintenanceTypeAndDuration = json['maintenance_type_and_duration'] != null
        ? MaintenanceTypeAndDuration.fromJson(
        json['maintenance_type_and_duration'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['maintenance_status'] = maintenanceStatus;
    if (selectedMaintenanceSystem != null) {
      data['selected_maintenance_system'] =
          selectedMaintenanceSystem!.toJson();
    }
    if (maintenanceMessages != null) {
      data['maintenance_messages'] = maintenanceMessages!.toJson();
    }
    if (maintenanceTypeAndDuration != null) {
      data['maintenance_type_and_duration'] =
          maintenanceTypeAndDuration!.toJson();
    }
    return data;
  }
}

class SelectedMaintenanceSystem {
  int? branchPanel;
  int? customerApp;
  int? webApp;
  int? deliverymanApp;

  SelectedMaintenanceSystem(
      {this.branchPanel, this.customerApp, this.webApp, this.deliverymanApp});

  SelectedMaintenanceSystem.fromJson(Map<String, dynamic> json) {
    deliverymanApp = int.tryParse(json['deliveryman_app'].toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['branch_panel'] = branchPanel;
    data['customer_app'] = customerApp;
    data['web_app'] = webApp;
    data['deliveryman_app'] = deliverymanApp;
    return data;
  }
}

class MaintenanceMessages {
  int? businessNumber;
  int? businessEmail;
  String? maintenanceMessage;
  String? messageBody;

  MaintenanceMessages(
      {this.businessNumber,
        this.businessEmail,
        this.maintenanceMessage,
        this.messageBody});

  MaintenanceMessages.fromJson(Map<String, dynamic> json) {
    businessNumber = json['business_number'];
    businessEmail = json['business_email'];
    maintenanceMessage = json['maintenance_message'];
    messageBody = json['message_body'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['business_number'] = businessNumber;
    data['business_email'] = businessEmail;
    data['maintenance_message'] = maintenanceMessage;
    data['message_body'] = messageBody;
    return data;
  }
}

class MaintenanceTypeAndDuration {
  String? _maintenanceDuration;
  String? _startDate;
  String? _endDate;

  MaintenanceTypeAndDuration(
      {String? maintenanceDuration, String? startDate, String? endDate}) {
    if (maintenanceDuration != null) {
      _maintenanceDuration = maintenanceDuration;
    }
    if (startDate != null) {
      _startDate = startDate;
    }
    if (endDate != null) {
      _endDate = endDate;
    }
  }

  String? get maintenanceDuration => _maintenanceDuration;
  set setMaintenanceDuration(String? maintenanceDuration) => _maintenanceDuration = maintenanceDuration;

  String? get startDate => _startDate;
  set setStartDate(String? startDate) => _startDate = startDate;
  String? get setEndDate => _endDate;
  set endDate(String? endDate) => _endDate = endDate;

  MaintenanceTypeAndDuration.fromJson(Map<String, dynamic> json) {
    _maintenanceDuration = json['maintenance_duration'];
    _startDate = json['start_date'];
    _endDate = json['end_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['maintenance_duration'] = _maintenanceDuration;
    data['start_date'] = _startDate;
    data['end_date'] = _endDate;
    return data;
  }
}


class InHouseTemporaryClose {
  int? status;
  InHouseTemporaryClose({this.status});

  InHouseTemporaryClose.fromJson(Map<String, dynamic> json) {
    status = int.tryParse(json['status'].toString()) ?? 0;
  }
}

class InHouseVacationAdd {
  bool? status;
  DateTime? vacationStartDate;
  DateTime? vacationEndDate;
  VacationDurationType? vacationDurationType;
  String? vacationNote;

  InHouseVacationAdd(
      {this.status,
        this.vacationStartDate,
        this.vacationEndDate,
        this.vacationNote,
        this.vacationDurationType,
      });

  InHouseVacationAdd.fromJson(Map<String, dynamic> json) {
    status = '${json['status']}'.contains('1');
    vacationStartDate = DateTime.tryParse(json['vacation_start_date'].toString());
    vacationEndDate = DateTime.tryParse(json['vacation_end_date'].toString());
    vacationNote = json['vacation_note'];
    if (json['vacation_duration_type'] != null) {
      vacationDurationType = VacationDurationType.fromJson(json['vacation_duration_type']);
    }
  }
}

class InHouseShop {
  final int? id;
  final int? sellerId;
  final String? authorType;
  final String? name;
  final String? slug;
  final String? contact;
  final String? address;
  final String? image;
  final String? imageStorageType;
  final String? banner;
  final String? bannerStorageType;
  final String? offerBanner;
  final String? offerBannerStorageType;
  final String? bottomBanner;
  final String? bottomBannerStorageType;
  final int? vacationDurationType;
  final String? vacationStartDate;
  final String? vacationEndDate;
  final String? vacationNote;
  final bool? vacationStatus;
  final bool? temporaryClose;
  final String? updatedAt;
  final String? createdAt;

  final ImageFullUrl? imageFullUrl;
  final ImageFullUrl? bannerFullUrl;
  final ImageFullUrl? offerBannerFullUrl;
  final ImageFullUrl? bottomBannerFullUrl;
  final ImageFullUrl? tinCertificateFullUrl;

  InHouseShop({
    this.id,
    this.sellerId,
    this.authorType,
    this.name,
    this.slug,
    this.contact,
    this.address,
    this.image,
    this.imageStorageType,
    this.banner,
    this.bannerStorageType,
    this.offerBanner,
    this.offerBannerStorageType,
    this.bottomBanner,
    this.bottomBannerStorageType,
    this.vacationDurationType,
    this.vacationStartDate,
    this.vacationEndDate,
    this.vacationNote,
    this.vacationStatus,
    this.temporaryClose,
    this.updatedAt,
    this.createdAt,
    this.imageFullUrl,
    this.bannerFullUrl,
    this.offerBannerFullUrl,
    this.bottomBannerFullUrl,
    this.tinCertificateFullUrl,
  });

  factory InHouseShop.fromJson(Map<String, dynamic> json) => InHouseShop(
    id: json['id'],
    sellerId: json['seller_id'],
    authorType: json['author_type'],
    name: json['name'],
    slug: json['slug'],
    contact: json['contact'],
    address: json['address'],
    image: json['image'],
    imageStorageType: json['image_storage_type'],
    banner: json['banner'],
    bannerStorageType: json['banner_storage_type'],
    offerBanner: json['offer_banner'],
    offerBannerStorageType: json['offer_banner_storage_type'],
    bottomBanner: json['bottom_banner'],
    bottomBannerStorageType: json['bottom_banner_storage_type'],
    vacationDurationType: int.tryParse(json['vacation_duration_type'].toString()),
    vacationStartDate: json['vacation_start_date'],
    vacationEndDate: json['vacation_end_date'],
    vacationNote: json['vacation_note'],
    vacationStatus: json['vacation_status'],
    temporaryClose: json['temporary_close'],
    updatedAt: json['updated_at'],
    createdAt: json['created_at'],
    imageFullUrl: json['image_full_url'] != null
        ? ImageFullUrl.fromJson(json['image_full_url'])
        : null,
    bannerFullUrl: json['banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['banner_full_url'])
        : null,
    offerBannerFullUrl: json['offer_banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['offer_banner_full_url'])
        : null,
    bottomBannerFullUrl: json['bottom_banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['bottom_banner_full_url'])
        : null,
    tinCertificateFullUrl: json['tin_certificate_full_url'] != null
        ? ImageFullUrl.fromJson(json['tin_certificate_full_url'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'author_type': authorType,
    'name': name,
    'slug': slug,
    'contact': contact,
    'address': address,
    'image': image,
    'image_storage_type': imageStorageType,
    'banner': banner,
    'banner_storage_type': bannerStorageType,
    'offer_banner': offerBanner,
    'offer_banner_storage_type': offerBannerStorageType,
    'bottom_banner': bottomBanner,
    'bottom_banner_storage_type': bottomBannerStorageType,
    'vacation_duration_type': vacationDurationType,
    'vacation_start_date': vacationStartDate,
    'vacation_end_date': vacationEndDate,
    'vacation_note': vacationNote,
    'vacation_status': vacationStatus,
    'temporary_close': temporaryClose,
    'updated_at': updatedAt,
    'created_at': createdAt,
    'image_full_url': imageFullUrl?.toJson(),
    'banner_full_url': bannerFullUrl?.toJson(),
    'offer_banner_full_url': offerBannerFullUrl?.toJson(),
    'bottom_banner_full_url': bottomBannerFullUrl?.toJson(),
    'tin_certificate_full_url': tinCertificateFullUrl?.toJson(),
  };
}

class DeliveryManAppVersionControl {
  final AppVersion forAndroid;
  final AppVersion forIos;

  DeliveryManAppVersionControl({
    required this.forAndroid,
    required this.forIos,
  });

  factory DeliveryManAppVersionControl.fromJson(Map<String, dynamic> json) {
    return DeliveryManAppVersionControl(
      forAndroid: AppVersion.fromJson(json['for_android']),
      forIos: AppVersion.fromJson(json['for_ios']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'for_android': forAndroid.toJson(),
      'for_ios': forIos.toJson(),
    };
  }
}

class AppVersion {
  final int status;
  final String version;
  final String link;

  AppVersion({
    required this.status,
    required this.version,
    required this.link,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      version: json['version'] ?? '',
      link: json['link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'version': version,
      'link': link,
    };
  }
}


