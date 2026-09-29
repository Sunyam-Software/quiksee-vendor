import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:quiksee/theme/quiksee_dark_theme.dart';
import 'package:quiksee/theme/quiksee_light_theme.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/messages.dart';
import 'package:quiksee/features/splash/screens/splash_screen.dart';
import 'common/controllers/localization_controller.dart';
import 'features/splash/controllers/splash_controller.dart';
import 'theme/controllers/theme_controller.dart';
import 'helper/get_di.dart' as di;
import 'package:url_strategy/url_strategy.dart';
import 'features/auth/controllers/auth_controller.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'quiksee_delivery_channel',
  'Quiksee Delivery',
  description: 'Order updates, chat messages and alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final AndroidNotificationChannel newOrderChannel = AndroidNotificationChannel(
  'quiksee_new_order_v5',
  'New orders',
  description: 'Loud alert when a new delivery order arrives (works on lock screen)',
  importance: Importance.max,
  playSound: true,
  audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
  bypassDnd: true,
  enableVibration: true,
  vibrationPattern: Int64List.fromList([0, 600, 150, 600, 150, 800, 150, 800]),
);

final AndroidNotificationChannel navigationChannel = AndroidNotificationChannel(
  'quiksee_active_navigation',
  'Active navigation',
  description: 'Reminder to mark delivery after Google Maps navigation',
  importance: Importance.max,
  playSound: false,
  enableVibration: false,
);

Future<void> main() async {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  final languages = await di.init();

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidNotifications = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidNotifications?.requestNotificationsPermission();
      await androidNotifications?.createNotificationChannel(channel);
      await androidNotifications?.createNotificationChannel(newOrderChannel);
      await androidNotifications?.createNotificationChannel(navigationChannel);
    }
  } catch (e) {
    debugPrint('Early notification init failed: $e');
  }

  runApp(MyApp(languages: languages));

  unawaited(_initializeDeferredServices());
}

Future<void> _initializeDeferredServices() async {
  try {
    await FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: true);
  } catch (_) {}

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    final androidNotifications = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.requestNotificationsPermission();
    await androidNotifications?.createNotificationChannel(channel);
    await androidNotifications?.createNotificationChannel(newOrderChannel);
    await androidNotifications?.createNotificationChannel(navigationChannel);
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.isLoggedIn()) {
          unawaited(auth.updateToken());
        }
      }
    });
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>> languages;
  const MyApp({super.key, required this.languages});
  @override
  Widget build(BuildContext context) {

    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (splashController) {
          return  GetMaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: Get.key,
            theme: themeController.darkTheme ? dark : light,
            locale: localizeController.locale,
            translations: Messages(languages: languages),
            fallbackLocale: Locale(AppConstants.languages[0].languageCode!, AppConstants.languages[0].countryCode),
            home: const SplashScreen(),
            defaultTransition: Transition.topLevel,
            transitionDuration: const Duration(milliseconds: 500),
            builder: (context, child) {
              final currentChild = child ?? const SizedBox.shrink();
              final wrappedChild = themeController.darkTheme
                  ? currentChild
                  : Stack(
                      children: [
                        currentChild,
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Opacity(
                                opacity: 0.045,
                                child: Image.asset(
                                  Images.quikseeLogo,
                                  width: MediaQuery.of(context).size.width * 0.95,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );

              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: SafeArea(top: false, child: wrappedChild),
              );
            }
          );
        });
      });
    });
  }
}
