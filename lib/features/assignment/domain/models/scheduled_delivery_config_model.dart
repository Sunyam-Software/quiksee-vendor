class ScheduledDeliveryConfigModel {
  final bool scheduledDeliveryEnabled;
  final String? assignmentRule;
  final int pollOffersIntervalSeconds;
  final int leadTimeMinutes;

  const ScheduledDeliveryConfigModel({
    this.scheduledDeliveryEnabled = false,
    this.assignmentRule,
    this.pollOffersIntervalSeconds = 10,
    this.leadTimeMinutes = 30,
  });

  factory ScheduledDeliveryConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScheduledDeliveryConfigModel();
    final nested = json['scheduled_delivery'];
    final nestedMap =
        nested is Map ? Map<String, dynamic>.from(nested) : null;
    return ScheduledDeliveryConfigModel(
      scheduledDeliveryEnabled: json['scheduled_delivery_enabled'] == true ||
          nestedMap?['scheduled_delivery_enabled'] == true,
      assignmentRule: json['assignment_rule']?.toString() ??
          nestedMap?['assignment_rule']?.toString(),
      pollOffersIntervalSeconds:
          int.tryParse('${json['poll_offers_interval_seconds'] ?? nestedMap?['poll_offers_interval_seconds']}') ??
              10,
      leadTimeMinutes:
          int.tryParse('${json['lead_time_minutes'] ?? nestedMap?['lead_time_minutes']}') ??
              30,
    );
  }
}
