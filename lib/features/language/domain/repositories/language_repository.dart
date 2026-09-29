import 'package:flutter/material.dart';
import 'package:quiksee/features/language/domain/models/language_model.dart';
import 'package:quiksee/utill/app_constants.dart';

class LanguageRepository {
  List<LanguageModel> getAllLanguages({BuildContext? context}) {
    return AppConstants.languages;
  }
}
