import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/vat_management/domain/models/vat_report_model.dart';
import 'package:quiksee_vendor_app/features/vat_management/domain/services/vat_service_interface.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';

class VatController extends ChangeNotifier {
  VatServiceInterface vatServiceInterface;

  VatController({required this.vatServiceInterface});

  VatReportModel?  _vatReportModel;
  VatReportModel? get vatReportModel => _vatReportModel;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  bool? _isLoading;
  bool? get isLoading => _isLoading;

  bool? _isFilterActive = false;
  bool? get isFilterActive => _isFilterActive;

  String? _orderType;
  String? get orderType => _orderType;

  final DateFormat _dateFormat = DateFormat('d MMM yy');
  DateFormat get dateFormat => _dateFormat;

  void setOrderType(String? type, {bool isUpdate = true}) {
    _orderType = type;
    if (isUpdate) {
      notifyListeners();
    }
  }

  Future<void> getVatReportList(int offset, {String? startDate, String? endDate, String? orderType}) async {
    if (orderType != null) {
      _orderType = orderType;
    }

    _isLoading = true;
    if (offset <= 1) {
      _vatReportModel = null;
    }
    notifyListeners();

    final type = (_orderType ?? '').toLowerCase();
    final bool isPosOnly = type == 'pos';
    final bool isOnlineOnly = type == 'default_type';
    final int limit = (isPosOnly || isOnlineOnly) ? 50 : 10;

    ApiResponse apiResponse = await vatServiceInterface.getVatReport(
      limit,
      offset,
      startDate,
      endDate,
      orderType: _orderType,
    );
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      try {
        _vatReportModel = VatReportModel.fromJson(apiResponse.response!.data);
        if (isPosOnly) {
          _applyPosOnlyFilter();
        } else if (isOnlineOnly) {
          _applyOnlineOnlyFilter();
        }
      } catch (e) {
        _vatReportModel = VatReportModel(
          totalTax: 0,
          totalOrders: 0,
          totalOrderAmount: 0,
          typeWiseTaxesList: [],
          orderTransactions: [],
        );
      }
    } else {
      ApiChecker.checkApi(apiResponse);
    }

    _isLoading = false;
    notifyListeners();
  }

  bool _isPosTransaction(OrderTransactions tx) {
    final orderType = (tx.order?.orderType ?? '').toLowerCase();
    if (orderType.isNotEmpty) {
      return orderType == 'pos';
    }
    if (tx.orderTaxes != null && tx.orderTaxes!.isNotEmpty) {
      return (tx.orderTaxes!.first.orderType ?? '').toLowerCase() == 'pos';
    }
    return false;
  }

  bool _hasOrderTypeInfo(List<OrderTransactions> txs) {
    for (final tx in txs) {
      if ((tx.order?.orderType ?? '').isNotEmpty) return true;
      if (tx.orderTaxes != null &&
          tx.orderTaxes!.isNotEmpty &&
          (tx.orderTaxes!.first.orderType ?? '').isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  void _applyPosOnlyFilter() {
    _rebuildFilteredReport((tx) => _isPosTransaction(tx), groupName: 'POS');
  }

  void _applyOnlineOnlyFilter() {
    _rebuildFilteredReport((tx) => !_isPosTransaction(tx), groupName: 'Order Tax');
  }

  void _rebuildFilteredReport(bool Function(OrderTransactions tx) keep, {required String groupName}) {
    final txs = _vatReportModel?.orderTransactions ?? [];
    if (txs.isEmpty || !_hasOrderTypeInfo(txs)) {
      return;
    }

    final filtered = txs.where(keep).toList();
    if (filtered.length == txs.length) {
      return;
    }

    double totalAmount = 0;
    double totalTax = 0;
    final Map<String, TaxItem> taxMap = {};

    for (final tx in filtered) {
      totalAmount += tx.orderAmount ?? tx.order?.orderAmount ?? 0;
      totalTax += tx.tax ?? tx.order?.totalTaxAmount ?? 0;

      for (final tax in tx.orderTaxes ?? []) {
        final name = tax.taxName ?? tax.tax?.name ?? 'GST';
        final rate = tax.taxRate;
        final key = '$name|${rate ?? 0}';
        final existing = taxMap[key];
        taxMap[key] = TaxItem(
          name: name,
          taxRate: rate,
          totalAmount: (existing?.totalAmount ?? 0) + (tax.beforeTaxAmount ?? 0),
          taxAmount: (existing?.taxAmount ?? 0) + (tax.taxAmount ?? 0),
        );
      }
    }

    _vatReportModel = VatReportModel(
      totalTax: totalTax,
      totalOrders: filtered.length,
      totalOrderAmount: totalAmount,
      totalSize: filtered.length,
      limit: _vatReportModel?.limit,
      offset: _vatReportModel?.offset,
      orderTransactions: filtered,
      typeWiseTaxesList: taxMap.isEmpty
          ? (_vatReportModel?.typeWiseTaxesList ?? [])
          : [TypeWiseTaxesList(name: groupName, data: taxMap.values.toList())],
    );
  }

  void selectDate(String type, BuildContext context) async {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2030),
    ).then((date) async {
      date = date;
      if(date == null){
      }

      DateTime combinedDateTime = DateTime(
        date!.year,
        date.month,
        date.day,
      );

      if (type == 'start'){
        _startDate = combinedDateTime;
      }else{
        _endDate = combinedDateTime;
      }

      notifyListeners();
    });
  }

  void resetReviewData({bool isUpdate = true}) {
    _startDate = null;
    _endDate = null;
    _isFilterActive = false;

    if(isUpdate) {
      notifyListeners();
    }
  }

  void setFilterActive(bool value) {
    _isFilterActive = value;
    notifyListeners();
  }

}