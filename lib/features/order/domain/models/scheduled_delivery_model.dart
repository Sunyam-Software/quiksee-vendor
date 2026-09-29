class ScheduledDeliveryInfo {
  final bool isScheduled;
  final String? deliveryType;
  final String? label;
  final String? badgeText;
  final String? dateDisplay;
  final String? timeFromDisplay;
  final String? timeToDisplay;
  final String? date;
  final String? timeFrom;
  final String? timeTo;
  final String? vendorNote;
  final String? riderAssignLabel;
  final String? riderAssignAt;
  final bool isBeforeDriverOfferWindow;
  final int driverOfferMinutesBefore;
  final bool scheduledAdminHold;
  final bool pickupFromAdminHub;

  ScheduledDeliveryInfo({
    required this.isScheduled,
    this.deliveryType,
    this.label,
    this.badgeText,
    this.dateDisplay,
    this.timeFromDisplay,
    this.timeToDisplay,
    this.date,
    this.timeFrom,
    this.timeTo,
    this.vendorNote,
    this.riderAssignLabel,
    this.riderAssignAt,
    this.isBeforeDriverOfferWindow = false,
    this.driverOfferMinutesBefore = 30,
    this.scheduledAdminHold = false,
    this.pickupFromAdminHub = false,
  });

  factory ScheduledDeliveryInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ScheduledDeliveryInfo(isScheduled: false);
    }
    return ScheduledDeliveryInfo(
      isScheduled: json['is_scheduled_delivery'] == true,
      deliveryType: json['delivery_type']?.toString(),
      label: json['label']?.toString(),
      badgeText: json['badge_text']?.toString(),
      dateDisplay: json['date_display']?.toString(),
      timeFromDisplay: json['time_from_display']?.toString(),
      timeToDisplay: json['time_to_display']?.toString(),
      date: json['scheduled_delivery_date']?.toString(),
      timeFrom: json['scheduled_delivery_time_from']?.toString(),
      timeTo: json['scheduled_delivery_time_to']?.toString(),
      vendorNote: json['vendor_note']?.toString(),
      riderAssignLabel: json['rider_assign_label']?.toString(),
      riderAssignAt: json['rider_assign_at']?.toString(),
      isBeforeDriverOfferWindow:
          json['is_before_driver_offer_window'] == true ||
              json['is_before_driver_offer_window'] == 1,
      driverOfferMinutesBefore:
          int.tryParse('${json['driver_offer_minutes_before']}') ?? 30,
      scheduledAdminHold: json['scheduled_admin_hold'] == true ||
          json['scheduled_admin_hold'] == 1,
      pickupFromAdminHub: json['pickup_from_admin_hub'] == true ||
          json['pickup_from_admin_hub'] == 1,
    );
  }

  String get displayBadgeText {
    if (badgeText != null && badgeText!.trim().isNotEmpty) {
      return badgeText!;
    }
    if (label != null && label!.trim().isNotEmpty) {
      return 'Scheduled: $label';
    }
    return 'Scheduled delivery';
  }

  String get displayTime {
    final from = timeFromDisplay?.trim() ?? '';
    final to = timeToDisplay?.trim() ?? '';
    if (from.isEmpty) return '';
    if (to.isEmpty || to == from) return from;
    return '$from - $to';
  }

  String? get riderTimingNote {
    final rider = riderAssignLabel?.trim();
    if (rider != null && rider.isNotEmpty) return rider;
    final note = vendorNote?.trim();
    if (note != null && note.isNotEmpty) return note;
    return null;
  }
}
