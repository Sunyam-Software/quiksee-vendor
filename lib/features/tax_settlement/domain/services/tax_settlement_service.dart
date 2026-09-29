import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/tax_settlement/domain/repositories/tax_settlement_repository_interface.dart';

abstract class TaxSettlementServiceInterface {
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

class TaxSettlementService implements TaxSettlementServiceInterface {
  final TaxSettlementRepositoryInterface taxSettlementRepositoryInterface;

  TaxSettlementService({required this.taxSettlementRepositoryInterface});

  @override
  Future<ApiResponse> getSummary() => taxSettlementRepositoryInterface.getSummary();

  @override
  Future<ApiResponse> getList({required int limit, required int offset}) =>
      taxSettlementRepositoryInterface.getList(limit: limit, offset: offset);

  @override
  Future<ApiResponse> getDetails(int id) => taxSettlementRepositoryInterface.getDetails(id);

  @override
  Future<ApiResponse> markPaid({
    required int id,
    required String amount,
    String? reference,
    String? note,
    String? receiptPath,
  }) =>
      taxSettlementRepositoryInterface.markPaid(
        id: id,
        amount: amount,
        reference: reference,
        note: note,
        receiptPath: receiptPath,
      );
}
