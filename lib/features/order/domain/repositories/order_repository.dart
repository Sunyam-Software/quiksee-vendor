import 'package:get/get_connect/http/src/response/response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/order/domain/repositories/order_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';

class OrderRepository implements OrderRepositoryInterface{
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  static const int _ordersTimeoutSeconds = 12;

  OrderRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response> getCurrentOrders() async {
    return apiClient.getData(
      AppConstants.currentOrderUri,
      timeoutSeconds: _ordersTimeoutSeconds,
    );
  }

  @override
  Future<Response> getScheduledCurrentOrders() async {
    return apiClient.getData(
      AppConstants.scheduledCurrentOrdersUri,
      timeoutSeconds: _ordersTimeoutSeconds,
    );
  }

  @override
  Future<Response> getAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause) async {
    return apiClient.getData(
      '${AppConstants.allOrderHistoryUri}?status=$type&start_date=$startDate&end_date=$endDate&search=$search&is_pause=$isPause&date_type=$dateType',
      timeoutSeconds: _ordersTimeoutSeconds,
    );
  }

  @override
  Future<Response> getScheduledAllOrderHistory(String dateType, String type, String startDate, String endDate, String search, int isPause) async {
    return apiClient.getData(
      '${AppConstants.scheduledAllOrdersUri}?status=$type&start_date=$startDate&end_date=$endDate&search=$search&is_pause=$isPause&date_type=$dateType',
      timeoutSeconds: _ordersTimeoutSeconds,
    );
  }

  @override
  Future<Response> getSingleOrderHistory(String id) async {
    Response response = await apiClient.getData('${AppConstants.singleOrderHistoryUri}?id=$id');
    return response;
  }

  @override
  Future<Response> acceptOrder(int orderId, double lat, double lng,
      {String? location, String? status}) async {
    return apiClient.postData(AppConstants.updateOrderStatusUri, {
      'order_id': orderId,
      'status': status ?? 'confirmed',
      'latitude': lat,
      'longitude': lng,
      'location': location ?? 'Accepted by driver',
      '_method': 'put',
    });
  }

  @override
  Future<Response> rejectAssignedOrder(int orderId, {String? reason}) async {
    return apiClient.postData(AppConstants.rejectAssignedOrderUri, {
      'order_id': orderId,
      'reason': reason ?? 'Driver declined',
    });
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(int? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList() {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }

}
