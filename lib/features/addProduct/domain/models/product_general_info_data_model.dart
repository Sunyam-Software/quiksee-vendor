import 'package:flutter/foundation.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/add_product_model.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';

class ProductGeneralInfoData {
  final String? categoryId;
  final String? subCategoryId;
  final String? subSubCategoryId;
  final String? brandId;
  final String? unit;
  final String title;
  final String description;
  final Product? product;
  final AddProductModel? addProduct;

  ProductGeneralInfoData({
    required this.categoryId,
    required this.subCategoryId,
    required this.subSubCategoryId,
    this.brandId,
    this.unit,
    required this.title,
    required this.description,
    this.product,
    this.addProduct,
  });
}

class ProductCombinedData {

  final String? categoryId;
  final String? subCategoryId;
  final String? subSubCategoryId;
  final String? brandId;
  final String? unit;
  final String? title;
  final String? description;
  final Product? product;
  final AddProductModel? addProduct;

  final String? unitPrice;
  final String? discount;
  final String? currentStock;
  final String? minimumOrderQuantity;
  final List<int?>? tax;
  final String? shippingCost;

  final ValueChanged<bool>? isSelected;

  ProductCombinedData({

    this.categoryId,
    this.subCategoryId,
    this.subSubCategoryId,
    this.brandId,
    this.unit,
    this.title,
    this.description,
    this.product,
    this.addProduct,

    this.unitPrice,
    this.discount,
    this.currentStock,
    this.minimumOrderQuantity,
    this.tax,
    this.shippingCost,

    this.isSelected,
  });
}