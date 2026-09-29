import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/discount_expense/domain/repositories/discount_expense_repository_interface.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class DiscountExpenseRepository implements DiscountExpenseRepositoryInterface {
  final DioClient? dioClient;
  DiscountExpenseRepository({required this.dioClient});

  @override
  Future<ApiResponse> getDiscountExpenseReport({
    String type = 'all',
    String? from,
    String? to,
  }) async {
    try {
      String url = '${AppConstants.discountExpenseReportUri}?type=$type';
      if (from != null && from.isNotEmpty) {
        url += '&from=$from';
      }
      if (to != null && to.isNotEmpty) {
        url += '&to=$to';
      }
      final response = await dioClient!.get(url);
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
