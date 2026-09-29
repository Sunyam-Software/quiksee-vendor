import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/dimensions.dart';

void showQuikseeSnackBarWidget(
  String? message, {
  bool isError = true,
  bool isWarning = false,
}) {
  final Color backgroundColor;
  if (isWarning) {
    backgroundColor = Colors.orange.shade800;
  } else {
    backgroundColor = isError ? Colors.red : Colors.green;
  }
  Get.showSnackbar(GetSnackBar(
    backgroundColor: backgroundColor,
    message: message,
    duration: const Duration(seconds: 3),
    snackStyle: SnackStyle.FLOATING,
    margin:  EdgeInsets.all(Dimensions.paddingSizeSmall),
    borderRadius: 10,
    isDismissible: true,
  ));
}