class DeliveryAreasModel {
  bool? autoAssignEnabled;
  int? dailyOrderLimit;
  bool? servesAllAreas;
  List<DeliveryAreaItem>? areas;
  List<DeliveryZone>? zones;
  AssignmentCircle? assignmentCircle;

  DeliveryAreasModel({
    this.autoAssignEnabled,
    this.dailyOrderLimit,
    this.servesAllAreas,
    this.areas,
    this.zones,
    this.assignmentCircle,
  });

  factory DeliveryAreasModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAreasModel(
      autoAssignEnabled: json['auto_assign_enabled'] == true,
      dailyOrderLimit: int.tryParse('${json['daily_order_limit']}'),
      servesAllAreas: json['serves_all_areas'] == true,
      areas: json['areas'] != null
          ? (json['areas'] as List)
              .map((e) => DeliveryAreaItem.fromJson(e))
              .toList()
          : null,
      zones: json['zones'] != null
          ? (json['zones'] as List)
              .map((e) => DeliveryZone.fromJson(e))
              .toList()
          : null,
      assignmentCircle: json['assignment_circle'] != null
          ? AssignmentCircle.fromJson(json['assignment_circle'])
          : null,
    );
  }

  /// Admin-assigned zone/area names for profile and settings UI.
  List<String> get assignedAreaLabels {
    if (servesAllAreas == true) return const [];
    final labels = <String>[];
    if (zones != null && zones!.isNotEmpty) {
      for (final zone in zones!) {
        final text = zone.label;
        if (text.isNotEmpty) labels.add(text);
      }
    }
    if (labels.isEmpty && areas != null && areas!.isNotEmpty) {
      for (final area in areas!) {
        final text = area.label;
        if (text.isNotEmpty) labels.add(text);
      }
    }
    return labels;
  }
}

class DeliveryAreaItem {
  String? city;
  String? area;
  String? zipcode;

  DeliveryAreaItem({this.city, this.area, this.zipcode});

  factory DeliveryAreaItem.fromJson(Map<String, dynamic> json) {
    return DeliveryAreaItem(
      city: json['city']?.toString(),
      area: json['area']?.toString(),
      zipcode: json['zipcode']?.toString(),
    );
  }

  String get label => [area, city, zipcode].where((e) => e != null && e.isNotEmpty).join(', ');
}

class DeliveryZone {
  int? id;
  String? city;
  String? area;
  String? zipcode;
  double? latitude;
  double? longitude;

  DeliveryZone({
    this.id,
    this.city,
    this.area,
    this.zipcode,
    this.latitude,
    this.longitude,
  });

  String get label =>
      [area, city, zipcode].where((e) => e != null && e.isNotEmpty).join(', ');

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      try {
        return value.toDouble();
      } catch (_) {
        return double.tryParse(value.toString());
      }
    }

    return DeliveryZone(
      id: int.tryParse('${json['id']}'),
      city: json['city']?.toString(),
      area: json['area']?.toString(),
      zipcode: json['zipcode']?.toString(),
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
    );
  }
}

class AssignmentCircle {
  double? lat;
  double? lng;
  double? radius;

  AssignmentCircle({this.lat, this.lng, this.radius});

  factory AssignmentCircle.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      try {
        return value.toDouble();
      } catch (_) {
        return double.tryParse(value.toString());
      }
    }

    return AssignmentCircle(
      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),
      radius: toDouble(json['radius']),
    );
  }
}
