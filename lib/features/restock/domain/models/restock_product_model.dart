import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';

class RestockProductModel {
  List<Data>? data;
  int? totalSize;
  int? limit;
  int? offset;

  RestockProductModel({this.data, this.totalSize, this.limit, this.offset});

  RestockProductModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    return data;
  }

}

class Data {
  int? id;
  int? productId;
  String? variant;
  String? createdAt;
  String? updatedAt;
  int? restockProductCustomersCount;
  Product? product;
  List<String>? variantKeys;

  Data(
      {this.id,
        this.productId,
        this.variant,
        this.createdAt,
        this.updatedAt,
        this.restockProductCustomersCount,
        this.product,
        this.variantKeys
      });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    variant = json['variant'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    restockProductCustomersCount = json['restock_product_customers_count'];
    product =
    json['product'] != null ? Product.fromJson(json['product']) : null;
    if(json['variant_keys'] != null) {

      variantKeys = (json['variant_keys'] as List<dynamic>?)
          ?.where((element) => element != null)
          .map((element) => element as String)
          .toList();
    }else {
      variantKeys = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['variant'] = variant;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['restock_product_customers_count'] = restockProductCustomersCount;
    return data;
  }
}

