import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/helper/location_permission_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class GpsStatusWidget extends StatefulWidget {
  const GpsStatusWidget({super.key});

  @override
  State<GpsStatusWidget> createState() => _GpsStatusWidgetState();
}

class _GpsStatusWidgetState extends State<GpsStatusWidget>
    with WidgetsBindingObserver {
  static const Color _brandGreen = Color(0xFF0F6B2D);
  static const Color _brandGold = Color(0xFFA36A00);
  static const Color _gpsOffBg = Color(0xFFFFF3E0);
  static const Color _gpsOnBg = Color(0xFFE8F5E9);

  bool? _locationReady;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().syncOnlineGpsAndLocation(context: context);
      }
    }
  }

  Future<void> _refreshStatus() async {
    final ready = await LocationPermissionHelper.isLocationReady();
    if (mounted) {
      setState(() => _locationReady = ready);
    }
  }

  Future<void> _onGpsPressed() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await LocationPermissionHelper.openGpsSettings();
      return;
    }

    await LocationPermissionHelper.ensureLocationReady(context: context);
    await _refreshStatus();

    if (!mounted) return;
    if (Get.isRegistered<ProfileController>()) {
      await Get.find<ProfileController>().syncOnlineGpsAndLocation(
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_locationReady == null) {
      return const SizedBox.shrink();
    }

    final ready = _locationReady!;
    final bgColor = ready
        ? (Get.isDarkMode ? _brandGreen.withValues(alpha: 0.2) : _gpsOnBg)
        : (Get.isDarkMode ? _brandGold.withValues(alpha: 0.15) : _gpsOffBg);
    final accent = ready ? _brandGreen : _brandGold;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeExtraLarge,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeExtraLarge,
        0,
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Row(
            children: [
              Icon(
                ready ? Icons.gps_fixed : Icons.gps_off,
                color: accent,
                size: 22,
              ),
              SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  ready ? 'gps_on'.tr : 'tap_to_enable_gps'.tr,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Get.isDarkMode
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : accent,
                  ),
                ),
              ),
              if (!ready)
                ElevatedButton(
                  onPressed: _onGpsPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSizeSmall),
                    ),
                  ),
                  child: Text(
                    'on_gps'.tr,
                    style: rubikMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    color: _brandGreen.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeSmall),
                  ),
                  child: Text(
                    'gps_on'.tr,
                    style: rubikMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: _brandGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
