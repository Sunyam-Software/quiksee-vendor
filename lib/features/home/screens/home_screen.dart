import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/auth/controllers/auth_controller.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/dashboard/controllers/dashboard_controller.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/widgets/order_history_shimmer_widget.dart';
import 'package:quiksee/features/order_transfer/controllers/order_transfer_controller.dart';
import 'package:quiksee/features/order_transfer/helpers/order_transfer_binding.dart';
import 'package:quiksee/features/profile/controllers/profile_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/common/basewidgets/quiksee_app_bar_widget.dart';
import 'package:quiksee/common/basewidgets/no_data_screen_widget.dart';
import 'package:quiksee/common/basewidgets/title_widget_widget.dart';
import 'package:quiksee/features/home/widgets/earn_statement_widget.dart';
import 'package:quiksee/features/home/widgets/gps_status_widget.dart';
import 'package:quiksee/features/home/widgets/ongoing_order_card_widget.dart';
import 'package:quiksee/features/home/widgets/trip_status_widget.dart';
import 'package:quiksee/features/tip/controllers/tip_controller.dart';
import 'package:quiksee/features/tip/widgets/tip_summary_widget.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/features/permissions/screens/app_permissions_screen.dart';
import 'package:quiksee/helper/app_permissions_helper.dart';
import 'package:quiksee/helper/new_order_alert_helper.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(int index) onTap;
  const HomeScreen({super.key, required this.onTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _readinessHintShown = false;
  bool _tokenSynced = false;
  bool _showPermissionBanner = false;
  Timer? _walletSyncTimer;
  PermissionReminderLevel _permissionReminderLevel =
      PermissionReminderLevel.none;

  Future<void> _loadData() async {
    final deferProfileSideEffects = Get.isRegistered<AssignmentController>() &&
        Get.find<AssignmentController>().isBusyWithOffer;

    final List<Future<void>> startupTasks = [];

    if (!_tokenSynced && Get.isRegistered<AuthController>()) {
      startupTasks.add(
        Get.find<AuthController>().updateToken().then((_) {
          _tokenSynced = true;
        }),
      );
    }

    startupTasks.add(
      Get.find<OrderController>().getCurrentOrders(
        showLoading: true,
        promptAccept: false,
      ),
    );

    startupTasks.add(
      Get.find<ProfileController>().getProfile(
        silent: true,
        skipSideEffects: true,
        waitForInFlight: true,
      ),
    );

    await Future.wait(startupTasks);

    unawaited(Get.find<OrderController>().ensureOrderHistoryLoaded());
    unawaited(_refreshPermissionBanner());
    unawaited(_showOrderReceiveHintsIfNeeded());

    if (deferProfileSideEffects && Get.isRegistered<AssignmentController>()) {
      unawaited(Get.find<AssignmentController>().loadScheduledConfig());
      unawaited(Get.find<AssignmentController>().syncWithDriverStatus());
    }

    unawaited(Get.find<DistancePaymentController>().loadConfig(silent: true));
    unawaited(Get.find<TipController>().getTipSummary(silent: true));
    Get.find<OrderController>().syncNewOrderPolling();
    if (OrderTransferBinding.ensure()) {
      final transfer = Get.find<OrderTransferController>();
      transfer.startIncomingOfferWatch();
      unawaited(transfer.loadRecentOutgoing());
    }
  }

  Future<void> _showOrderReceiveHintsIfNeeded() async {
    if (_readinessHintShown || !mounted) return;

    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true) {
      _readinessHintShown = true;
      showQuikseeSnackBarWidget('account_not_activated'.tr);
      return;
    }

    if (profile?.isOnline != 1) {
      _readinessHintShown = true;
      showQuikseeSnackBarWidget('go_online_for_orders'.tr);
      return;
    }
  }

  Future<void> _refreshPermissionBanner() async {
    if (!mounted) return;
    if (Get.isBottomSheetOpen == true) return;
    if (Get.isRegistered<AssignmentController>() &&
        Get.find<AssignmentController>().isBusyWithOffer) {
      return;
    }
    if (NewOrderAlertHelper.isActive) return;

    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isAccountActive != true || profile?.isOnline != 1) {
      if (_showPermissionBanner) {
        setState(() => _showPermissionBanner = false);
      }
      return;
    }

    final level = await AppPermissionsHelper.homeReminderLevel();
    final shouldShow = await AppPermissionsHelper.shouldShowHomePermissionReminder();
    if (!mounted) return;
    setState(() {
      _permissionReminderLevel = level;
      _showPermissionBanner = shouldShow;
    });
  }

  void _openPermissionsScreen() {
    Get.to(
      () => const AppPermissionsScreen(
        nextRoute: AppPermissionsNextRoute.dashboard,
      ),
    )?.then((_) => _refreshPermissionBanner());
  }

  Future<void> _dismissPermissionBanner() async {
    await AppPermissionsHelper.dismissHomePermissionReminder();
    if (!mounted) return;
    setState(() => _showPermissionBanner = false);
  }

  void _syncDashboardWallet() {
    if (!mounted) return;
    Get.find<ProfileController>().getProfile(
      silent: true,
      skipSideEffects: true,
      waitForInFlight: false,
    );
  }

  @override
  void initState() {
    super.initState();
    _walletSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncDashboardWallet(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkPermission(context);
      _loadData();
    });
  }

  @override
  void dispose() {
    _walletSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QuikseeAppBarWidget(title: 'dashboard'.tr, isSwitch: true),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (_showPermissionBanner)
                    _PermissionReminderBanner(
                      level: _permissionReminderLevel,
                      onFix: _openPermissionsScreen,
                      onDismiss: _permissionReminderLevel ==
                              PermissionReminderLevel.recommended
                          ? _dismissPermissionBanner
                          : null,
                    ),
                  const EarnStatementWidget(),
                  const TipSummaryWidget(),
                  const GpsStatusWidget(),
                  SizedBox(height: Dimensions.paddingSizeDefault),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeExtraLarge,
                      Dimensions.paddingSizeDefault,
                      Dimensions.paddingSizeExtraLarge,
                      Dimensions.paddingSizeExtraSmall,
                    ),
                    child: TitleWidget(
                      title: 'ongoing'.tr,
                      onTap: () {
                        Get.find<DashboardController>()
                            .selectOrderHistoryScreen(fromHome: true);
                        Get.find<OrderController>().setOrderTypeIndex(0);
                      },
                    ),
                  ),
                  GetBuilder<OrderController>(
                    builder: (orderController) {
                      final showScheduledTab =
                          orderController.scheduledDeliveryEnabled;
                      // Keep transfer tab at index 2 even if scheduled is hidden.
                      if (!showScheduledTab &&
                          orderController.homeDeliveryTabIndex == 1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          orderController.setHomeDeliveryTabIndex(0);
                        });
                      }
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeExtraLarge,
                          vertical: Dimensions.paddingSizeExtraSmall,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DeliveryTabChip(
                                label: 'normal_delivery'.tr,
                                selected:
                                    orderController.homeDeliveryTabIndex == 0,
                                onTap: () => orderController
                                    .setHomeDeliveryTabIndex(0),
                              ),
                            ),
                            if (showScheduledTab) ...[
                              SizedBox(width: Dimensions.paddingSizeSmall),
                              Expanded(
                                child: _DeliveryTabChip(
                                  label: 'scheduled_delivery'.tr,
                                  selected:
                                      orderController.homeDeliveryTabIndex ==
                                          1,
                                  onTap: () => orderController
                                      .setHomeDeliveryTabIndex(1),
                                ),
                              ),
                            ],
                            SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: _DeliveryTabChip(
                                label: 'transfer_order'.tr,
                                selected:
                                    orderController.homeDeliveryTabIndex == 2,
                                onTap: () {
                                  orderController.setHomeDeliveryTabIndex(2);
                                  if (OrderTransferBinding.ensure()) {
                                    unawaited(Get.find<
                                            OrderTransferController>()
                                        .loadRecentOutgoing());
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  GetBuilder<OrderController>(
                    builder: (orderController) {
                      if (orderController.homeDeliveryTabIndex != 2) {
                        return const SizedBox.shrink();
                      }
                      if (!OrderTransferBinding.ensure()) {
                        return const SizedBox.shrink();
                      }
                      return GetBuilder<OrderTransferController>(
                        builder: (transfer) {
                          final items = transfer.recentOutgoing;
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeExtraLarge,
                              Dimensions.paddingSizeSmall,
                              Dimensions.paddingSizeExtraLarge,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'recently_transferred'.tr,
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                  ),
                                ),
                                SizedBox(height: Dimensions.paddingSizeSmall),
                                if (items.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: Dimensions.paddingSizeLarge,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'no_transfers_yet'.tr,
                                        style: rubikRegular.copyWith(
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...items.take(5).map((item) {
                                    final orderId = item['order_id'];
                                    final toName = (item['to_rider_name'] ?? '')
                                        .toString();
                                    final label = toName.isNotEmpty
                                        ? 'Order #$orderId transferred · To $toName'
                                        : 'Order #$orderId transferred';
                                    return Container(
                                      width: double.infinity,
                                      margin: EdgeInsets.only(
                                        bottom: Dimensions.paddingSizeSmall,
                                      ),
                                      padding: EdgeInsets.all(
                                        Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.orange.shade700
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: rubikMedium.copyWith(
                                          color: Colors.orange.shade900,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  GetBuilder<OrderController>(
                    builder: (orderController) {
                      if (orderController.homeDeliveryTabIndex == 2) {
                        return const SizedBox.shrink();
                      }
                      final showScheduled =
                          orderController.scheduledDeliveryEnabled &&
                              orderController.homeDeliveryTabIndex == 1;
                      final orders = showScheduled
                          ? orderController.scheduledCurrentOrders
                          : orderController.currentOrders;

                      return !orderController.isLoading
                          ? orders.isNotEmpty
                              ? Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        Dimensions.paddingSizeExtraLarge,
                                    vertical: Dimensions.paddingSizeSmall,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: orders.length,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return OnGoingOrderWidget(
                                        orderModel: orders[index],
                                        index: index,
                                      );
                                    },
                                  ),
                                )
                              : const Center(child: NoDataScreenWidget())
                          : const OrderHistoryShimmer();
                    },
                  ),
                  SizedBox(height: Dimensions.paddingSizeDefault),
                  TripStatusWidget(onTap: (int index) => widget.onTap(index)),
                  SizedBox(height: Dimensions.paddingSizeDefault),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkPermission(BuildContext context) {
    final profile = Get.find<ProfileController>().profileModel;
    if (profile?.isOnline == 1) {
      Get.find<ProfileController>().syncOnlineGpsAndLocation(context: context);
    }
  }
}

class _PermissionReminderBanner extends StatelessWidget {
  final PermissionReminderLevel level;
  final VoidCallback onFix;
  final VoidCallback? onDismiss;

  const _PermissionReminderBanner({
    required this.level,
    required this.onFix,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool required = level == PermissionReminderLevel.required;
    final Color bg =
        required ? Colors.red.shade700 : Colors.orange.shade800;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeDefault,
        0,
      ),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'permissions_setup_subtitle'.tr,
                style: rubikRegular.copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
              SizedBox(height: Dimensions.paddingSizeSmall),
              Row(
                children: [
                  TextButton(
                    onPressed: onFix,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                    ),
                    child: Text('permissions_fix_now'.tr),
                  ),
                  if (onDismiss != null) ...[
                    SizedBox(width: Dimensions.paddingSizeSmall),
                    TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: Text('permissions_dismiss'.tr),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Material(
      color: selected ? color : color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: rubikMedium.copyWith(
              color: selected ? Colors.white : color,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ),
      ),
    );
  }
}
