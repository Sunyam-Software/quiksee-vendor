
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiksee/features/language/domain/models/language_model.dart';
import 'package:quiksee/utill/app_constants.dart';

class LanguageController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  LanguageController({required this.sharedPreferences}){
    initializeAllLanguages(Get.context!);
  }

  int? _selectIndex = 0;
  int? get selectIndex => _selectIndex;

  void setSelectIndex(int? index) {
    _selectIndex = index;
    update();
  }

  List<LanguageModel> _languages = [];
  List<LanguageModel> get languages => _languages;

  void searchLanguage(String query, BuildContext context) {
    if (query.isEmpty) {
      _languages.clear();
      _languages = AppConstants.languages;
      update();
    } else {
      _selectIndex = -1;
      _languages = [];
      // ignore: avoid_function_literals_in_foreach_calls
      AppConstants.languages.forEach((product) async {
        if (product.languageName!.toLowerCase().contains(query.toLowerCase())) {
          _languages.add(product);
        }
      });
      update();
    }
  }

  void initializeAllLanguages(BuildContext context) {
    if (_languages.isEmpty) {
      _languages.clear();
      _languages = AppConstants.languages;
    }

    _selectIndex = _getCurrentLanguageIndex();

  }

  int _getCurrentLanguageIndex() {
    for (int index = 0; index < AppConstants.languages.length; index++) {
      if (AppConstants.languages[index].languageCode == sharedPreferences.getString(AppConstants.languageCode)) {
        return index;
      }
    }
    return 0;
  }

}
