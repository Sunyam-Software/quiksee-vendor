import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/utill/app_constants.dart';

class RiderRepository {
  final ApiClient apiClient;
  static const int _locationTimeoutSeconds = 12;

  RiderRepository({required this.apiClient});

  Future<Response> getDistanceInMeter(LatLng from, LatLng to) async {
    return await apiClient.postData(AppConstants.distanceApi, {
      'origin_lat': from.latitude,
      'origin_lng': from.longitude,
      'destination_lat': to.latitude,
      'destination_lng': to.longitude
    });
  }

  Future<Response> recordLocationData({
    required int orderId,
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    return apiClient.postData(AppConstants.recordLocationUri, {
      'order_id': orderId,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
    }, timeoutSeconds: _locationTimeoutSeconds);
  }

}
