import 'package:quiksee_vendor_app/data/model/image_full_url.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/store_listing_model.dart';
import 'package:quiksee_vendor_app/helper/date_converter.dart';

class ShopModel {
  int? id;
  String? name;
  String? address;
  String? contact;
  String? image;
  ImageFullUrl? imageFullUrl;
  String? createdAt;
  String? updatedAt;
  String? banner;
  ImageFullUrl? bannerFullUrl;
  ImageFullUrl? tinCertificateFullUrl;
  String? bottomBanner;
  ImageFullUrl? bottomBannerFullUrl;
  String? offerBanner;
  ImageFullUrl? offerBannerFullUrl;
  double? ratting;
  int? rattingCount;
  bool? temporaryClose;
  bool? isStoreActive;
  StoreListingModel? storeListing;
  String? vacationEndDate;
  String? vacationStartDate;
  bool? vacationStatus;
  String? vacationDurationType;
  String? vacationNote;
  String? taxIdentificationNumber;
  String? tinExpireDate;
  int? totalReview;
  int? totalOrder;
  int? totalProducts;
  int? reorderLevel;
  int? preparationTime;
  Map<String, dynamic>? setupGuideApp;
  Map<String, String>? dynamicFieldValues;

  ShopModel(
      {this.id,
        this.name,
        this.address,
        this.contact,
        this.image,
        this.imageFullUrl,
        this.createdAt,
        this.updatedAt,
        this.banner,
        this.bannerFullUrl,
        this.tinCertificateFullUrl,
        this.bottomBanner,
        this.bottomBannerFullUrl,
        this.offerBanner,
        this.offerBannerFullUrl,
        this.ratting,
        this.rattingCount,
        this.temporaryClose,
        this.isStoreActive,
        this.storeListing,
        this.vacationEndDate,
        this.vacationStartDate,
        this.vacationStatus,
        this.vacationDurationType,
        this.vacationNote,
        this.taxIdentificationNumber,
        this.tinExpireDate,
        this.totalReview,
        this.totalOrder,
        this.totalProducts,
        this.setupGuideApp,
        this.reorderLevel,
        this.preparationTime,
      });

  ShopModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    contact = json['contact'];
    image = json['image'];
    imageFullUrl = json['image_full_url'] != null
      ? ImageFullUrl.fromJson(json['image_full_url'])
      : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    banner = json['banner'];
    bottomBanner = json['bottom_banner'];
    offerBanner = json['offer_banner'];
    ratting = json['rating'] != null
        ? double.tryParse(json['rating'].toString()) ?? 0
        : 0;
    rattingCount = json['rating_count'] != null
        ? int.tryParse(json['rating_count'].toString())
        : null;

    if (json['temporary_close'] != null) {
      final raw = json['temporary_close'];
      final bool isClosed =
          raw == true || raw == 1 || raw == '1';
      temporaryClose = !isClosed;
    } else {
      temporaryClose = true;
    }

    isStoreActive = StoreListingModel.parseBool(json['is_store_active']);
    if (json['store_listing'] is Map) {
      storeListing =
          StoreListingModel.fromJson(json['store_listing'] as Map<String, dynamic>);
      isStoreActive ??= storeListing?.isStoreActive;
    }

    vacationEndDate = json['vacation_end_date'];
    vacationStartDate = json['vacation_start_date'];
    final dynamic vacationRaw = json['vacation_status'];
    vacationStatus = vacationRaw == true ||
        vacationRaw == 1 ||
        vacationRaw == '1';
    offerBannerFullUrl = json['offer_banner_full_url'] != null
      ? ImageFullUrl.fromJson(json['offer_banner_full_url'])
      : null;
    bannerFullUrl = json['banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['banner_full_url'])
        : null;
    bottomBannerFullUrl = json['bottom_banner_full_url'] != null
        ? ImageFullUrl.fromJson(json['bottom_banner_full_url'])
        : null;
    tinCertificateFullUrl = json['tin_certificate_full_url'] != null
      ? ImageFullUrl.fromJson(json['tin_certificate_full_url'])
      : null;
    vacationDurationType = json['vacation_duration_type'] ?? 'custom';
    vacationNote = json['vacation_note'] ?? '';
    taxIdentificationNumber = json['tax_identification_number'];
    final rawTinExpire = json['tin_expire_date']?.toString();
    tinExpireDate = DateConverter.isValidApiDate(rawTinExpire) ? rawTinExpire : null;
    totalProducts = json['total_products'];
    totalOrder = json['total_orders'];
    totalReview = json['total_reviews'];
    setupGuideApp = json['setup_guide_app'] != null
      ? Map<String, dynamic>.from(json['setup_guide_app'])
      : null;

    reorderLevel = json['stock_limit'] != null
      ? int.tryParse(json['stock_limit'].toString())
      : null;

    preparationTime = json['preparation_time'] != null
      ? int.tryParse(json['preparation_time'].toString())
      : null;

    if (json['dynamic_field_values'] is Map) {
      dynamicFieldValues = Map<String, String>.from(
        (json['dynamic_field_values'] as Map).map(
          (key, value) => MapEntry('$key', value == null ? '' : '$value'),
        ),
      );
    }
  }
}
