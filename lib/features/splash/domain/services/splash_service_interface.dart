import 'package:get/get_connect/http/src/response/response.dart';

abstract class SplashServiceInterface {

  Future<Response> getConfigData();
  Future<dynamic> getBusinessPages(String type);
  Future<bool> initSharedData();
  String getCurrency();
  void setCurrency(String currencyCode);
  Future<bool> removeSharedData();
  void disableIntro();
  bool? showIntro();
  void disableNotification();
  void enableNotification();
  bool? notificationSound();
  String? getCachedConfigJson();
  Future<bool> cacheConfigJson(String json);
}