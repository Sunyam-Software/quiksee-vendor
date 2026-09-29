import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/domain/models/tax_settlement_model.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/domain/services/tax_settlement_service.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';

class TaxSettlementController extends ChangeNotifier {
  final TaxSettlementServiceInterface taxSettlementServiceInterface;

  TaxSettlementController({required this.taxSettlementServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TaxSettlementSummaryModel? _summary;
  TaxSettlementSummaryModel? get summary => _summary;

  TaxSettlementListModel? _listModel;
  TaxSettlementListModel? get listModel => _listModel;

  TaxSettlementModel? _selected;
  TaxSettlementModel? get selected => _selected;

  Future<void> loadList({int offset = 1, bool reset = true}) async {
    _isLoading = true;
    if (reset) {
      _listModel = null;
    }
    notifyListeners();

    final ApiResponse response = await taxSettlementServiceInterface.getList(limit: 20, offset: offset);
    if (response.response != null && response.response!.statusCode == 200) {
      _listModel = TaxSettlementListModel.fromJson(response.response!.data as Map<String, dynamic>);
      _summary = _listModel?.summary;
    } else {
      ApiChecker.checkApi(response);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDetails(int id) async {
    _isLoading = true;
    _selected = null;
    notifyListeners();

    final ApiResponse response = await taxSettlementServiceInterface.getDetails(id);
    if (response.response != null && response.response!.statusCode == 200) {
      _selected = TaxSettlementModel.fromJson(response.response!.data as Map<String, dynamic>);
    } else {
      ApiChecker.checkApi(response);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markPaid({
    required int id,
    required String amount,
    String? reference,
    String? note,
    String? receiptPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    final ApiResponse response = await taxSettlementServiceInterface.markPaid(
      id: id,
      amount: amount,
      reference: reference,
      note: note,
      receiptPath: receiptPath,
    );

    _isLoading = false;
    notifyListeners();

    if (response.response != null && response.response!.statusCode == 200) {
      await loadDetails(id);
      await loadList(reset: true);
      return true;
    }

    ApiChecker.checkApi(response);
    return false;
  }
}
