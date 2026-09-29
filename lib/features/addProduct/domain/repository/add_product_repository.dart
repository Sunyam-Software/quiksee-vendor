import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' show basename;
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/add_product_model.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/models/image_model.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/product_model.dart';
import 'package:quiksee_vendor_app/features/addProduct/domain/repository/add_product_repository_interface.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/dynamic_fields/controllers/dynamic_field_controller.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class AddProductRepository implements AddProductRepositoryInterface{
  final DioClient? dioClient;
  AddProductRepository({required this.dioClient});

  @override
  Future<ApiResponse> getAttributeList(String languageCode) async {
    try {
      final response = await dioClient!.get(AppConstants.attributeUri,
        options: Options(headers: {AppConstants.langKey: languageCode}),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getEditProduct(int? id) async {
    try {
      final response = await dioClient!.get('${AppConstants.editProductUri}/$id');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getCategoryList(String languageCode) async {
    try {
      final response = await dioClient!.get(AppConstants.categoryUri,
        options: Options(headers: {AppConstants.langKey: languageCode}),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getSubCategoryList() async {
    try {
      final response = await dioClient!.get(AppConstants.categoryUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getSubSubCategoryList() async {
    try {
      final response = await dioClient!.get(AppConstants.categoryUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }

  }

  @override
  Future<ApiResponse> addImage(BuildContext context, ImageModel imageForUpload, bool colorActivate) async {
    try {
      final token = Provider.of<AuthController>(context, listen: false).getUserToken();
      final formData = FormData.fromMap(<String, dynamic>{
        'type': imageForUpload.type ?? '',
        'color': imageForUpload.color ?? '',
        'colors_active': colorActivate.toString(),
      });

      final imagePath = imageForUpload.image?.path;
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'image',
            await MultipartFile.fromFile(
              file.path,
              filename: basename(file.path),
            ),
          ));
        }
      }

      final response = await dioClient!.post(
        AppConstants.uploadProductImageUri,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  void _setRequestHeaders(String? token) {
    dioClient!.dio!.options.headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${token ?? Provider.of<AuthController>(Get.context!, listen: false).getUserToken()}'
    };
  }

  Future<Map<String, dynamic>> _prepareRequestData({
    required Product product,
    required AddProductModel addProduct,
    required Map<String, dynamic> attributes,
    List<Map<String, dynamic>>? productImages,
    String? thumbnail,
    String? metaImage,
    required bool isAdd,
    required bool isActiveColor,
    required List<ColorImage> colorImageObject,
    required List<String?> tags,
    String? digitalFileReady,
    DigitalVariationModel? digitalVariationModel,
    bool? isDigitalVariationActive,
  }) async {
    final fields = <String, dynamic>{};

    _addBasicProductFields(fields, product, addProduct, productImages, thumbnail, metaImage, isActiveColor, tags, digitalFileReady, digitalVariationModel, isAdd);

    if (!(product.productType == 'digital' || (addProduct.colorCodeList != null && addProduct.colorCodeList!.isEmpty))) {
      fields['color_image'] = jsonEncode(_prepareColorImages(colorImageObject));
    } else {
      fields['color_image'] = jsonEncode([]);
    }

    if (product.metaSeoInfo != null) {
      _addMetaSeoFields(fields, product.metaSeoInfo!);
    }

    _addCategoryFields(fields, product.categoryIds);

    if (!isAdd) {
      fields.addAll({'_method': 'put', 'id': product.id});
    }

    if (attributes.isNotEmpty) {
      fields.addAll(attributes);
    }

    if (isDigitalVariationActive == true) {
      _addDigitalVariationFields(fields, digitalVariationModel!);
    }

    if (Get.context != null) {
      final dynamicFieldController =
          Provider.of<DynamicFieldController>(Get.context!, listen: false);
      final dynamicFields = dynamicFieldController.getPayload();
      if (dynamicFields.isNotEmpty) {
        fields['dynamic_fields'] = dynamicFields;
      }
    }

    return fields;
  }

  List<Map<String, dynamic>> _prepareColorImages(List<ColorImage> colorImageObject) {
    return colorImageObject
        .where((image) => image.imageName?.key != 'null' && image.imageName?.key != null)
        .map((image) => {
      'color': image.color,
      'image_name': image.imageName?.key,
      'storage': image.storage ?? 'public',
    }).toList();
  }

  int? _positiveId(dynamic value) {
    final id = int.tryParse('$value');
    return (id != null && id > 0) ? id : null;
  }

  void _addBasicProductFields(
      Map<String, dynamic> fields,
      Product product,
      AddProductModel addProduct,
      List<Map<String, dynamic>>? productImages,
      String? thumbnail,
      String? metaImage,
      bool isActiveColor,
      List<String?> tags,
      String? digitalFileReady,
      DigitalVariationModel? digitalVariationModel,
      bool isAdd,
      ) {
    fields.addAll({
      'name': jsonEncode(addProduct.titleList),
      'description': jsonEncode(addProduct.descriptionList),
      'unit_price': product.unitPrice,
      'discount': product.discount,
      'discount_type': product.discountType,
      'tax_ids': jsonEncode((product.taxIds ?? []).where((id) => id != null && id > 0).toList()),
      'tax_model': (product.taxModel == 'include' || product.taxModel == 'exclude') ? product.taxModel : 'exclude',
      'unit': product.unit,
      'meta_title': product.metaTitle,
      'meta_description': product.metaDescription,
      'lang': jsonEncode(addProduct.languageList),
      'colors': jsonEncode(addProduct.colorCodeList),
      'images': jsonEncode(productImages ?? []),
      'thumbnail': (thumbnail != null && thumbnail.isNotEmpty && thumbnail != 'null')
          ? thumbnail
          : (isAdd ? null : product.thumbnail),
      'colors_active': isActiveColor,
      'video_url': addProduct.videoUrl,
      'meta_image': (metaImage != null && metaImage.isNotEmpty) ? metaImage : null,
      'current_stock': product.currentStock,
      'shipping_cost': product.shippingCost,
      'multiply_qty': product.multiplyWithQuantity,
      'code': product.code,
      'minimum_order_qty': product.minimumOrderQty,
      'preparation_time': product.preparationTime?.toString() ?? '',
      'product_type': product.productType,
      'digital_product_type': product.digitalProductType,
      'digital_file_ready': digitalFileReady ?? product.digitalFileReady,
      'tags': jsonEncode(tags),
      'publishing_house': jsonEncode(digitalVariationModel?.publishingHouse ?? []),
      'authors': jsonEncode(digitalVariationModel?.authors ?? []),
    });

    final categoryId = _positiveId(
      product.categoryIds != null && product.categoryIds!.isNotEmpty
          ? product.categoryIds!.first.id
          : null,
    );
    if (categoryId != null) {
      fields['category_id'] = categoryId;
    }

    if (Provider.of<SplashController>(Get.context!, listen: false).configModel!.brandSetting == "1") {
      final brandId = _positiveId(product.brandId);
      if (brandId != null) {
        fields['brand_id'] = brandId;
      }
    }
  }

  void _addMetaSeoFields(Map<String, dynamic> fields, MetaSeoInfo metaSeoInfo) {
    fields.addAll({
      "meta_index": metaSeoInfo.metaIndex,
      "meta_no_follow": metaSeoInfo.metaNoFollow,
      "meta_no_image_index": metaSeoInfo.metaNoImageIndex,
      "meta_no_archive": metaSeoInfo.metaNoArchive,
      "meta_no_snippet": metaSeoInfo.metaNoSnippet,
      "meta_max_snippet": metaSeoInfo.metaMaxSnippet,
      "meta_max_snippet_value": metaSeoInfo.metaMaxSnippetValue,
      "meta_max_video_preview": metaSeoInfo.metaMaxVideoPreview,
      "meta_max_video_preview_value": metaSeoInfo.metaMaxVideoPreviewValue,
      "meta_max_image_preview": metaSeoInfo.metaMaxImagePreview,
      "meta_max_image_preview_value": metaSeoInfo.metaMaxImagePreviewValue,
    });
  }

  void _addCategoryFields(Map<String, dynamic> fields, List<CategoryIds>? categoryIds) {
    if (categoryIds == null || categoryIds.isEmpty) {
      return;
    }
    if (categoryIds.length > 1 && _positiveId(categoryIds[1].id) != null) {
      fields['sub_category_id'] = categoryIds[1].id;
    }
    if (categoryIds.length > 2 && _positiveId(categoryIds[2].id) != null) {
      fields['sub_sub_category_id'] = categoryIds[2].id;
    }
  }

  void _addDigitalVariationFields(Map<String, dynamic> fields, DigitalVariationModel digitalVariationModel) {
    fields.addAll({
      'extensions_type': jsonEncode(digitalVariationModel.variationType),
      'digital_product_variant_key': jsonEncode(digitalVariationModel.digitalVariantKeyMap),
      'digital_product_sku': jsonEncode(digitalVariationModel.digitalVariantSku),
      'digital_product_price': jsonEncode(digitalVariationModel.digitalVariantPrice),
    });

    if (digitalVariationModel.variationType != null) {
      for (int i = 0; i < digitalVariationModel.variationType!.length; i++) {
        fields['extensions_options_${digitalVariationModel.variationType![i]}'] =
            jsonEncode(digitalVariationModel.variationKeys![i]);
      }
    }
  }

  @override
  Future<ApiResponse> addProduct(Product product, AddProductModel addProduct, Map<String, dynamic> attributes, List<Map<String,dynamic>>? productImages, String? thumbnail, String? metaImage, bool isAdd, bool isActiveColor, List<ColorImage> colorImageObject, List<String?> tags, String? digitalFileReady, DigitalVariationModel? digitalVariationModel, bool? isDigitalVariationActive, String? token) async {

    _setRequestHeaders(token);

    final requestData = await _prepareRequestData(
      product: product,
      addProduct: addProduct,
      attributes: product.productType == 'digital' ? {} : attributes,
      productImages: productImages,
      thumbnail: thumbnail,
      metaImage: metaImage,
      isAdd: isAdd,
      isActiveColor: isActiveColor,
      colorImageObject: colorImageObject,
      tags: tags,
      digitalFileReady: digitalFileReady,
      digitalVariationModel: digitalVariationModel,
      isDigitalVariationActive: isDigitalVariationActive,
    );

    if(product.productType == 'digital') {
      try {
        List<MultipartWithKey> multiPartFiles = await processItems(digitalVariationModel);

        final String path = isAdd
            ? AppConstants.addProductUri
            : '${AppConstants.updateProductUri}/${product.id}';
        Response response = await dioClient!.postMultipart(
          path,
          data: requestData,
          files: multiPartFiles,
        );

        return ApiResponse.withSuccess(response);
      } catch (e) {
        return ApiResponse.withError(ApiErrorHandler.getMessage(e));
      }
    } else {
      try {
        final String path = isAdd
            ? AppConstants.addProductUri
            : '${AppConstants.updateProductUri}/${product.id}';
        Response response = await dioClient!.post(
          path,
          data: requestData,
        );

        return ApiResponse.withSuccess(response);

      } catch (e) {
        return ApiResponse.withError(ApiErrorHandler.getMessage(e));
      }
    }
  }

  Future<List<MultipartWithKey>> processItems(DigitalVariationModel? digitalVariationModel) async {
    List<MultipartWithKey> multipartBody = [];

    if(digitalVariationModel?.digitalVariantFiles != null) {
      await Future.forEach(digitalVariationModel!.digitalVariantFiles!.keys, (key) async {
        final file = digitalVariationModel.digitalVariantFiles![key];
        if(file != null) {
          multipartBody.add(MultipartWithKey(
            key: 'digital_files_$key',
            multipartFile: await MultipartFile.fromFile(
              file.path,
              filename: basename(file.path),
            ),
          ));
        }
      });
    }

     if(digitalVariationModel?.digitalProductPreview != null) {
       final preview = digitalVariationModel!.digitalProductPreview!;
       multipartBody.add(MultipartWithKey(
         key: 'preview_file',
         multipartFile: await MultipartFile.fromFile(
           preview.path,
           filename: basename(preview.path),
         ),
       ));
     }

    return multipartBody;
  }

  @override
  Future<ApiResponse> uploadDigitalProduct(File? filePath, String token) async {
    try {
      final formData = FormData();
      if (filePath != null && await filePath.exists()) {
        formData.files.add(MapEntry(
          'digital_file_ready',
          await MultipartFile.fromFile(
            filePath.path,
            filename: basename(filePath.path),
          ),
        ));
      }

      final response = await dioClient!.post(
        AppConstants.digitalProductUpload,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateProductQuantity(int? productId,int currentStock, List <Variation> variation) async {
    try {
      final response = await dioClient!.post(AppConstants.updateProductQuantity,
          data: {
            "product_id": productId,
            "current_stock": currentStock,
            "variation" : variation,
            "_method":"put"
          }
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateRestockProductQuantity(int? productId,int currentStock, List <Variation> variation) async {
    try {
      final response = await dioClient!.post(AppConstants.restockUpdateProductQuantity,
          data: {
            "product_id": productId,
            "current_stock": currentStock,
            "variation" : jsonEncode(variation),

          }
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deleteProductImage(String id, String name, String? color ) async {
    try {
      final response = await dioClient!.get("${AppConstants.deleteProductImage}?id=$id&name=$name&color=$color");
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deleteProductPreview(int? id) async {
    try {
      final response = await dioClient!.get("${AppConstants.deleteProductPreview}?product_id=$id");
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getProductImage(String id ) async {
    try {
      final response = await dioClient!.get("${AppConstants.getProductImage}$id");
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deleteDigitalVariationFile(int? productId, String variantKey) async {
    try {
      final response = await dioClient!.post(AppConstants.deleteDigitalProductVariationFile,
          data: {
            "product_id": productId,
            "variant_key": variantKey
          }
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getDigitalAuthor() async {
    try {
      final response = await dioClient!.get(AppConstants.digitalAuthorList);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getPublishingHouse() async {
    try {
      final response = await dioClient!.get(AppConstants.digitalPublishingHouse);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getTaxVatList() async {
    try {
      final response = await dioClient!.get(AppConstants.getTaxVatList);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getProductTaxConfig() async {
    try {
      final response = await dioClient!.get(AppConstants.productTaxConfigUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) {

    throw UnimplementedError();
  }

  @override
  Future delete(int id) {

    throw UnimplementedError();
  }

  @override
  Future get(String id) {

    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {

    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {

    throw UnimplementedError();
  }
}