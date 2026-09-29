import 'package:flutter/material.dart';
import 'package:quiksee_vendor_app/main.dart';

Future<TimeOfDay?> showQuikseeTimePicker({DateTime? dateTime}) async {
  DateTime time = dateTime ?? DateTime.now();

  return await showTimePicker(

    context: Get.context!,
    initialTime: TimeOfDay(hour: time.hour, minute: time.minute),

    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      );
    },

  );
}