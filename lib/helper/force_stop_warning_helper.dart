import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForceStopWarningHelper {
  static const _cooldown = Duration(hours: 12);

  static Future<void> maybeShowAfterGoOnline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(AppConstants.forceStopWarningShownAt) ?? 0;
      final lastAt = DateTime.fromMillisecondsSinceEpoch(last);
      if (DateTime.now().difference(lastAt) < _cooldown) return;

      await prefs.setInt(
        AppConstants.forceStopWarningShownAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));
    if (Get.context == null) return;

    await Get.dialog(
      AlertDialog(
        title: Text('force_stop_warning_title'.tr),
        content: Text('force_stop_warning_body'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('got_it'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
