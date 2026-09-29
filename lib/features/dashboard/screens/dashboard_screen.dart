import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/helper/vendor_ready_popup_helper.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_binding.dart';
import 'package:quiksee/features/dashboard/controllers/dashboard_controller.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/home/screens/home_screen.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/animated_custom_dialog_widget.dart';
import 'package:quiksee/common/basewidgets/confirmation_dialog_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_botom_navy_bar_widget.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final int? chatIndex;
  const DashboardScreen({super.key, required this.pageIndex, this.chatIndex});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  static const Color _bottomBarGreen = Color(0xFF0F6B2D);
  static const Color _bottomBarGold = Color(0xFFFFC107);

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  final PageStorageBucket bucket = PageStorageBucket();

  OrderController orderController = Get.find<OrderController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (OrderTransferBinding.ensure()) {
      Get.find<OrderTransferController>().startIncomingOfferWatch();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(VendorReadyPopupHelper.processPending());
      // Backup if wake prefs arrived after first call.

      Get.find<DistancePaymentController>().loadConfig(silent: true);
      Get.find<ProfileController>().getProfile(silent: true);

      final dashboard = Get.find<DashboardController>();
      if (widget.pageIndex == 2) {
        dashboard.selectConversationScreen(
          isUpdate: true,
          chatIndex: widget.chatIndex,
        );
      } else if (widget.pageIndex == 3 || widget.pageIndex == 4) {
        dashboard.selectProfileScreen(isUpdate: true);
      } else {
        dashboard.selectHomePage(first: false);
      }

      if (orderController.allOrderHistory == null) {
        unawaited(Get.find<OrderController>().ensureOrderHistoryLoaded());
      }
      if (OrderTransferBinding.ensure()) {
        unawaited(Get.find<OrderTransferController>().loadRecentOutgoing());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      VendorReadyPopupHelper.processPending();
      orderController.refreshCurrentOrdersOnly(promptAccept: false);
      if (Get.isRegistered<AssignmentController>() &&
          Get.find<AssignmentController>().scheduledDeliveryEnabled) {
        orderController.refreshScheduledCurrentOrdersOnly(promptAccept: false);
      }
      Get.find<ProfileController>().refreshWalletBalances();
      Get.find<ProfileController>().onAppResumed();
      orderController.syncNewOrderPolling();
      if (Get.isRegistered<AssignmentController>()) {
        Get.find<AssignmentController>().syncWithDriverStatus();
      }
      if (Get.isRegistered<RiderController>()) {
        Get.find<RiderController>().checkArrivalOnResume();
      }
      if (OrderTransferBinding.ensure()) {
        final transfer = Get.find<OrderTransferController>();
        transfer.startIncomingOfferWatch();
        unawaited(transfer.loadRecentOutgoing());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if( Get.find<DashboardController>().currentTab != 0) {
          Get.find<DashboardController>().selectHomePage();
        } else {
          _onWillPop(context);
        }
        return;
      },

      child: GetBuilder<DashboardController>(builder: (menuController) {
        return GetBuilder<AssignmentController>(
          builder: (assignmentController) {
            final pendingBadgeCount =
                assignmentController.pendingOfferBadgeCount;

            return Scaffold(
          resizeToAvoidBottomInset: false,
          body: PageStorage(
            bucket: bucket,
            child: menuController.currentScreen ??
                HomeScreen(onTap: (_) {}),
          ),
          bottomNavigationBar: BottomNavBarWidget(
            selectedIndex: menuController.currentTab,
            showElevation: true,
            backgroundColor: _bottomBarGreen,
            animationDuration: const Duration(milliseconds: 500),
            itemCornerRadius: 100,
            curve: Curves.ease,
            items: [
              _barItem(
                Images.homeIcon,
                'home'.tr,
                0,
                menuController,
                badgeCount: pendingBadgeCount,
              ),
              _barItem(Images.orderIcon, 'order_history'.tr, 1, menuController),
              _barItem(Images.chatIcon, 'message'.tr, 2, menuController),
              _barItem(Images.profileIcon, 'profile'.tr, 3, menuController),
            ],
            onItemSelected: (int index) {
              if(index == 0){
                menuController.selectHomePage();
              }else if(index == 1){
                menuController.selectOrderHistoryScreen();
              }else if(index == 2){
                menuController.selectConversationScreen();
              }else if(index == 3){
                menuController.selectProfileScreen();
              }
            },
          ),

        );
          },
        );
      }),
    );
  }

  BottomNavyBarItem _barItem(
    String icon,
    String label,
    int index,
    DashboardController menuController, {
    int badgeCount = 0,
  }) {
    final iconWidget = _navIcon(icon, index, menuController);
    final badgedIcon = badgeCount > 0
        ? Badge(
            label: Text(
              badgeCount > 9 ? '9+' : '$badgeCount',
              style: rubikMedium.copyWith(
                fontSize: 9,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            child: iconWidget,
          )
        : iconWidget;

    return BottomNavyBarItem(
      activeColor: Theme.of(context).primaryColor,
      inactiveColor: _bottomBarGold,
      textAlign: TextAlign.center,
      icon: index == menuController.currentTab
          ? const SizedBox()
          : SizedBox(
              width: Dimensions.iconSizeMenu,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: badgedIcon,
              ),
            ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          badgeCount > 0
              ? Badge(
                  label: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: rubikMedium.copyWith(
                      fontSize: 8,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red,
                  child: Image.asset(
                    icon,
                    color: index == menuController.currentTab
                        ? Colors.white
                        : _bottomBarGold,
                    width: 16,
                  ),
                )
              : Image.asset(
                  icon,
                  color: index == menuController.currentTab
                      ? Colors.white
                      : _bottomBarGold,
                  width: 16,
                ),
          SizedBox(width: Dimensions.paddingSizeSmall),
          FittedBox(
            child: Text(
              label,
              style: rubikRegular.copyWith(
                color: index == menuController.currentTab
                    ? Colors.white
                    : _bottomBarGold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(String icon, int index, DashboardController menuController) {
    return Image.asset(
      icon,
      color: index == menuController.currentTab
          ? Theme.of(context).cardColor
          : _bottomBarGold,
    );
  }

}
Future<bool> _onWillPop(BuildContext context) async {
  showAnimatedDialogWidget(context,  ConfirmationDialogWidget(icon: Images.logOut,
    title: 'exit_app'.tr,
    description: 'do_you_want_to_exit_the_app'.tr, onYesPressed: (){
    SystemNavigator.pop();
  },),isFlip: true);
  return true;
}

