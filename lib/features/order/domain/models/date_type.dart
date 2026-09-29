enum DateType {
  overall('all_time'),
  today('today'),
  thisWeek('this_week'),
  thisMonth('this_month'),
  custom('custom_date');

  final String key;
  const DateType(this.key);


  static DateType fromKey(String key) {
    return DateType.values.firstWhere(
          (e) => e.key == key,
      orElse: () => DateType.overall,
    );
  }

  bool get isCustom => this == DateType.custom;
  bool get isOverall => this == DateType.overall;
}
