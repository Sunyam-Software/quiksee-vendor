import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/features/dynamic_fields/domain/models/dynamic_field_models.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class DynamicFieldController extends ChangeNotifier {
  final DioClient dioClient;

  DynamicFieldController({required this.dioClient});

  String _module = 'product';
  bool _loading = false;
  List<DynamicFieldDefinition> _definitions = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _values = {};
  final Map<String, DateTime?> _dates = {};
  List<DynamicFieldDisplayRow> _displayRows = [];

  bool get isLoading => _loading;
  String get module => _module;
  List<DynamicFieldDefinition> get definitions => _definitions;
  List<DynamicFieldDisplayRow> get displayRows =>
      _displayRows.where((row) => row.hasValue).toList();

  Future<void> loadDefinitions(String module) async {
    _module = module;
    _loading = true;
    notifyListeners();

    try {
      final response = await dioClient.get(
        AppConstants.dynamicFieldsUri,
        queryParameters: {'module': module},
      );
      final dynamic fields = response.data?['fields'];
      _definitions = [];
      if (fields is List) {
        _definitions = fields
            .map((item) =>
                DynamicFieldDefinition.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
      _ensureControllers();
    } catch (e) {
      _definitions = [];
      debugPrint('DynamicFieldController.loadDefinitions: ${ApiErrorHandler.getMessage(e)}');
    }

    _loading = false;
    notifyListeners();
  }

  void applyApiPayload(Map<String, dynamic>? json) {
    if (json == null) return;

    final dynamic defs = json['dynamic_field_definitions'];
    if (defs is List && defs.isNotEmpty) {
      _definitions = defs
          .map((item) =>
              DynamicFieldDefinition.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      _ensureControllers();
    }

    final dynamic values = json['dynamic_field_values'];
    if (values is Map) {
      loadValues(Map<String, dynamic>.from(values));
    }

    final dynamic display = json['dynamic_field_display'];
    if (display is List) {
      _displayRows = display
          .map((item) =>
              DynamicFieldDisplayRow.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (_definitions.isNotEmpty) {
      _displayRows = _definitions
          .map((def) => DynamicFieldDisplayRow(
                fieldKey: def.fieldKey,
                label: def.label,
                value: _values[def.fieldKey] ?? '—',
                fieldType: def.fieldType,
              ))
          .toList();
    }

    notifyListeners();
  }

  void loadValues(Map<String, dynamic> values) {
    for (final def in _definitions) {
      final raw = values[def.fieldKey];
      final value = raw == null ? '' : '$raw';
      _values[def.fieldKey] = value;
      _controllers[def.fieldKey]?.text = value;
      if (def.fieldType == 'date' && value.isNotEmpty) {
        _dates[def.fieldKey] = DateTime.tryParse(value);
      }
      if (def.fieldType == 'checkbox') {
        _values[def.fieldKey] = value == '1' ? '1' : '0';
      }
    }
    notifyListeners();
  }

  void setValue(String fieldKey, String value) {
    _values[fieldKey] = value;
    _controllers[fieldKey]?.text = value;
    notifyListeners();
  }

  void setCheckbox(String fieldKey, bool checked) {
    setValue(fieldKey, checked ? '1' : '0');
  }

  void setDate(String fieldKey, DateTime? date) {
    _dates[fieldKey] = date;
    if (date == null) {
      setValue(fieldKey, '');
      return;
    }
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    setValue(fieldKey, formatted);
  }

  Map<String, String> getPayload() {
    final Map<String, String> payload = {};
    for (final def in _definitions) {
      if (def.fieldType == 'checkbox') {
        payload[def.fieldKey] = _values[def.fieldKey] == '1' ? '1' : '0';
      } else {
        payload[def.fieldKey] = _values[def.fieldKey]?.trim() ?? '';
      }
    }
    return payload;
  }

  String? validateLocally() {
    for (final def in _definitions) {
      if (!def.isRequired) continue;
      final value = getPayload()[def.fieldKey] ?? '';
      if (def.fieldType == 'checkbox') {
        if (value != '1') return '${def.label} is required';
      } else if (value.isEmpty) {
        return '${def.label} is required';
      }
    }
    return null;
  }

  TextEditingController controllerFor(String fieldKey) {
    return _controllers.putIfAbsent(fieldKey, TextEditingController.new);
  }

  DateTime? dateFor(String fieldKey) => _dates[fieldKey];

  bool isChecked(String fieldKey) => _values[fieldKey] == '1';

  void reset() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _values.clear();
    _dates.clear();
    _definitions = [];
    _displayRows = [];
    _module = 'product';
    notifyListeners();
  }

  void _ensureControllers() {
    for (final def in _definitions) {
      _controllers.putIfAbsent(def.fieldKey, TextEditingController.new);
      _values.putIfAbsent(def.fieldKey, () => '');
      if (def.fieldType == 'checkbox') {
        _values[def.fieldKey] = _values[def.fieldKey] ?? '0';
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
