import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/features/splash/domain/repositories/splash_repository_interface.dart';
import 'package:quiksee/utill/app_constants.dart';

class SplashRepository implements SplashRepositoryInterface{
  ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  SplashRepository({required this.sharedPreferences, required this.apiClient});

  @override
  Future<Response> getConfigData() async {
    Response response = await apiClient.getData(AppConstants.configUri);
    return response;
  }

  @override
  Future<Response> getBusinessPages(String type) async {
    final response = await apiClient.getData(AppConstants.businessPagesUri+type);
    return response;
  }

  @override
  Future<bool> initSharedData() {
    if(!sharedPreferences.containsKey(AppConstants.theme)) {
      return sharedPreferences.setBool(AppConstants.theme, false);
    }
    if(!sharedPreferences.containsKey(AppConstants.countryCode)) {
      return sharedPreferences.setString(AppConstants.countryCode, AppConstants.languages[0].countryCode!);
    }
    if(!sharedPreferences.containsKey(AppConstants.languageCode)) {
      return sharedPreferences.setString(AppConstants.languageCode, AppConstants.languages[0].languageCode!);
    }
    if(!sharedPreferences.containsKey(AppConstants.intro)) {
      sharedPreferences.setBool(AppConstants.intro, true);
    }

    return Future.value(true);
  }

  @override
  String getCurrency() {
    return sharedPreferences.getString(AppConstants.currency) ?? '';
  }

  @override
  void setCurrency(String currencyCode) {
    sharedPreferences.setString(AppConstants.currency, currencyCode);
  }

  @override
  Future<bool> removeSharedData() {
    return sharedPreferences.remove(AppConstants.token);
  }

  @override
  void disableIntro() {
    sharedPreferences.setBool(AppConstants.intro, false);
  }

  @override
  bool? showIntro() {
    if(!sharedPreferences.containsKey(AppConstants.intro)) {
      sharedPreferences.setBool(AppConstants.intro, true);
    }
    return sharedPreferences.getBool(AppConstants.intro);

  }

  @override
  void disableNotification() {
    sharedPreferences.setBool(AppConstants.notificationSound, false);
  }

  @override
  void enableNotification() {
    sharedPreferences.setBool(AppConstants.notificationSound, true);
  }

  @override
  bool? notificationSound() {
    if(!sharedPreferences.containsKey(AppConstants.notificationSound)) {
      sharedPreferences.setBool(AppConstants.notificationSound, true);
    }
    return sharedPreferences.getBool(AppConstants.notificationSound);
  }

  @override
  String? getCachedConfigJson() {
    return sharedPreferences.getString(AppConstants.cachedConfigJson);
  }

  @override
  Future<bool> cacheConfigJson(String json) {
    return sharedPreferences.setString(AppConstants.cachedConfigJson, json);
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