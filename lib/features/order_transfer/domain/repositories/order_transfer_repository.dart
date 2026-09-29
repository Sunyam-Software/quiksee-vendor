import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/utill/app_constants.dart';

class OrderTransferRepository {
  final ApiClient apiClient;

  OrderTransferRepository({required this.apiClient});

  Future<Response> getCandidates(int orderId) {
    return apiClient.getData(
      '${AppConstants.orderTransferCandidatesUri}?order_id=$orderId',
    );
  }

  Future<Response> requestTransfer({
    required int orderId,
    required int toDeliveryManId,
    String? reason,
  }) {
    final body = <String, dynamic>{
      'order_id': orderId,
      'to_delivery_man_id': toDeliveryManId,
    };
    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason.trim();
    }
    return apiClient.postData(AppConstants.orderTransferRequestUri, body);
  }

  Future<Response> getStatus(int offerId) {
    return apiClient.getData(
      '${AppConstants.orderTransferStatusUri}?offer_id=$offerId',
    );
  }

  Future<Response> pendingIncoming() {
    return apiClient.getData(AppConstants.orderTransferPendingIncomingUri);
  }

  Future<Response> recentOutgoing({int limit = 5}) {
    return apiClient.getData(
      '${AppConstants.orderTransferRecentOutgoingUri}?limit=$limit',
    );
  }

  Future<Response> cancel(int offerId) {
    return apiClient.postData(AppConstants.orderTransferCancelUri, {
      'offer_id': offerId,
    });
  }

  Future<Response> respond({
    required int offerId,
    required String action,
  }) {
    return apiClient.postData(AppConstants.orderTransferRespondUri, {
      'offer_id': offerId,
      'action': action,
    });
  }
}
