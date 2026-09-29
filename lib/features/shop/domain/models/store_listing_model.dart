class StoreListingModel {
  bool? supported;
  bool? isStoreActive;
  bool? isVisibleOnStorefront;
  bool? canShowInApp;
  String? message;

  StoreListingModel({
    this.supported,
    this.isStoreActive,
    this.isVisibleOnStorefront,
    this.canShowInApp,
    this.message,
  });

  factory StoreListingModel.fromJson(Map<String, dynamic> json) {
    return StoreListingModel(
      supported: parseBool(json['supported']),
      isStoreActive: parseBool(json['is_store_active']),
      isVisibleOnStorefront: parseBool(json['is_visible_on_storefront']),
      canShowInApp: parseBool(json['can_show_in_app']),
      message: json['message']?.toString(),
    );
  }

  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final normalized = value.toString().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }
}
