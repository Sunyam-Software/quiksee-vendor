import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/discount_expense/domain/models/discount_expense_model.dart';
import 'package:quiksee_vendor_app/features/discount_expense/domain/services/discount_expense_service_interface.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';

class DiscountExpenseController extends ChangeNotifier {
  final DiscountExpenseServiceInterface discountExpenseServiceInterface;

  DiscountExpenseController({required this.discountExpenseServiceInterface});

  DiscountExpenseReportModel? _report;
  DiscountExpenseReportModel? get report => _report;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _selectedType = 'all';
  String get selectedType => _selectedType;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayDateFormat = DateFormat('d MMM yyyy');

  static const List<String> typeKeys = [
    'all',
    'product_discount',
    'sale_discount',
    'coupon_discount',
  ];

  Future<void> getReport({bool reset = false}) async {
    if (reset) {
      _report = null;
    }
    _isLoading = true;
    notifyListeners();

    final ApiResponse apiResponse = await discountExpenseServiceInterface.getDiscountExpenseReport(
      type: _selectedType,
      from: _startDate != null ? _apiDateFormat.format(_startDate!) : null,
      to: _endDate != null ? _apiDateFormat.format(_endDate!) : null,
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      try {
        final data = apiResponse.response!.data;
        if (data is Map<String, dynamic>) {
          _report = DiscountExpenseReportModel.fromJson(data);
        } else if (data is Map) {
          _report = DiscountExpenseReportModel.fromJson(Map<String, dynamic>.from(data));
        } else {
          _report = DiscountExpenseReportModel(
            totals: DiscountExpenseTotals(),
            rows: [],
          );
        }
      } catch (_) {
        _report = DiscountExpenseReportModel(
          totals: DiscountExpenseTotals(),
          rows: [],
        );
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setType(String type) {
    if (_selectedType == type) return;
    _selectedType = type;
    getReport(reset: true);
  }

  Future<void> selectDate(String type, BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: type == 'start'
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null) return;
    if (type == 'start') {
      _startDate = date;
    } else {
      _endDate = date;
    }
    notifyListeners();
  }

  void clearFilters({bool reload = true}) {
    _selectedType = 'all';
    _startDate = null;
    _endDate = null;
    if (reload) {
      getReport(reset: true);
    } else {
      notifyListeners();
    }
  }
}
