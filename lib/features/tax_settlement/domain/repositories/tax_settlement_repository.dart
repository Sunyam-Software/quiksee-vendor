import 'package:dio/dio.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/domain/repositories/tax_settlement_repository_interface.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class TaxSettlementRepository implements TaxSettlementRepositoryInterface {
  final DioClient? dioClient;

  TaxSettlementRepository({required this.dioClient});

  @override
  Future<ApiResponse> getSummary() async {
    try {
      final response = await dioClient!.get(AppConstants.taxSettlementSummaryUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getList({required int limit, required int offset}) async {
    try {
      final response = await dioClient!.get(
        '${AppConstants.taxSettlementListUri}?limit=$limit&offset=$offset',
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getDetails(int id) async {
    try {
      final response = await dioClient!.get('${AppConstants.taxSettlementListUri}/$id');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> markPaid({
    required int id,
    required String amount,
    String? reference,
    String? note,
    String? receiptPath,
  }) async {
    try {
      final map = <String, dynamic>{
        'amount': amount,
        if (reference != null && reference.isNotEmpty) 'reference': reference,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      if (receiptPath != null && receiptPath.isNotEmpty) {
        map['receipt'] = await MultipartFile.fromFile(receiptPath);
      }

      final formData = FormData.fromMap(map);
      final response = await dioClient!.post(
        '${AppConstants.taxSettlementListUri}/$id/mark-paid',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }
}
