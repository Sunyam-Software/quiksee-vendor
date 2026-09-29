
import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/chat/screens/conversation_screen.dart';
import 'package:quiksee/features/home/screens/home_screen.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/screens/order_history_screen.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/features/profile/screens/profile_screen.dart';

class DashboardController extends GetxController implements GetxService{
  int _currentTab = 0;
  int get currentTab => _currentTab;
  late List<Widget> screen;
  Widget? _currentScreen;
  Widget? get currentScreen => _currentScreen;
  DashboardController() {
    initPage();
  }

  void _safeUpdate() {
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      update();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) update();
    });
  }

  void selectHomePage({bool first = true}) {
    _currentScreen = screen[0];
    _currentTab = 0;
    if (!first) {
      unawaited(Get.find<ProfileController>().refreshWalletBalances());
    }
    _safeUpdate();
  }


  void initPage() {
    screen = [
      HomeScreen(onTap: (int index) {
        _currentTab = index;
        _safeUpdate();
      }),
      const OrderHistoryScreen(fromMenu: true),
      const ConversationScreen(fromNotification: false),
      const ProfileScreen(),
    ];
    _currentScreen = screen[0];
  }


  void selectOrderHistoryScreen({bool fromHome = false}) {
    _currentScreen = screen[1];
    _currentTab = 1;
    if (fromHome) {
      Get.find<OrderController>().setOrderTypeIndex(0);
    } else {
      unawaited(Get.find<OrderController>().ensureOrderHistoryLoaded());
    }
    _safeUpdate();
  }


  void selectConversationScreen({bool isUpdate = true, int? chatIndex}) {
    _currentScreen = ConversationScreen(fromNotification: !isUpdate, chatIndex: chatIndex);
    _currentTab = 2;
    if (isUpdate) {
      _safeUpdate();
    }
  }


  void selectProfileScreen({bool isUpdate = true}) {
    _currentScreen = const ProfileScreen();
    _currentTab = 3;
    Get.find<ProfileController>().getProfile(silent: true);
    if (isUpdate) {
      _safeUpdate();
    }
  }

}
