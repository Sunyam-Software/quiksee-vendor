import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/utill/app_constants.dart';

class AssignmentRepository {
  final ApiClient apiClient;

  AssignmentRepository({required this.apiClient});

  static const int _offersTimeoutSeconds = 8;
  static const int _liveLocationTimeoutSeconds = 12;

  Future<Response> getPendingOffers() {
    return apiClient.getData(
      AppConstants.pendingOffersUri,
      timeoutSeconds: _offersTimeoutSeconds,
    );
  }

  Future<Response> getScheduledPendingOffers() {
    return apiClient.getData(
      AppConstants.scheduledPendingOffersUri,
      timeoutSeconds: _offersTimeoutSeconds,
    );
  }

  Future<Response> getScheduledDeliveryConfig() {
    return apiClient.getData(AppConstants.scheduledDeliveryConfigUri);
  }

  Future<Response> acceptOffer(int offerId) {
    return apiClient.postData(AppConstants.acceptOfferUri, {
      'offer_id': offerId,
    });
  }

  Future<Response> rejectOffer(int offerId, {String? reason}) {
    final body = <String, dynamic>{'offer_id': offerId};
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }
    return apiClient.postData(AppConstants.rejectOfferUri, body);
  }

  Future<Response> getAssignmentSettings() {
    return apiClient.getData(AppConstants.assignmentSettingsUri);
  }

  Future<Response> getDeliveryAreas() {
    return apiClient.getData(AppConstants.deliveryAreasUri);
  }

  Future<Response> updateLiveLocation({
    required double latitude,
    required double longitude,
    required String location,
  }) {
    return apiClient.postData(AppConstants.updateLiveLocationUri, {
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
    }, timeoutSeconds: _liveLocationTimeoutSeconds);
  }
}
