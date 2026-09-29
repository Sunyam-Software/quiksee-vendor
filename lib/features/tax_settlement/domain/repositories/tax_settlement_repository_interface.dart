import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';

abstract class TaxSettlementRepositoryInterface {
  Future<ApiResponse> getSummary();
  Future<ApiResponse> getList({required int limit, required int offset});
  Future<ApiResponse> getDetails(int id);
  Future<ApiResponse> markPaid({
    required int id,
    required String amount,
    String? reference,
    String? note,
    String? receiptPath,
  });
}
