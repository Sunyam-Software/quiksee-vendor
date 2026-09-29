class DynamicFieldDefinition {
  final String fieldKey;
  final String label;
  final String fieldType;
  final List<String> options;
  final bool isRequired;
  final int sortOrder;

  DynamicFieldDefinition({
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.options,
    required this.isRequired,
    required this.sortOrder,
  });

  factory DynamicFieldDefinition.fromJson(Map<String, dynamic> json) {
    return DynamicFieldDefinition(
      fieldKey: '${json['field_key'] ?? ''}',
      label: '${json['label'] ?? ''}',
      fieldType: '${json['field_type'] ?? 'text'}',
      options: List<String>.from(json['options'] ?? []),
      isRequired: json['is_required'] == true || json['is_required'] == 1,
      sortOrder: int.tryParse('${json['sort_order'] ?? 0}') ?? 0,
    );
  }
}

class DynamicFieldDisplayRow {
  final String fieldKey;
  final String label;
  final String value;
  final String fieldType;

  DynamicFieldDisplayRow({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.fieldType,
  });

  factory DynamicFieldDisplayRow.fromJson(Map<String, dynamic> json) {
    return DynamicFieldDisplayRow(
      fieldKey: '${json['field_key'] ?? ''}',
      label: '${json['label'] ?? ''}',
      value: '${json['value'] ?? ''}',
      fieldType: '${json['field_type'] ?? 'text'}',
    );
  }

  bool get hasValue => value.trim().isNotEmpty && value.trim() != '—';
}
