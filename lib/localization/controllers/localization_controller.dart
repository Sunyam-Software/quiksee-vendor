import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee_vendor_app/features/auth/controllers/auth_controller.dart';
import 'package:quiksee_vendor_app/localization/models/language_model.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';

class LocalizationController extends ChangeNotifier {
  final SharedPreferences? sharedPreferences;

  LocalizationController({required this.sharedPreferences}) {
    _loadCurrentLanguage();
  }

  int? _languageIndex;
  Locale _locale = Locale(AppConstants.languages[0].languageCode!, AppConstants.languages[0].countryCode);
  bool _isLtr = true;
  Locale get locale => _locale;
  bool get isLtr => _isLtr;
  int? get languageIndex => _languageIndex;
  List<LanguageModel> _languages = [];
  List<LanguageModel> get languages => _languages;

  void setLanguage(Locale locale, int index) {
    _locale = locale;
    _languageIndex = index;
    if(_locale.languageCode == 'ar') {
      _isLtr = false;
    }else {
      _isLtr = true;
    }
    _saveLanguage(_locale);
    Provider.of<AuthController>(Get.context!, listen: false).setCurrentLanguage(locale.countryCode == 'US'?'en': _locale.countryCode!.toLowerCase());
    notifyListeners();
  }

  Future<void> _loadCurrentLanguage() async {
    const english = Locale('en', 'US');
    _locale = english;
    _languageIndex = 0;
    _isLtr = true;
    _languages = List<LanguageModel>.from(AppConstants.languages);
    await _saveLanguage(english);
    notifyListeners();
  }

  Future<void> _saveLanguage(Locale locale) async {
    sharedPreferences!.setString(AppConstants.languageCode, locale.languageCode);
    sharedPreferences!.setString(AppConstants.countryCode, locale.countryCode!);
  }

  String? getCurrentLanguage() {
    return sharedPreferences!.getString(AppConstants.countryCode == 'US'? 'en' : AppConstants.countryCode) ?? "en";
  }

}