class ScheduledDeliveryInfo {
  final String? deliveryType;
  final bool isScheduledDelivery;
  final String? scheduledDeliveryDate;
  final String? scheduledDeliveryTimeFrom;
  final String? scheduledDeliveryTimeTo;
  final String? label;
  final String? slotStartsAt;
  final bool isSchedulePending;
  final int minutesUntilSlot;
  final String? driverActionLabel;
  final double extraCharge;
  final String? extraChargeFormatted;
  final bool scheduledAdminHold;
  final String? scheduledPickupNote;
  final String? pickupPointNote;
  final String? timeFromDisplay;
  final String? timeToDisplay;

  const ScheduledDeliveryInfo({
    this.deliveryType,
    this.isScheduledDelivery = false,
    this.scheduledDeliveryDate,
    this.scheduledDeliveryTimeFrom,
    this.scheduledDeliveryTimeTo,
    this.label,
    this.slotStartsAt,
    this.isSchedulePending = false,
    this.minutesUntilSlot = 0,
    this.driverActionLabel,
    this.extraCharge = 0,
    this.extraChargeFormatted,
    this.scheduledAdminHold = false,
    this.scheduledPickupNote,
    this.pickupPointNote,
    this.timeFromDisplay,
    this.timeToDisplay,
  });

  factory ScheduledDeliveryInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScheduledDeliveryInfo();
    final pickup = json['pickup_point_note']?.toString() ??
        json['scheduled_pickup_note']?.toString();
    return ScheduledDeliveryInfo(
      deliveryType: json['delivery_type']?.toString(),
      isScheduledDelivery: json['is_scheduled_delivery'] == true ||
          json['is_scheduled_delivery'] == 1,
      scheduledDeliveryDate: json['scheduled_delivery_date']?.toString(),
      scheduledDeliveryTimeFrom:
          json['scheduled_delivery_time_from']?.toString(),
      scheduledDeliveryTimeTo: json['scheduled_delivery_time_to']?.toString(),
      label: json['label']?.toString(),
      slotStartsAt: json['slot_starts_at']?.toString(),
      isSchedulePending: json['is_schedule_pending'] == true,
      minutesUntilSlot:
          int.tryParse('${json['minutes_until_slot']}') ?? 0,
      driverActionLabel: json['driver_action_label']?.toString(),
      extraCharge: double.tryParse('${json['extra_charge']}') ?? 0,
      extraChargeFormatted: json['extra_charge_formatted']?.toString(),
      scheduledAdminHold: json['scheduled_admin_hold'] == true ||
          json['scheduled_admin_hold'] == 1,
      scheduledPickupNote: json['scheduled_pickup_note']?.toString(),
      pickupPointNote: pickup,
      timeFromDisplay: json['time_from_display']?.toString(),
      timeToDisplay: json['time_to_display']?.toString(),
    );
  }

  String? get displayPickupNote {
    final note = (pickupPointNote ?? scheduledPickupNote)?.trim();
    if (note == null || note.isEmpty) return null;
    return note;
  }
}

String? formatScheduledDeliveryTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return raw;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = parts[1].length >= 2 ? parts[1].substring(0, 2) : parts[1];
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '${hour12.toString().padLeft(2, '0')}:$minute $suffix';
}
