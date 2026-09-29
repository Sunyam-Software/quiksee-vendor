
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:quiksee/features/splash/domain/repositories/splash_repository_interface.dart';
import 'package:quiksee/features/splash/domain/services/splash_service_interface.dart';

class SplashService implements SplashServiceInterface{
  SplashRepositoryInterface splashRepoInterface;
  SplashService({required this.splashRepoInterface});

  @override
  void disableIntro() {
    return splashRepoInterface.disableIntro();
  }

  @override
  void disableNotification() {
    return splashRepoInterface.disableNotification();
  }

  @override
  void enableNotification() {
    return splashRepoInterface.enableNotification();
  }

  @override
  Future<Response> getConfigData() {
    return splashRepoInterface.getConfigData();
  }

  @override
  String getCurrency() {
    return splashRepoInterface.getCurrency();
  }

  @override
  Future<bool> initSharedData() {
    return splashRepoInterface.initSharedData();
  }

  @override
  bool? notificationSound() {
    return splashRepoInterface.notificationSound();
  }

  @override
  Future<bool> removeSharedData() {
    return splashRepoInterface.removeSharedData();
  }

  @override
  void setCurrency(String currencyCode) {
    return splashRepoInterface.setCurrency(currencyCode);
  }

  @override
  bool? showIntro() {
    return splashRepoInterface.showIntro();
  }

  @override
  String? getCachedConfigJson() {
    return splashRepoInterface.getCachedConfigJson();
  }

  @override
  Future<bool> cacheConfigJson(String json) {
    return splashRepoInterface.cacheConfigJson(json);
  }

  @override
  Future getBusinessPages(String type) {
    return splashRepoInterface.getBusinessPages(type);
  }

}