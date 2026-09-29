
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/delivery_man/domain/model/delivery_man_body.dart';
import 'package:quiksee_vendor_app/features/delivery_man/domain/repositories/delivery_man_repository_interface.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' show basename;
import 'package:quiksee_vendor_app/helper/country_code_helper.dart';

class DeliveryManRepository implements DeliveryManRepositoryInterface{
  final DioClient? dioClient;
  DeliveryManRepository({required this.dioClient});

  @override
  Future<ApiResponse> getDeliveryManList() async {
    try {
      final response = await dioClient!.get(AppConstants.getDeliveryManUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManWithdrawList(int offset, String status) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManWithdrawList}?limit=10&offset=$offset&status=$status');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getDeliveryManReviewList(int offset, int? id) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManReviewList}$id?limit=10&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManWithdrawDetails(int? id) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManWithdrawDetails}$id');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManWithdrawApprovedDenied(int? id, String note, int approved) async {
    try {
      final response = await dioClient!.post(AppConstants.deliveryManWithdrawApprovedRejected,
          data: {
            '_method':"put",
            'id':id,
            'note':note,
            'approved':approved
          });
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManSearchList(int offset, String search) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManListUri}?limit=10&offset=$offset&search=$search');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getNearStoreOnlineRiders({double? maxKm}) async {
    try {
      final query = maxKm != null ? '?max_km=$maxKm' : '';
      final response = await dioClient!.get('${AppConstants.nearStoreDeliveryMenUri}$query');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> sendOfferToDeliveryMan({required int deliveryManId, int? orderId}) async {
    try {
      final data = <String, dynamic>{
        'delivery_man_id': deliveryManId,
      };
      if (orderId != null && orderId > 0) {
        data['order_id'] = orderId;
      }
      final response = await dioClient!.post(
        AppConstants.sendDeliveryManOfferUri,
        data: data,
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManDetails(int? deliveryManId) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManDetails}$deliveryManId');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManOrderList(int offset, int? deliverymanId) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManOrderHistory}$deliverymanId?limit=10&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManEarningList(int offset, int? deliverymanId) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManEarning}$deliverymanId?limit=10&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getTopDeliveryManList() async {
    try {
      final response = await dioClient!.get(AppConstants.topDeliveryMan);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deliveryManStatusOnOff(int? id, int status) async {
    try {
      final response = await dioClient!.post(AppConstants.deliveryManStatusOnOff,
          data: {
            'id' : id,
            'status' : status
      });
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> collectCashFromDeliveryMan(int? deliveryManId, String amount) async {
    try {
      if (kDebugMode) {
        print('====>id==$deliveryManId== and amount ===$amount');
      }
      final response = await dioClient!.post(AppConstants.collectCashFromDeliveryMan,
          data: {'deliveryman_id' : deliveryManId, 'amount': amount});
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deleteDeliveryMan(int? deliveryManId) async {
    try {
      final response = await dioClient!.get('${AppConstants.deleteDeliveryman}$deliveryManId');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getDeliverymanOrderHistoryLog(int? orderId) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManOrderChangeLog}$orderId');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> addNewDeliveryMan(XFile? profileImage, List<XFile?> identityImage, DeliveryManBody deliveryManBody, String token, {bool isUpdate = false}) async {
    try {
      final String path = isUpdate
          ? '${AppConstants.updateDeliveryMan}/${deliveryManBody.id}'
          : AppConstants.addDeliveryMan;

      final formData = FormData.fromMap(<String, dynamic>{
        'f_name': deliveryManBody.fName!,
        'l_name': deliveryManBody.lName!,
        'address': deliveryManBody.address!,
        'phone': deliveryManBody.phone!,
        'email': deliveryManBody.email!,
        'country_code': deliveryManBody.countryCode ?? IndiaPhoneConfig.isoCode,
        'identity_number': deliveryManBody.identityNumber!,
        'identity_type': deliveryManBody.identityType!,
        'password': deliveryManBody.password!,
        'confirm_password': deliveryManBody.confirmPassword!,
        if (isUpdate) '_method': 'put',
      });

      if (profileImage != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            profileImage.path,
            filename: basename(profileImage.path),
          ),
        ));
      }

      for (final XFile? file in identityImage) {
        if (file == null) continue;
        formData.files.add(MapEntry(
          'identity_image[]',
          await MultipartFile.fromFile(
            file.path,
            filename: basename(file.path),
          ),
        ));
      }

      if (kDebugMode) {
        print('Delivery man ${isUpdate ? 'update' : 'add'} => $path, files: ${formData.files.length}');
      }

      final response = await dioClient!.post(
        path,
        data: formData,
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getDeliveryManCollectedCashList(int? id, int offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.deliveryManCollectedCashList}$id?limit=10&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future add(value) {

    throw UnimplementedError();
  }

  @override
  Future delete(int id) {

    throw UnimplementedError();
  }

  @override
  Future get(String id) {

    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {

    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {

    throw UnimplementedError();
  }
}