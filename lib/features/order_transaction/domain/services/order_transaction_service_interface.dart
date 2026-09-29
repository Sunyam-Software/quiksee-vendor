abstract class OrderTransactionServiceInterface {
  Future<dynamic> getOrderTransactions({
    String? search,
    String? status,
    String? from,
    String? to,
    int limit = 20,
    int offset = 1,
  });
}
