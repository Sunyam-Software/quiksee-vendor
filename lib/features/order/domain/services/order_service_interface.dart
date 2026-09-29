import 'package:get/get_connect/http/src/response/response.dart';

abstract class OrderServiceInterface {
  Future<dynamic> getCurrentOrders();
  Future<dynamic> getScheduledCurrentOrders();
  Future<dynamic> getAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause);
  Future<dynamic> getScheduledAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause);
  Future<dynamic> getSingleOrderHistory(String id);
  Future<Response> acceptOrder(int orderId, double lat, double lng,
      {String? location, String? status});
  Future<Response> rejectAssignedOrder(int orderId, {String? reason});
}