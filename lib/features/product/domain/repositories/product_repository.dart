import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/product/domain/models/filter_model.dart';
import 'package:quiksee_vendor_app/features/product/domain/repositories/product_repository_interface.dart';
import 'package:quiksee_vendor_app/helper/date_converter.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class ProductRepository implements ProductRepositoryInterface{
  final DioClient? dioClient;
  final SharedPreferences? sharedPreferences;
  ProductRepository({required this.sharedPreferences, required this.dioClient});

  @override
  Future<ApiResponse> getSellerProductList({
    required String sellerId,
    required int offset,
    required String languageCode,
    required String search,
    FilterModel? filterModel,
}) async {
    try {

      final List<String> productTypes = (filterModel?.productType ?? [])
          .where((type) => type.trim().isNotEmpty)
          .toList();

      String? requestStatus;
      switch (filterModel?.isApproved) {
        case 'approved':
          requestStatus = '1';
          break;
        case 'denied':
          requestStatus = '2';
          break;
        case 'new_product':
          requestStatus = '0';
          break;
      }

      final Map<String, dynamic> queryParams = {
        'limit': 10,
        'offset': offset,
        'search': search,
        if (productTypes.isNotEmpty) 'product_types': jsonEncode(productTypes),
        if (filterModel?.minPrice != null) 'min_price': filterModel?.minPrice,
        if (filterModel?.maxPrice != null) 'max_price': filterModel?.maxPrice,
        if (filterModel?.startDate != null) 'start_date': DateConverter.durationDateTime(filterModel!.startDate!),
        if (filterModel?.endDate != null) 'end_date': DateConverter.durationDateTime(filterModel!.endDate!),
        if (filterModel?.brandIds != null && filterModel!.brandIds!.isNotEmpty) 'brand_ids': jsonEncode(filterModel.brandIds),
        if (filterModel?.categoryIds != null && filterModel!.categoryIds!.isNotEmpty) 'category_ids': jsonEncode(filterModel.categoryIds),
        if (filterModel?.filterSubCategoryIds != null && filterModel!.filterSubCategoryIds!.isNotEmpty) 'filter_sub_category_ids': jsonEncode(filterModel.filterSubCategoryIds),
        if (filterModel?.filterSubSubCategoryIds != null && filterModel!.filterSubSubCategoryIds!.isNotEmpty) 'filter_sub_sub_category_ids': jsonEncode(filterModel.filterSubSubCategoryIds),
        if (filterModel?.publishingHouseIds != null && filterModel!.publishingHouseIds!.isNotEmpty) 'publishing_house_ids': jsonEncode(filterModel.publishingHouseIds),
        if (filterModel?.authorIds != null && filterModel!.authorIds!.isNotEmpty) 'author_ids': jsonEncode(filterModel.authorIds),
        if (filterModel?.status != null && filterModel!.status!.isNotEmpty) 'product_status' :
        filterModel.status?.length == 1 ? filterModel.status!.contains('active') ? jsonEncode([1]) : filterModel.status!.contains('inactive') ? jsonEncode([0]) : jsonEncode([0,1]) : jsonEncode([0,1]),
        if (requestStatus != null) 'request_status': requestStatus,
        if (filterModel?.sorting != null && filterModel!.sorting!.isNotEmpty) 'filter_sort_by': filterModel.sorting,
      };

      debugPrint('-----------queryParams $queryParams');

      final response = await dioClient!.get(
        '${AppConstants.sellerProductUri}$sellerId/all-products',
        queryParameters: queryParams,
        options: Options(
          headers: {AppConstants.langKey: languageCode},

          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getPosProductList(int offset, List <String> ids) async {
    try {
      final response = await dioClient!.get('${AppConstants.posProductList}?limit=10&&offset=$offset&category_id=${jsonEncode(ids)}');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getSearchedPosProductList(String search, List <String> ids) async {
    try {
      final response = await dioClient!.get('${AppConstants.searchPosProductList}?limit=10&offset=1&name=$search&category_id=${jsonEncode(ids)}');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getStockLimitedProductList(int offset, String languageCode ) async {
    try {
      final response = await dioClient!.get('${AppConstants.stockOutProductUri}$offset',
        options: Options(headers: {AppConstants.langKey: languageCode}),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getMostPopularProductList(int offset, String languageCode ) async {
    try {
      final response = await dioClient!.get('${AppConstants.mostPopularProduct}$offset',
        options: Options(headers: {AppConstants.langKey: languageCode}),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getTopSellingProductList(int offset, String languageCode ) async {
    try {
      final response = await dioClient!.get('${AppConstants.topSellingProduct}$offset',
        options: Options(headers: {AppConstants.langKey: languageCode}),
      );
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
  Future delete(int id) async{
    try {
      final response = await dioClient!.post('${AppConstants.deleteProductUri}/$id',data: {
        '_method':'delete'
      });
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
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

  @override
  Future<ApiResponse> getStockLimitStatus() async {
    try {
      final response = await dioClient!.get(AppConstants.stockLimitStatus);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  bool isShowCookies() {
    return sharedPreferences!.containsKey(AppConstants.showCookies);
  }

  @override
  Future<void> setIsShowCookies() async {
    await sharedPreferences!.setString(AppConstants.showCookies, 'cookies');
  }

  @override
  Future<void> removeShowCookies() async {
    await sharedPreferences!.remove(AppConstants.showCookies);
  }

  @override
  Future<ApiResponse> getProductAvailabilityHours(int productId) async {
    try {
      final response = await dioClient!.get('${AppConstants.productAvailabilityHoursUri}$productId');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateProductAvailabilityHours(int productId, Map<String, dynamic> body) async {
    try {
      final response = await dioClient!.put(
        '${AppConstants.productAvailabilityHoursUri}$productId',
        data: body,
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getBrandList(String languageCode) async {
    try {
      final response = await dioClient!.get(AppConstants.brandUri,
        options: Options(headers: {AppConstants.langKey: languageCode}),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

}