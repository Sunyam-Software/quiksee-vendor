
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/interface/repository_interface.dart';

abstract class OrderDetailsRepositoryInterface implements RepositoryInterface{
  Future<Response> getOrderDetails({String? orderID});
  Future<Response> updateOrderStatus({
    int? orderId,
    String? status,
    double? latitude,
    double? longitude,
    String? location,
  });
  Future<Response> rescheduleOrder({int? orderId, String? deliveryDate, String? cause});
  Future<Response> pauseAndResumeOrder({int? orderId, int? isPos, String? cause});
  Future<Response> cancelOrderStatus({int? orderId, String? cause});
  Future<Response> updatePaymentStatus({int? orderId, String? status});
  Future<Response> createCodUpiQr({required int orderId});
  Future<Response> codUpiQrStatus({required int orderId, bool sync = false});
  Future<Response> markCodCashCollected({required int orderId});
  Future<Response> uploadOrderVerificationImage( String orderId, List<MultipartBody>? verificationImage);
  Future<Response> verifyOrderDeliveryOtp({int? orderId, String? verificationCode});
  Future<Response> resendOtpForOrderVerification({int? orderId});
}