abstract class TipServiceInterface {
  Future<dynamic> getTipSummary();
  Future<dynamic> getTipList({required int offset, required int limit, String? status});
  Future<dynamic> getTipOrderDetail({required int orderId});
}
