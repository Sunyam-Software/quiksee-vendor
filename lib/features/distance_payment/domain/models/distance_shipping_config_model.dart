class DistanceShippingConfigModel {
  bool enabled;
  String? message;
  String? earningFormula;
  String? extraKmFormula;
  DistanceRateConfig? defaultRate;
  List<DistanceRateConfig>? cities;
  List<String>? deliveryCities;
  StoreOrigin? storeOrigin;

  DistanceShippingConfigModel({
    this.enabled = false,
    this.message,
    this.earningFormula,
    this.extraKmFormula,
    this.defaultRate,
    this.cities,
    this.deliveryCities,
    this.storeOrigin,
  });

  factory DistanceShippingConfigModel.fromJson(Map<String, dynamic> json) {
    return DistanceShippingConfigModel(
      enabled: json['enabled'] == true,
      message: json['message']?.toString(),
      earningFormula: json['earning_formula']?.toString(),
      extraKmFormula: json['extra_km_formula']?.toString(),
      defaultRate: json['default'] != null
          ? DistanceRateConfig.fromJson(json['default'])
          : null,
      cities: json['cities'] != null
          ? (json['cities'] as List)
              .map((e) => DistanceRateConfig.fromJson(e))
              .toList()
          : null,
      deliveryCities: json['delivery_cities'] != null
          ? List<String>.from(json['delivery_cities'])
          : null,
      storeOrigin: json['store_origin'] != null
          ? StoreOrigin.fromJson(json['store_origin'])
          : null,
    );
  }
}

class DistanceRateConfig {
  String? city;
  double? baseKm;
  double? baseDeliveryManPay;
  double? perKmRate;

  DistanceRateConfig({
    this.city,
    this.baseKm,
    this.baseDeliveryManPay,
    this.perKmRate,
  });

  factory DistanceRateConfig.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      try {
        return value.toDouble();
      } catch (_) {
        return double.tryParse(value.toString());
      }
    }

    return DistanceRateConfig(
      city: json['city']?.toString(),
      baseKm: toDouble(json['base_km']),
      baseDeliveryManPay: toDouble(json['base_delivery_man_pay']),
      perKmRate: toDouble(json['per_km_rate']),
    );
  }
}

class StoreOrigin {
  double? lat;
  double? lng;

  StoreOrigin({this.lat, this.lng});

  factory StoreOrigin.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      try {
        return value.toDouble();
      } catch (_) {
        return double.tryParse(value.toString());
      }
    }

    return StoreOrigin(
      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),
    );
  }
}
