import 'package:dio/dio.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/order_transaction/domain/repositories/order_transaction_repository_interface.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class OrderTransactionRepository implements OrderTransactionRepositoryInterface {
  final DioClient? dioClient;
  OrderTransactionRepository({required this.dioClient});

  @override
  Future<ApiResponse> getOrderTransactions({
    String? search,
    String? status,
    String? from,
    String? to,
    int limit = 20,
    int offset = 1,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        'status': status ?? 'all',
      };
      if ((search ?? '').isNotEmpty) query['search'] = search;
      if ((from ?? '').isNotEmpty) query['from'] = from;
      if ((to ?? '').isNotEmpty) query['to'] = to;

      final Response response = await dioClient!.get(
        AppConstants.orderTransactionsUri,
        queryParameters: query,
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }
}
