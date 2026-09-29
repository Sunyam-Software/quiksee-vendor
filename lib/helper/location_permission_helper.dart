import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/home/widgets/permission_dialog_widget.dart';

class LocationPermissionHelper {
  static Future<bool> isLocationReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<void> openGpsSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<bool> ensureLocationReadyForOnline({
    BuildContext? context,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await openGpsSettings();
    }
    return ensureLocationReady(context: context, showDialog: true);
  }

  static Future<bool> ensureLocationReady({
    BuildContext? context,
    bool showDialog = true,
  }) async {
    final BuildContext? ctx = context ?? Get.context;
    if (ctx == null) return isLocationReady();

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (showDialog) {
        await _showLocationServiceDialog(ctx);
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (showDialog) {
        await _showPermissionDialog(ctx, deniedForever: false);
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (showDialog) {
        await _showPermissionDialog(ctx, deniedForever: true);
      }
      return false;
    }

    return true;
  }

  static Future<void> _showLocationServiceDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('alert'.tr),
        content: Text('location_service_disabled'.tr),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await Geolocator.openLocationSettings();
            },
            child: Text('turn_on_location'.tr),
          ),
        ],
      ),
    );
  }

  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required bool deniedForever,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PermissionDialogWidget(
        isDenied: !deniedForever,
        onPressed: () async {
          Navigator.pop(dialogContext);
          if (deniedForever) {
            await Geolocator.openAppSettings();
          } else {
            await Geolocator.requestPermission();
          }
        },
      ),
    );
  }
}
