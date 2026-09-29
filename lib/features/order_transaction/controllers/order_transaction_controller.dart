import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/order_transaction/domain/models/order_transaction_model.dart';
import 'package:quiksee_vendor_app/features/order_transaction/domain/services/order_transaction_service_interface.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';

class OrderTransactionController extends ChangeNotifier {
  final OrderTransactionServiceInterface orderTransactionServiceInterface;

  OrderTransactionController({required this.orderTransactionServiceInterface});

  OrderTransactionReportModel? _report;
  OrderTransactionReportModel? get report => _report;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _search = '';
  String get search => _search;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  final DateFormat apiDateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat displayDateFormat = DateFormat('dd MMM yyyy');

  Future<void> getReport({bool reset = false, int limit = 20}) async {
    if (reset) {
      _report = null;
    }
    _isLoading = true;
    notifyListeners();

    final ApiResponse apiResponse = await orderTransactionServiceInterface.getOrderTransactions(
      search: _search.isEmpty ? null : _search,
      from: _startDate == null ? null : apiDateFormat.format(_startDate!),
      to: _endDate == null ? null : apiDateFormat.format(_endDate!),
      limit: limit,
      offset: 1,
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final data = apiResponse.response!.data;
      if (data is Map) {
        _report = OrderTransactionReportModel.fromJson(Map<String, dynamic>.from(data));
      } else {
        _report = OrderTransactionReportModel(totalSize: 0, transactions: []);
      }
    } else {
      _report = OrderTransactionReportModel(totalSize: 0, transactions: []);
      ApiChecker.checkApi(apiResponse);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String value, {bool reload = false}) {
    _search = value.trim();
    if (reload) {
      getReport(reset: true);
    }
  }

  Future<void> selectDate(String type, BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: type == 'start' ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    if (type == 'start') {
      _startDate = picked;
    } else {
      _endDate = picked;
    }
    notifyListeners();
  }

  void clearFilters({bool reload = true}) {
    _search = '';
    _startDate = null;
    _endDate = null;
    if (reload) {
      getReport(reset: true);
    } else {
      notifyListeners();
    }
  }
}
