import 'package:quiksee_vendor_app/features/order_transaction/domain/repositories/order_transaction_repository_interface.dart';
import 'package:quiksee_vendor_app/features/order_transaction/domain/services/order_transaction_service_interface.dart';

class OrderTransactionService implements OrderTransactionServiceInterface {
  final OrderTransactionRepositoryInterface orderTransactionRepoInterface;
  OrderTransactionService({required this.orderTransactionRepoInterface});

  @override
  Future getOrderTransactions({
    String? search,
    String? status,
    String? from,
    String? to,
    int limit = 20,
    int offset = 1,
  }) {
    return orderTransactionRepoInterface.getOrderTransactions(
      search: search,
      status: status,
      from: from,
      to: to,
      limit: limit,
      offset: offset,
    );
  }
}
