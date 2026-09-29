import 'package:get/get_connect/http/src/response/response.dart';

abstract class TipRepositoryInterface {
  Future<Response> getTipSummary();
  Future<Response> getTipList({required int offset, required int limit, String? status});
  Future<Response> getTipOrderDetail({required int orderId});
}
