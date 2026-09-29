import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/utill/app_constants.dart';

class DistancePaymentRepository {
  final ApiClient apiClient;

  DistancePaymentRepository({required this.apiClient});

  Future<Response> getDistanceShippingConfig() {
    return apiClient.getData(AppConstants.distanceShippingConfigUri);
  }

  Future<Response> getOrderDistancePayment(int orderId) {
    return apiClient.getData(
      '${AppConstants.orderDistancePaymentUri}?order_id=$orderId',
    );
  }

  Future<Response> estimateDeliveryPay({int? orderId, double? lat, double? lng, String? city}) {
    final Map<String, dynamic> body = {};
    if (orderId != null) {
      body['order_id'] = orderId;
    } else {
      body['destination_lat'] = lat;
      body['destination_lng'] = lng;
      if (city != null) body['city'] = city;
    }
    return apiClient.postData(AppConstants.estimateDeliveryPayUri, body);
  }
}
