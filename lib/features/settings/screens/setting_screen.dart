import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import 'package:quiksee_vendor_app/helper/kitchen_ring_prefs.dart';
import 'package:quiksee_vendor_app/localization/language_constrants.dart';
import 'package:quiksee_vendor_app/features/splash/controllers/splash_controller.dart';
import 'package:quiksee_vendor_app/theme/controllers/theme_controller.dart';
import 'package:quiksee_vendor_app/utill/dimensions.dart';
import 'package:quiksee_vendor_app/utill/quiksee_brand_colors.dart';
import 'package:quiksee_vendor_app/utill/styles.dart';
import 'package:quiksee_vendor_app/common/basewidgets/quiksee_app_bar_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _ringEnabled = true;
  bool _ringLoaded = false;

  @override
  void initState() {
    super.initState();
    KitchenRingPrefs.isEnabled().then((on) {
      if (!mounted) return;
      setState(() {
        _ringEnabled = on;
        _ringLoaded = true;
      });
    });
  }

  Future<void> _onRingToggle(bool enabled) async {
    await KitchenRingPrefs.setEnabled(enabled);
    if (!mounted) return;
    setState(() => _ringEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SplashController>(context, listen: false).setFromSetting(true);

    return Scaffold(
      appBar: QuikseeAppBarWidget(
        title: getTranslated('settings', context),
        useQuikseeBrandedHeader: true,
      ),
      body: ListView(physics: const BouncingScrollPhysics(), children: [
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        if (_ringLoaded)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Provider.of<ThemeController>(context, listen: false)
                            .darkTheme
                        ? Theme.of(context).primaryColor.withValues(alpha: 0)
                        : Colors.grey[
                            Provider.of<ThemeController>(context).darkTheme
                                ? 800
                                : 200]!,
                    spreadRadius: 0.5,
                    blurRadius: 0.3,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeDefault,
                  horizontal: Dimensions.paddingSizeLarge,
                ),
                child: Row(
                  children: [
                    Icon(
                      _ringEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: QuikseeBrandColors.seeTextGreen,
                      size: Dimensions.iconSizeLarge,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslated('kitchen_ring', context) ??
                                'New order ringtone',
                            style: titilliumRegular.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getTranslated('kitchen_ring_hint', context) ??
                                'Off = no sound, phone still vibrates. New order popup still shows.',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    FlutterSwitch(
                      width: 50,
                      height: 28,
                      toggleSize: 20,
                      padding: 2,
                      value: _ringEnabled,
                      activeColor: QuikseeBrandColors.seeTextGreen,
                      onToggle: _onRingToggle,
                    ),
                  ],
                ),
              ),
            ),
          ),

      ]),
    );
  }
}
