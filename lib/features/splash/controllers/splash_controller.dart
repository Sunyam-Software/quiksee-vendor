
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/maintenance/maintenance_screen.dart';
import 'package:quiksee/features/splash/domain/models/business_pages_model.dart';
import 'package:quiksee/features/splash/domain/models/config_model.dart';
import 'package:quiksee/features/splash/domain/services/splash_service_interface.dart';

class SplashController extends GetxController implements GetxService {
  final SplashServiceInterface splashServiceInterface;
  SplashController({required this.splashServiceInterface});

  ConfigModel? _configModel;
  BaseUrls? _baseUrls;
  BaseUrls? get baseUrls => _baseUrls;
  bool _firstTimeConnectionCheck = true;
  CurrencyList? _myCurrency;
  CurrencyList? _usdCurrency;
  CurrencyList? _defaultCurrency;
  CurrencyList? get myCurrency => _myCurrency;
  CurrencyList? get usdCurrency => _usdCurrency;
  CurrencyList? get defaultCurrency => _defaultCurrency;
  int? _currencyIndex;
  int? get currencyIndex => _currencyIndex;

  ConfigModel? get configModel => _configModel;
  DateTime get currentTime => DateTime.now();
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;

  List<BusinessPageModel>? _defaultBusinessPages;
  List<BusinessPageModel>? get defaultBusinessPages => _defaultBusinessPages;

  /// Apply a config map into memory (live API or disk cache).
  bool _applyConfigMap(dynamic body) {
    try {
      final Map<String, dynamic> map = body is Map<String, dynamic>
          ? body
          : Map<String, dynamic>.from(body as Map);
      _configModel = ConfigModel.fromJson(map);
      _baseUrls = _configModel?.baseUrls;
      String? currencyCode = splashServiceInterface.getCurrency();
      final currencies = _configModel?.currencyList;
      if (currencies != null) {
        for (final currencyList in currencies) {
          if (currencyList.id == _configModel!.systemDefaultCurrency) {
            if (currencyCode == null || currencyCode.isEmpty) {
              currencyCode = currencyList.code;
            }
            _defaultCurrency = currencyList;
          }
          if (currencyList.code == 'USD') {
            _usdCurrency = currencyList;
          }
        }
      }
      getCurrencyData(currencyCode);
      return true;
    } catch (e) {
      debugPrint('ConfigModel parse error: $e');
      return false;
    }
  }

  bool loadCachedConfig() {
    final raw = splashServiceInterface.getCachedConfigJson();
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (!_applyConfigMap(decoded)) return false;
      update();
      return true;
    } catch (e) {
      debugPrint('Cached config load error: $e');
      return false;
    }
  }

  Future<bool> getConfigData() async {
    Response response = await splashServiceInterface.getConfigData();
    bool isSuccess = false;
    if(response.statusCode == 200) {
      if (!_applyConfigMap(response.body)) {
        ApiChecker.checkApi(response);
        update();
        return false;
      }
      try {
        unawaited(splashServiceInterface.cacheConfigJson(jsonEncode(response.body)));
      } catch (_) {}
      if(_configModel?.maintenanceModeData?.maintenanceStatus == 0){
        if(_configModel?.maintenanceModeData?.selectedMaintenanceSystem?.deliverymanApp == 1 ) {
          if(_configModel?.maintenanceModeData?.maintenanceTypeAndDuration?.maintenanceDuration == 'customize'){

            DateTime now = DateTime.now();
            DateTime specifiedDateTime = DateTime.parse(_configModel!.maintenanceModeData!.maintenanceTypeAndDuration!.startDate!);

            Duration difference = specifiedDateTime.difference(now);

            if(difference.inMinutes > 0 && (difference.inMinutes < 60 || difference.inMinutes == 60)){
              _startTimer(specifiedDateTime);
            }

          }
        }
      }
      isSuccess = true;
    }else {
      ApiChecker.checkApi(response);
      isSuccess = false;
    }
    update();
    return isSuccess;
  }

  Future<void> getBusinessPagesList(String type) async {
    Response response = await splashServiceInterface.getBusinessPages(type);

    if (response.statusCode == 200) {
      if(type == 'default') {
        _defaultBusinessPages = [];
        response.body.forEach((data) {_defaultBusinessPages?.add(BusinessPageModel.fromJson(data));});
      }
    } else {
      ApiChecker.checkApi(response);
    }

    update();
  }


  void getCurrencyData(String? currencyCode) {
    final currencies = _configModel?.currencyList;
    if (currencies == null) return;
    for (final currency in currencies) {
      if (currencyCode == currency.code) {
        _myCurrency = currency;
        _currencyIndex = currencies.indexOf(currency);
        return;
      }
    }
  }


  void setCurrency(int index) {
    final currencies = _configModel?.currencyList;
    if (currencies == null || index < 0 || index >= currencies.length) {
      return;
    }
    splashServiceInterface.setCurrency(currencies[index].code!);
    getCurrencyData(currencies[index].code);
    update();
  }

  Future<bool> initSharedData() {
    return splashServiceInterface.initSharedData();
  }

  Future<bool> removeSharedData() {
    return splashServiceInterface.removeSharedData();
  }

  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  bool? showIntro() {
    return splashServiceInterface.showIntro();

  }
  bool? notificationSound() {
    return splashServiceInterface.notificationSound();


  }
  void disableIntro() {
    splashServiceInterface.disableIntro();
  }
  void disableNotification() {
    splashServiceInterface.disableNotification();
    update();
  }
  void enableNotification() {
    splashServiceInterface.enableNotification();
    update();
  }


  void _startTimer (DateTime startTime){
    Timer.periodic(const Duration(seconds: 30), (Timer timer) {

      DateTime now = DateTime.now();

      if (now.isAfter(startTime) || now.isAtSameMomentAs(startTime)) {
        timer.cancel();
        Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(
          builder: (_) => const MaintenanceScreen(),
          settings: const RouteSettings(name: 'MaintenanceScreen'),
        ));
      }

    });
  }
}
