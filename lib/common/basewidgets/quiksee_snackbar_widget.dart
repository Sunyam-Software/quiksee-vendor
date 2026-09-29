import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quiksee_vendor_app/main.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'quiksee_toast.dart';

enum SnackBarType {
  error,
  warning,
  success,
}

void showQuikseeSnackBarWidget(String? message, BuildContext? context, {bool isError = true, bool isToaster = false, SnackBarType sanckBarType = SnackBarType.success}) {
    final scaffold = ScaffoldMessenger.of(context ?? Get.context!);
    scaffold.showSnackBar(
      SnackBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        content: QuikseeToast(text: message ?? '', sanckBarType: sanckBarType),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

void showQuikseeToast({bool isSuccess = true, required String message, required BuildContext context}) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: isSuccess ? Theme.of(context).colorScheme.onTertiaryContainer : Theme.of(context).colorScheme.error,
      textColor: Colors.white,
      fontSize: Dimensions.fontSizeDefault
  );
}