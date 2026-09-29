

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:quiksee_vendor_app/data/model/response/base/api_response.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/shop_model.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/vacation_model.dart';
import 'package:quiksee_vendor_app/features/shop/domain/models/withdrawal_method_model.dart';
import 'package:quiksee_vendor_app/interface/repository_interface.dart';

abstract class ShopRepositoryInterface implements RepositoryInterface{
  Future<ApiResponse> getShop();
  Future<ApiResponse> updateShop(ShopModel userInfoModel,  File? file, XFile? shopBanner, XFile? secondaryBanner, XFile? offerBanner,
      {String? minimumOrderAmount, String? freeDeliveryStatus, String? freeDeliveryOverAmount, String? taxIdentificationNumber, String? tinExpireDate, String? stockLimit, String? preparationTime, XFile? tinCertificate});
  Future<ApiResponse> vacation(VacationModel vacationModel);
  Future<ApiResponse> temporaryClose(int status);
  Future<ApiResponse> getOpeningHours();
  Future<ApiResponse> updateOpeningHours(Map<String, dynamic> body);
  Future<ApiResponse> getStoreStatus();
  Future<ApiResponse> updateStoreStatus(bool status);
  Future<ApiResponse> getPaymentWithdrawalMethodList();
  Future<ApiResponse> addPaymentInfo(WithdrawAddModel withdrawAddMode, bool isUpdate);
  Future<ApiResponse> getPaymentInfoList(int? offset);
  Future<ApiResponse> updateConfigStatus(bool status, int id);
  Future<ApiResponse> deletePaymentMethod(int id);
  Future<ApiResponse> setDefaultPaymentMethod(int id);
  Future<ApiResponse> updateSetupGuideApp(String key, int value);
  Future<HttpClientResponse> downloadTinCertificate(String url);
}