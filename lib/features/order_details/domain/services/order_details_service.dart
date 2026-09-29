import 'package:get/get.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order_details/domain/repositories/order_details_repository_interface.dart';
import 'package:quiksee/features/order_details/domain/services/order_details_service_interface.dart';

class OrderDetailsService implements OrderDetailsServiceInterface{
  OrderDetailsRepositoryInterface orderDetailsRepositoryInterface;
  OrderDetailsService({required this.orderDetailsRepositoryInterface});


  @override
  Future cancelOrderStatus({int? orderId, String? cause}) async {
    Response response = await orderDetailsRepositoryInterface.cancelOrderStatus(orderId: orderId, cause: cause);
    bool _isSuccess;
    if(response.body != null && response.statusCode == 200) {
      showQuikseeSnackBarWidget(response.body['message'], isError: false);
      _isSuccess = true;
      Get.find<OrderController>().getCurrentOrders();
    }else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    return _isSuccess;
  }


  @override
  Future getOrderDetails({String? orderID}) async{
    return  await orderDetailsRepositoryInterface.getOrderDetails(orderID: orderID);
  }


  @override
  Future pauseAndResumeOrder({int? orderId, int? isPos, String? cause}) async{
    Response response = await orderDetailsRepositoryInterface.pauseAndResumeOrder(orderId: orderId, isPos: isPos, cause: cause);
    bool _isSuccess;
    if(response.body != null && response.statusCode == 200) {
      Get.back();
      showQuikseeSnackBarWidget(response.body['message'], isError: false);
      _isSuccess = true;
    }else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }

    return _isSuccess;
  }

  @override
  Future rescheduleOrder({int? orderId, String? deliveryDate, String? cause}) async{
    Response response = await orderDetailsRepositoryInterface.rescheduleOrder(orderId: orderId, deliveryDate: deliveryDate, cause: cause);
    bool _isSuccess;
    if(response.body != null && response.statusCode == 200) {
      showQuikseeSnackBarWidget(response.body['message'], isError: false);
      _isSuccess = true;
      Get.find<OrderController>().getCurrentOrders();
    }else {
      ApiChecker.checkApi(response);
      _isSuccess = false;
    }
    return _isSuccess;
  }

  @override
  Future resendOtpForOrderVerification({int? orderId}) async{
    Response response = await orderDetailsRepositoryInterface.resendOtpForOrderVerification(orderId: orderId);
    if (response.statusCode == 200) {
      showQuikseeSnackBarWidget('otp_sent_successfully'.tr, isError: false, );
    } else {
      ApiChecker.checkApi(response);
    }
  }

  @override
  Future updateOrderStatus({
    int? orderId,
    String? status,
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    return await orderDetailsRepositoryInterface.updateOrderStatus(
      orderId: orderId,
      status: status,
      latitude: latitude,
      longitude: longitude,
      location: location,
    );
  }

  @override
  Future<Response> updatePaymentStatus({int? orderId, String? status}) async{
    Response response = await orderDetailsRepositoryInterface.updatePaymentStatus(orderId: orderId, status: status);
    if (response.statusCode == 200) {
    } else {
      ApiChecker.checkApi(response);
    }
    return response;
  }

  @override
  Future<Response> createCodUpiQr({required int orderId}) async {
    return orderDetailsRepositoryInterface.createCodUpiQr(orderId: orderId);
  }

  @override
  Future<Response> codUpiQrStatus({
    required int orderId,
    bool sync = false,
  }) async {
    return orderDetailsRepositoryInterface.codUpiQrStatus(
      orderId: orderId,
      sync: sync,
    );
  }

  @override
  Future<Response> markCodCashCollected({required int orderId}) async {
    return orderDetailsRepositoryInterface.markCodCashCollected(orderId: orderId);
  }

  @override
  Future<Response?> uploadOrderVerificationImage(String orderId, List<MultipartBody>? verificationImage) {
    return orderDetailsRepositoryInterface.uploadOrderVerificationImage(orderId, verificationImage);
  }

  @override
  Future<Response> verifyOrderDeliveryOtp({int? orderId, String? verificationCode}) {
     return orderDetailsRepositoryInterface.verifyOrderDeliveryOtp(orderId: orderId, verificationCode: verificationCode);
  }
}