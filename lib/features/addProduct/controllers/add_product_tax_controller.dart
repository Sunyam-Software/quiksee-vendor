import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/product_tax_config_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/tax_vat_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/services/add_product_service_interface.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/helper/api_checker.dart';

class AddProductTaxController extends ChangeNotifier {
  final AddProductServiceInterface addProductServiceInterface;

  AddProductTaxController({required this.addProductServiceInterface});

  List<TaxVatModel> _taxVatList = [];
  List<TaxVatModel> get taxVatList => _taxVatList;

  List<TaxVatModel> _selectedTaxList = [];
  List<TaxVatModel> get selectedTaxList => _selectedTaxList;

  ProductTaxConfig? _taxConfig;
  ProductTaxConfig? get taxConfig => _taxConfig;

  bool _isTaxConfigLoading = false;
  bool get isTaxConfigLoading => _isTaxConfigLoading;

  List<TaxVats>? _pendingTaxVats;

  bool get showTaxSection => _taxConfig?.productWiseTax == true;

  bool get hasTaxConfigLoaded => _taxConfig != null;

  Future<void> getTaxConfig({Product? product}) async {
    List<TaxVats>? taxesToApply = _pendingTaxVats;
    if (product?.taxVats != null && product!.taxVats!.isNotEmpty) {
      taxesToApply = product.taxVats;
    }

    _isTaxConfigLoading = true;
    notifyListeners();

    ApiResponse response = await addProductServiceInterface.getProductTaxConfig();
    if (response.response != null && response.response!.statusCode == 200) {
      final data = response.response!.data;
      if (data is Map<String, dynamic>) {
        _taxConfig = ProductTaxConfig.fromJson(data);
      } else if (data is Map) {
        _taxConfig = ProductTaxConfig.fromJson(Map<String, dynamic>.from(data));
      }

      _taxVatList = [];
      _selectedTaxList = [];
      if (taxesToApply != null && taxesToApply.isNotEmpty) {
        _pendingTaxVats = taxesToApply;
      }

      if (_taxConfig?.productWiseTax == true) {
        for (final rate in _taxConfig!.taxRates) {
          _taxVatList.add(TaxVatModel(
            id: rate.id,
            name: rate.name,
            taxRate: rate.taxRate.toDouble(),
          ));
        }
        if (_taxVatList.isNotEmpty) {
          _taxVatList.insert(0, TaxVatModel(id: 0, name: 'All'));
        }
      }

      _applyPendingTaxVats();
    } else {

      await getTaxVatList(clearSelection: true);
      if (response.response != null) {
        ApiChecker.checkApi(response);
      }
    }

    _isTaxConfigLoading = false;
    notifyListeners();
  }

  Future<void> getTaxVatList({bool clearSelection = true}) async {
    _taxVatList = [];
    if (clearSelection) {
      _selectedTaxList = [];
    }
    ApiResponse response = await addProductServiceInterface.getTaxVatList();
    if (response.response != null && response.response!.statusCode == 200) {
      response.response?.data.forEach((vatTax) {
        _taxVatList.add(TaxVatModel.fromJson(vatTax));
      });

      if (_taxVatList.isNotEmpty) {
        _taxVatList.insert(0, TaxVatModel(id: 0, name: 'All'));
      }
      _applyPendingTaxVats();
    } else {
      ApiChecker.checkApi(response);
    }
    notifyListeners();
  }

  void addToSelectedTaxList(TaxVatModel taxVatModel) {
    if (!isSelected(taxVatModel)) {
      _selectedTaxList.add(taxVatModel);
      notifyListeners();
    }
  }

  void removeToSelectedTaxList(TaxVatModel taxVatModel, int index) {
    _selectedTaxList.removeAt(index);
    notifyListeners();
  }

  bool isSelected(TaxVatModel taxVatModel) {
    for (TaxVatModel tvModel in _selectedTaxList) {
      if (taxVatModel.id == tvModel.id) {
        return true;
      }
    }
    return false;
  }

  void setProductVatTax(List<TaxVats>? taxVats) {
    if (taxVats == null || taxVats.isEmpty) return;
    _pendingTaxVats = taxVats;

    if (_taxVatList.isEmpty) {

      return;
    }

    _applyPendingTaxVats();
    notifyListeners();
  }

  void _applyPendingTaxVats() {
    if (_pendingTaxVats == null || _pendingTaxVats!.isEmpty) return;

    for (TaxVats taxVat in _pendingTaxVats!) {
      TaxVatModel? model = taxVat.tax;
      if (model == null && taxVat.taxId != null) {
        for (final item in _taxVatList) {
          if (item.id == taxVat.taxId) {
            model = item;
            break;
          }
        }
      }
      if (model != null && model.id != null && model.id != 0 && !checkContains(model)) {
        _selectedTaxList.add(model);
      }
    }
    _pendingTaxVats = null;
  }

  void setAIProductVatTax(List<TaxVatModel>? taxVats) {
    if (taxVats != null && taxVats.isNotEmpty) {
      for (TaxVatModel taxVat in taxVats) {
        if (!checkContains(taxVat)) {
          _selectedTaxList.add(taxVat);
        }
      }
    }
    notifyListeners();
  }

  bool checkContains(TaxVatModel? vatTRax) {
    if (_selectedTaxList.isNotEmpty && vatTRax != null) {
      for (TaxVatModel tax in _selectedTaxList) {
        if (tax.id == vatTRax.id) {
          return true;
        }
      }
    }
    return false;
  }

  List<int?> getSelectedTaxIds() {
    return _selectedTaxList
        .map((tax) => tax.id)
        .where((id) => id != null && id != 0)
        .toList();
  }

  void resetTaxSelection({bool notify = false}) {
    _selectedTaxList = [];
    _pendingTaxVats = null;
    if (notify) {
      notifyListeners();
    }
  }
}
