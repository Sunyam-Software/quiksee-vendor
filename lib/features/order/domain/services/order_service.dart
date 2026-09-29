import 'package:get/get.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/domain/repositories/order_repository_interface.dart';
import 'package:quiksee/features/order/domain/services/order_service_interface.dart';
import 'package:quiksee/features/order/helpers/combined_order_helper.dart';
import 'package:quiksee/features/order/helpers/scheduled_delivery_response_helper.dart';

class OrderService implements OrderServiceInterface{
  OrderRepositoryInterface orderRepoInterface;
  OrderService({required this.orderRepoInterface});

  @override
  Future getCurrentOrders() async{
    Response response = await orderRepoInterface.getCurrentOrders();
    List<OrderModel> _currentOrders = [];
    if (response.body != null && response.body != {} && response.statusCode == 200) {
      _currentOrders = [];
      response.body.forEach((order) {_currentOrders.add(OrderModel.fromJson(order));});
      _currentOrders = CombinedOrderHelper.groupOrders(_currentOrders);
    } else {
      ApiChecker.checkApi(response);
    }
    return _currentOrders;
  }

  @override
  Future getScheduledCurrentOrders() async {
    Response response = await orderRepoInterface.getScheduledCurrentOrders();
    if (response.statusCode == 200 && response.body != null) {
      return ScheduledDeliveryResponseHelper.parseOrderList(response.body);
    }
    if (response.statusCode != 200) {
      ApiChecker.checkApi(response);
    }
    return <OrderModel>[];
  }

  @override
  Future<Response> getAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause) {
    return orderRepoInterface.getAllOrderHistory(dateType, type, startDate, endDate, search, isPause);
  }

  @override
  Future<Response> getScheduledAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause) {
    return orderRepoInterface.getScheduledAllOrderHistory(dateType, type, startDate, endDate, search, isPause);
  }

  @override
  Future<Response> getSingleOrderHistory(String id) {
    return orderRepoInterface.getSingleOrderHistory(id);
  }

  @override
  Future<Response> acceptOrder(int orderId, double lat, double lng,
      {String? location, String? status}) {
    return orderRepoInterface.acceptOrder(
      orderId,
      lat,
      lng,
      location: location,
      status: status,
    );
  }

  @override
  Future<Response> rejectAssignedOrder(int orderId, {String? reason}) {
    return orderRepoInterface.rejectAssignedOrder(orderId, reason: reason);
  }

}