
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/interface/repository_interface.dart';

abstract class OrderRepositoryInterface implements RepositoryInterface{
  Future<Response> getCurrentOrders();
  Future<Response> getScheduledCurrentOrders();
  Future<Response> getAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause);
  Future<Response> getScheduledAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause);
  Future<Response> getSingleOrderHistory(String id);
  Future<Response> acceptOrder(int orderId, double lat, double lng,
      {String? location, String? status});
  Future<Response> rejectAssignedOrder(int orderId, {String? reason});
}