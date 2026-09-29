class TipSummaryModel {
  bool? supported;
  bool? tipSystemEnabled;
  double? totalTipEarned;
  String? totalTipEarnedFormatted;
  double? totalTipPending;
  String? totalTipPendingFormatted;
  double? todayTipEarned;
  double? thisWeekTipEarned;
  double? thisMonthTipEarned;
  int? ordersWithTipCount;
  int? pendingOrdersWithTipCount;

  TipSummaryModel({
    this.supported,
    this.tipSystemEnabled,
    this.totalTipEarned,
    this.totalTipEarnedFormatted,
    this.totalTipPending,
    this.totalTipPendingFormatted,
    this.todayTipEarned,
    this.thisWeekTipEarned,
    this.thisMonthTipEarned,
    this.ordersWithTipCount,
    this.pendingOrdersWithTipCount,
  });

  bool get isEnabled => supported == true && tipSystemEnabled == true;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    try {
      return value.toDouble();
    } catch (_) {
      return double.tryParse(value.toString());
    }
  }

  factory TipSummaryModel.fromJson(Map<String, dynamic> json) {
    return TipSummaryModel(
      supported: json['supported'] == true,
      tipSystemEnabled: json['tip_system_enabled'] == true,
      totalTipEarned: _toDouble(json['total_tip_earned']),
      totalTipEarnedFormatted: json['total_tip_earned_formatted']?.toString(),
      totalTipPending: _toDouble(json['total_tip_pending']),
      totalTipPendingFormatted: json['total_tip_pending_formatted']?.toString(),
      todayTipEarned: _toDouble(json['today_tip_earned']),
      thisWeekTipEarned: _toDouble(json['this_week_tip_earned']),
      thisMonthTipEarned: _toDouble(json['this_month_tip_earned']),
      ordersWithTipCount: int.tryParse('${json['orders_with_tip_count']}'),
      pendingOrdersWithTipCount:
          int.tryParse('${json['pending_orders_with_tip_count']}'),
    );
  }
}
