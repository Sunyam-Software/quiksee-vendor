import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/order_details/domain/repositories/order_details_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';

class OrderDetailsRepository implements OrderDetailsRepositoryInterface{
  final ApiClient apiClient;
  OrderDetailsRepository({required this.apiClient});


  @override
  Future<Response> getOrderDetails({String? orderID}) async {
    return apiClient.getData(
      '${AppConstants.orderDetailsUri}$orderID',
      timeoutSeconds: 45,
    );
  }


  @override
  Future<Response> updateOrderStatus({
    int? orderId,
    String? status,
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    final Map<String, dynamic> body = {
      'order_id': orderId,
      'status': status,
      '_method': 'put',
    };
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
      if (location != null && location.isNotEmpty) {
        body['location'] = location;
      }
    }
    return apiClient.postData(
      AppConstants.updateOrderStatusUri,
      body,
      timeoutSeconds: 20,
    );
  }

  @override
  Future<Response> rescheduleOrder({int? orderId, String? deliveryDate, String? cause}) async {
    Response response = await apiClient.postData(
        AppConstants.rescheduleOrderStatusUri,
        {"order_id": orderId, "expected_delivery_date": deliveryDate, "_method": 'put', 'cause' : cause});
    return response;

  }

  @override
  Future<Response> pauseAndResumeOrder({int? orderId, int? isPos, String? cause}) async {
    Response response = await apiClient.postData(
        AppConstants.pauseAndResumeOrderStatusUri,
        {"order_id": orderId, "is_pause": isPos, "_method": 'put', 'cause' : cause});
    return response;

  }

  @override
  Future<Response> cancelOrderStatus({int? orderId, String? cause}) async {
    Response response = await apiClient.postData(
        AppConstants.updateOrderStatusUri,
        {"order_id": orderId, "status": 'canceled', "_method": 'put', 'cause': cause});
    return response;

  }

  @override
  Future<Response> updatePaymentStatus({int? orderId, String? status}) async {
    Response response = await apiClient.postData(AppConstants.updatePaymentStatusUri,
        {"order_id": orderId, "payment_status": status, "_method": 'put'});
      return response;

  }

  @override
  Future<Response> createCodUpiQr({required int orderId}) async {
    return apiClient.postData(
      AppConstants.createCodUpiQrUri,
      {'order_id': orderId},
      timeoutSeconds: 15,
    );
  }

  @override
  Future<Response> codUpiQrStatus({
    required int orderId,
    bool sync = false,
  }) async {
    // sync=1 = live Razorpay pull (slow). Auto-poll must use sync=false.
    final syncQ = sync ? '&sync=1' : '';
    return apiClient.getData(
      '${AppConstants.codUpiQrStatusUri}?order_id=$orderId$syncQ',
      timeoutSeconds: sync ? 8 : 4,
    );
  }

  @override
  Future<Response> markCodCashCollected({required int orderId}) async {
    return apiClient.postData(AppConstants.markCodCashCollectedUri, {
      'order_id': orderId,
    });
  }


  @override
  Future<Response> uploadOrderVerificationImage( String orderId, List<MultipartBody>? verificationImage) async {
    Map<String, String> fields = <String, String> {
      'order_id': orderId,

    };
    return await apiClient.postMultipartData(
      AppConstants.deliveryVerificationImage,
      fields,
      verificationImage!,
    );
  }


  @override
  Future<Response> verifyOrderDeliveryOtp({int? orderId, String? verificationCode}) async {
    return apiClient.postData(
      AppConstants.otpVerificationForOrder,
      {
        'order_id': orderId,
        'verification_code': verificationCode,
      },
      timeoutSeconds: 10,
    );
  }

  @override
  Future<Response> resendOtpForOrderVerification({int? orderId}) async {
    return apiClient.postData(
      AppConstants.resendVerificationCode,
      {'order_id': orderId},
      timeoutSeconds: 10,
    );
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
