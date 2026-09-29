
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/dio/dio_client.dart';
import 'package:quiksee_vendor_app/data/datasource/remote/exception/api_error_handler.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/shop_model.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/vacation_model.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/withdrawal_method_model.dart';
import 'package:quiksee_vendor_app/features/shop/domain/repositories/shop_repository_interface.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/features/dynamic_fields/controllers/dynamic_field_controller.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show basename;

class ShopRepository implements ShopRepositoryInterface{
  final DioClient? dioClient;
  final SharedPreferences? sharedPreferences;
  ShopRepository({required this.dioClient, required this.sharedPreferences});

  @override
  Future<ApiResponse> getShop() async {
    try {
      final response = await dioClient!.get(AppConstants.shopUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateShop(ShopModel userInfoModel, File? file, XFile? shopBanner, XFile? secondaryBanner, XFile? offerBanner,
      {String? minimumOrderAmount, String? freeDeliveryStatus, String? freeDeliveryOverAmount, String? taxIdentificationNumber, String? tinExpireDate, String? stockLimit, String? preparationTime, XFile? tinCertificate}) async {
    try {
      final String token = Provider.of<AuthController>(Get.context!, listen: false).getUserToken();
      final formData = FormData.fromMap(<String, dynamic>{
        '_method': 'put',
        'name': userInfoModel.name ?? '',
        'address': userInfoModel.address ?? '',
        'contact': userInfoModel.contact ?? '',
        'minimum_order_amount': minimumOrderAmount ?? '0',
        'free_delivery_status': freeDeliveryStatus ?? 'false',
        'free_delivery_over_amount': freeDeliveryOverAmount ?? '0',
        'tax_identification_number': taxIdentificationNumber ?? '0',
        'tin_expire_date': tinExpireDate ?? '',
        'stock_limit': stockLimit ?? '0',
        'preparation_time': preparationTime ?? (userInfoModel.preparationTime?.toString() ?? ''),
      });

      if (file != null && await file.exists()) {
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(file.path, filename: basename(file.path)),
        ));
      }
      if (shopBanner != null) {
        formData.files.add(MapEntry(
          'banner',
          await MultipartFile.fromFile(shopBanner.path, filename: basename(shopBanner.path)),
        ));
      }
      if (secondaryBanner != null) {
        formData.files.add(MapEntry(
          'bottom_banner',
          await MultipartFile.fromFile(secondaryBanner.path, filename: basename(secondaryBanner.path)),
        ));
      }
      if (offerBanner != null) {
        formData.files.add(MapEntry(
          'offer_banner',
          await MultipartFile.fromFile(offerBanner.path, filename: basename(offerBanner.path)),
        ));
      }
      if (tinCertificate != null) {
        formData.files.add(MapEntry(
          'tin_certificate',
          await MultipartFile.fromFile(tinCertificate.path, filename: basename(tinCertificate.path)),
        ));
      }

      if (Get.context != null) {
        final dynamicFields =
            Provider.of<DynamicFieldController>(Get.context!, listen: false).getPayload();
        dynamicFields.forEach((key, value) {
          formData.fields.add(MapEntry('dynamic_fields[$key]', value));
        });
      }

      if (kDebugMode) {
        print('Shop update => files: ${formData.files.length}, logo: ${file != null}');
      }

      final response = await dioClient!.post(
        AppConstants.shopUpdate,
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
  Future<ApiResponse> vacation(VacationModel vacationModel) async {
    try {
      final response = await dioClient!.post(
        AppConstants.vacation,
        data: vacationModel
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> temporaryClose(int status) async {
    try {
      final response = await dioClient!.post(AppConstants.temporaryClose,data: {
        '_method' : "put",
        'status' : status
      });
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getOpeningHours() async {
    try {
      final response = await dioClient!.get(AppConstants.shopOpeningHoursUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateOpeningHours(Map<String, dynamic> body) async {
    try {
      final response = await dioClient!.put(
        AppConstants.shopOpeningHoursUri,
        data: body,
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getStoreStatus() async {
    try {
      final response = await dioClient!.get(AppConstants.shopStoreStatusUri);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateStoreStatus(bool status) async {
    try {
      final response = await dioClient!.put(
        AppConstants.shopStoreStatusUri,
        data: {'status': status},
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getPaymentWithdrawalMethodList() async {
    try {
      final response = await dioClient!.get(AppConstants.paymentWithdrawalMethodList);
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> addPaymentInfo (WithdrawAddModel withdrawAddModel, bool isUpdate) async {
    try {
      final response = await dioClient!.post(
        isUpdate ? AppConstants.paymentInformationUpdate :
        AppConstants.paymentInformationAdd,
        data: withdrawAddModel
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getPaymentInfoList(int? offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.paymentInformationList}?limit=10&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateConfigStatus(bool status, int id) async {
    try {
      final response = await dioClient!.post(AppConstants.paymentInformationStatusUpdate,
        data: {
          "id" : id,
          "status" : status
        }
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> deletePaymentMethod(int id) async {
    try {
      final response = await dioClient!.get(
        '${AppConstants.paymentInformationDelete}?id=$id',
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> setDefaultPaymentMethod(int id) async {
    try {
      final response = await dioClient!.post(
        AppConstants.paymentInformationDefault,
        data: {"id" : id}
      );
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> updateSetupGuideApp(String key, int value) async {
    try {
      final response = await dioClient!.post(AppConstants.updateSetupGuideApp, data: {
        'key' : key,
        'value' : value
      });
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<HttpClientResponse> downloadTinCertificate (String? url) async {
    HttpClient client = HttpClient();
    final response = await client.getUrl(Uri.parse(url!)).then((HttpClientRequest request) {
      return request.close();
    });
    return response;
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