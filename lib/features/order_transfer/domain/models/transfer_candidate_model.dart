class TransferCandidateModel {
  int id;
  String name;
  String phone;
  int isOnline;
  int isBusy;
  /// online | busy | offline
  String availability;
  int selectable;
  double? distanceKm;
  double expectedDeliverymanCharge;
  double expectedTip;
  double expectedIncentive;
  double expectedTotal;

  TransferCandidateModel({
    required this.id,
    required this.name,
    required this.phone,
    this.isOnline = 0,
    this.isBusy = 0,
    this.availability = 'offline',
    this.selectable = 0,
    this.distanceKm,
    this.expectedDeliverymanCharge = 0,
    this.expectedTip = 0,
    this.expectedIncentive = 0,
    this.expectedTotal = 0,
  });

  bool get canSelect => selectable == 1 || (availability == 'online' && isBusy != 1);

  factory TransferCandidateModel.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
    final isOnline = int.tryParse('${json['is_online'] ?? 0}') ?? 0;
    final isBusy = int.tryParse('${json['is_busy'] ?? 0}') ?? 0;
    var availability = (json['availability'] ?? '').toString().trim().toLowerCase();
    if (availability.isEmpty || availability == 'null') {
      if (isOnline != 1) {
        availability = 'offline';
      } else if (isBusy == 1) {
        availability = 'busy';
      } else {
        availability = 'online';
      }
    }
    final selectableRaw = json['selectable'];
    final selectable = selectableRaw == null
        ? (availability == 'online' ? 1 : 0)
        : (int.tryParse('$selectableRaw') ?? 0);
    return TransferCandidateModel(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      isOnline: isOnline,
      isBusy: isBusy,
      availability: availability,
      selectable: selectable,
      distanceKm: json['distance_km'] == null
          ? null
          : double.tryParse('${json['distance_km']}'),
      expectedDeliverymanCharge: d(json['expected_deliveryman_charge']),
      expectedTip: d(json['expected_tip']),
      expectedIncentive: d(json['expected_incentive']),
      expectedTotal: d(json['expected_total']),
    );
  }
}
