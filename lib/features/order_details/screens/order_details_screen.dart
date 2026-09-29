import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quiksee/data/api/api_client.dart';
import 'package:quiksee/common/basewidgets/quiksee_snackbar_widget.dart';
import 'package:quiksee/features/assignment/controllers/assignment_controller.dart';
import 'package:quiksee/features/dashboard/screens/dashboard_screen.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/distance_payment/widgets/delivery_distance_earning_widget.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/helpers/order_collect_amount_helper.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order/widgets/order_info_widget.dart';
import 'package:quiksee/features/order/widgets/scheduled_delivery_badge_widget.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_details/domain/models/order_details_model.dart';
import 'package:quiksee/features/order_details/screens/order_delivered_screen.dart';
import 'package:quiksee/features/order_details/widgets/camera_or_gallery_widget.dart';
import 'package:quiksee/features/order_details/widgets/change_amount_widget.dart';
import 'package:quiksee/features/order_details/widgets/accept_payment_qr_sheet_widget.dart';
import 'package:quiksee/features/order_details/widgets/delivery_info_widget.dart';
import 'package:quiksee/features/order_details/widgets/order_details_shimmer_widget.dart';
import 'package:quiksee/features/order_details/widgets/payment_info_widget.dart';
import 'package:quiksee/features/order_details/widgets/seller_info_widget.dart';
import 'package:quiksee/features/order_details/widgets/pickup_sequence_widget.dart';
import 'package:quiksee/features/order_details/widgets/food_pickup_otp_card_widget.dart';
import 'package:quiksee/features/order_details/widgets/store_wait_poke_card_widget.dart';
import 'package:quiksee/features/order_details/widgets/verify_otp_sheet_widget.dart';
import 'package:quiksee/features/order_details/widgets/order_details_app_bar_widget.dart';
import 'package:quiksee/features/order_details/widgets/estimated_delivery_card_widget.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/features/splash/domain/models/config_model.dart' as config;
import 'package:quiksee/theme/controllers/theme_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/helper/vendor_ready_popup_helper.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/images.dart';
import 'package:quiksee/utill/styles.dart';
import 'package:quiksee/common/basewidgets/quiksee_button_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_loader_widget.dart';
import 'package:quiksee/common/basewidgets/quiksee_title_widget.dart';
import 'package:get/get.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel? orderModel;
  final bool fromNotification;
  const OrderDetailsScreen({super.key, this.orderModel, required this.fromNotification});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  double? deliveryCharge = 0;
  OrderModel? orderModel;
  OrderDetailsModel? orderDetails;
  double? _editOrderCollectableAmount;
  Timer? _pickupOtpWatchTimer;

  Future<void> _watchPickupOtpUnlock() async {
    if (!mounted || !Get.isRegistered<OrderDetailsController>()) return;
    final id = widget.orderModel?.id ?? orderModel?.id;
    if (id == null) return;
    final ctrl = Get.find<OrderDetailsController>();
    if (ctrl.isPickupOtpUnlocked(id)) return;
    final active = _resolveDisplayOrder(ctrl);
    final waiting = active?.pickupVerificationStatus != 1 &&
        (active?.pickupOtpRequired == 1 ||
            active?.foodPickupOtpEnabled == 1 ||
            (active?.pickupVerificationCode ?? '').isNotEmpty ||
            (Get.isRegistered<SplashController>() &&
                Get.find<SplashController>().configModel?.foodPickupOtp == 1));
    if (!waiting) return;
    final unlocked = await ctrl.refreshPickupOtpStatus(id);
    if (unlocked && mounted) {
      orderModel = _mergeOrderModels(
        ctrl.orderDetails?.isNotEmpty == true
            ? ctrl.orderDetails!.first.orderModel
            : null,
        orderModel ?? widget.orderModel,
      );
      setState(() {});
    }
  }


  Future<void> _loadData({bool silent = false}) async {
    final controller = Get.find<OrderDetailsController>();
    controller.setTotalPrice = 0;

    final targetOrderId = widget.orderModel?.id;
    final sameOrder = controller.hasCachedDetailsForOrder(targetOrderId);
    final primaryLoad = !(silent && sameOrder);

    if (primaryLoad) {
      if (Get.isRegistered<AssignmentController>()) {
        Get.find<AssignmentController>().pauseBackgroundSync();
      }
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().pauseBackgroundOrderPolls();
      }
    }

    List<OrderDetailsModel>? orderDetailsList;
    try {
      orderDetailsList = await controller.getOrderDetails(
        '$targetOrderId',
        context,
        silent: silent && sameOrder,
      );
    } finally {
      if (primaryLoad) {
        if (Get.isRegistered<AssignmentController>()) {
          Get.find<AssignmentController>().resumeBackgroundSync();
        }
        if (Get.isRegistered<OrderController>()) {
          Get.find<OrderController>().resumeBackgroundOrderPolls();
        }
      }
    }
    if (orderDetailsList?.isNotEmpty ?? false) {
      orderModel = _mergeOrderModels(
        orderDetailsList?.first.orderModel,
        orderModel ?? widget.orderModel,
      );
      orderDetails = orderDetailsList?.first;

      if (editOrderPayment()) {
        _editOrderCollectableAmount =
            orderDetails?.latestEditHistory?.orderDueAmount;
      }
    } else {
      orderModel = _resolveFallbackOrder(widget.orderModel?.id) ??
          widget.orderModel;
      orderDetails = null;
    }

    Get.find<OrderDetailsController>().gotoEndOfPageInitialize();
    Get.find<OrderDetailsController>().emptyIdentityImage();

    if (orderModel?.id != null) {
      Get.find<DistancePaymentController>().fetchOrderPayment(orderModel!.id!);
    }

    if (mounted) setState(() {});
  }

  OrderModel? _mergeOrderModels(OrderModel? primary, OrderModel? fallback) {
    if (primary == null) return fallback;
    if (fallback == null) return primary;

    final merged = OrderModel(
      id: primary.id ?? fallback.id,
      customerId: primary.customerId ?? fallback.customerId,
      customerType: primary.customerType ?? fallback.customerType,
      paymentStatus: primary.paymentStatus ?? fallback.paymentStatus,
      orderStatus: _preferAdvancedOrderStatus(
        primary.orderStatus,
        fallback.orderStatus,
      ),
      paymentMethod: primary.paymentMethod ?? fallback.paymentMethod,
      orderAmount: OrderCollectAmountHelper.preferMaxMoney(
            primary.orderAmount, fallback.orderAmount) ??
          0,
      createdAt: primary.createdAt ?? fallback.createdAt,
      updatedAt: primary.updatedAt ?? fallback.updatedAt,
      discountAmount: primary.discountAmount ?? fallback.discountAmount,
      discountType: primary.discountType ?? fallback.discountType,
      couponCode: primary.couponCode ?? fallback.couponCode,
      itemDiscount: OrderCollectAmountHelper.preferPositiveMoney(
          primary.itemDiscount, fallback.itemDiscount),
      couponDiscount: OrderCollectAmountHelper.preferPositiveMoney(
          primary.couponDiscount, fallback.couponDiscount),
      extraDiscount: OrderCollectAmountHelper.preferPositiveMoney(
          primary.extraDiscount, fallback.extraDiscount),
      shippingCost: OrderCollectAmountHelper.preferPositiveMoney(
            primary.shippingCost, fallback.shippingCost) ??
          primary.shippingCost ??
          fallback.shippingCost,
      sellerId: primary.sellerId ?? fallback.sellerId,
      sellerIs: primary.sellerIs ?? fallback.sellerIs,
      customer: primary.customer ?? fallback.customer,
      billingAddress: primary.billingAddress ?? fallback.billingAddress,
      sellerInfo: primary.sellerInfo ?? fallback.sellerInfo,
      expectedDate: primary.expectedDate ?? fallback.expectedDate,
      isPause: primary.isPause ?? fallback.isPause,
      shippingAddress: primary.shippingAddress ?? fallback.shippingAddress,
      isGuest: primary.isGuest ?? fallback.isGuest,
      isShippingFree: primary.isShippingFree ?? fallback.isShippingFree,
      bringChangeAmount: primary.bringChangeAmount ?? fallback.bringChangeAmount,
      bringChangeAmountCurrency:
          primary.bringChangeAmountCurrency ?? fallback.bringChangeAmountCurrency,
      referAndEarnDiscount:
          primary.referAndEarnDiscount ?? fallback.referAndEarnDiscount,
      totalTaxAmount: OrderCollectAmountHelper.preferPositiveMoney(
          primary.totalTaxAmount, fallback.totalTaxAmount),
      taxModel: primary.taxModel ?? fallback.taxModel,
      taxType: primary.taxType ?? fallback.taxType,
      platformFee: OrderCollectAmountHelper.preferPositiveMoney(
          primary.platformFee, fallback.platformFee),
      platformFeeFormatted:
          primary.platformFeeFormatted ?? fallback.platformFeeFormatted,
      platformFeeLabel: primary.platformFeeLabel ?? fallback.platformFeeLabel,
      scheduledDeliveryCharge:
          OrderCollectAmountHelper.preferPositiveMoney(
              primary.scheduledDeliveryCharge, fallback.scheduledDeliveryCharge),
      scheduledDeliveryChargeFormatted:
          primary.scheduledDeliveryChargeFormatted ??
              fallback.scheduledDeliveryChargeFormatted,
      deliveryManTip: OrderCollectAmountHelper.preferPositiveMoney(
          primary.deliveryManTip, fallback.deliveryManTip),
      deliveryManTipFormatted:
          primary.deliveryManTipFormatted ?? fallback.deliveryManTipFormatted,
      extraIncentiveCharge: OrderCollectAmountHelper.preferMaxMoney(
          primary.extraIncentiveCharge, fallback.extraIncentiveCharge),
      extraIncentiveLabel:
          primary.extraIncentiveLabel ?? fallback.extraIncentiveLabel,
      extraIncentiveRiderShare: OrderCollectAmountHelper.preferMaxMoney(
          primary.extraIncentiveRiderShare, fallback.extraIncentiveRiderShare),
      extraIncentiveItems: (primary.extraIncentiveItems != null &&
              primary.extraIncentiveItems!.isNotEmpty)
          ? primary.extraIncentiveItems
          : fallback.extraIncentiveItems,
      manualExtraCharges: (primary.manualExtraCharges != null &&
              primary.manualExtraCharges!.isNotEmpty)
          ? primary.manualExtraCharges
          : fallback.manualExtraCharges,
      deliveryDistanceInfo:
          primary.deliveryDistanceInfo ?? fallback.deliveryDistanceInfo,
      isScheduledDelivery:
          (primary.isScheduledDelivery == 1 || fallback.isScheduledDelivery == 1)
              ? 1
              : (primary.isScheduledDelivery ?? fallback.isScheduledDelivery),
      scheduledDeliveryDate:
          primary.scheduledDeliveryDate ?? fallback.scheduledDeliveryDate,
      scheduledDeliveryTimeFrom: primary.scheduledDeliveryTimeFrom ??
          fallback.scheduledDeliveryTimeFrom,
      scheduledDeliveryTimeTo:
          primary.scheduledDeliveryTimeTo ?? fallback.scheduledDeliveryTimeTo,
      scheduledDelivery:
          primary.scheduledDelivery ?? fallback.scheduledDelivery,
      deliveryType: (primary.deliveryType?.isNotEmpty ?? false)
          ? primary.deliveryType
          : fallback.deliveryType,
    );
    merged.isCombinedCheckout =
        primary.isCombinedCheckout || fallback.isCombinedCheckout;
    merged.combinedLabel = primary.combinedLabel ?? fallback.combinedLabel;
    merged.combinedOrderIds = primary.combinedOrderIds ?? fallback.combinedOrderIds;
    merged.combinedOrderIdsLabel =
        primary.combinedOrderIdsLabel ?? fallback.combinedOrderIdsLabel;
    merged.combinedStoreNames =
        primary.combinedStoreNames ?? fallback.combinedStoreNames;
    merged.combinedTotalEarning =
        primary.combinedTotalEarning ?? fallback.combinedTotalEarning;
    merged.combinedTotalEarningFormatted = primary.combinedTotalEarningFormatted ??
        fallback.combinedTotalEarningFormatted;
    merged.combinedOrders = _preferCombinedOrders(
      primary.combinedOrders,
      fallback.combinedOrders,
    );
    merged.pickupSequence = primary.pickupSequence ?? fallback.pickupSequence;
    merged.pickupLabel = primary.pickupLabel ?? fallback.pickupLabel;
    merged.storeName = primary.storeName ?? fallback.storeName;
    merged.pickupSequenceTotal =
        primary.pickupSequenceTotal ?? fallback.pickupSequenceTotal;
    merged.dropLabel = primary.dropLabel ?? fallback.dropLabel;
    merged.preparationTime = primary.preparationTime ?? fallback.preparationTime;
    merged.estimatedReadyAt =
        primary.estimatedReadyAt ?? fallback.estimatedReadyAt;
    merged.vendorReadyAt = primary.vendorReadyAt ?? fallback.vendorReadyAt;
    merged.etaMinutes = primary.etaMinutes ?? fallback.etaMinutes;
    merged.etaLabel = primary.etaLabel ?? fallback.etaLabel;
    merged.etaBreakdown = primary.etaBreakdown ?? fallback.etaBreakdown;

    final unlocked = primary.pickupVerificationStatus == 1 ||
        fallback.pickupVerificationStatus == 1 ||
        (Get.isRegistered<OrderDetailsController>() &&
            Get.find<OrderDetailsController>()
                .isPickupOtpUnlocked(primary.id ?? fallback.id));
    if (unlocked) {
      merged.foodPickupOtpEnabled =
          primary.foodPickupOtpEnabled ?? fallback.foodPickupOtpEnabled ?? 1;
      merged.pickupVerificationStatus = 1;
      merged.pickupOtpRequired = 0;
      merged.canPickup = 1;
      merged.pickupVerificationCode = null;
      merged.pickupVerifiedAt =
          primary.pickupVerifiedAt ?? fallback.pickupVerifiedAt;
    } else {
      merged.foodPickupOtpEnabled =
          primary.foodPickupOtpEnabled ?? fallback.foodPickupOtpEnabled;
      merged.pickupVerificationStatus =
          primary.pickupVerificationStatus ?? fallback.pickupVerificationStatus;
      merged.pickupOtpRequired =
          primary.pickupOtpRequired ?? fallback.pickupOtpRequired;
      merged.canPickup = primary.canPickup ?? fallback.canPickup;
      merged.pickupVerificationCode =
          primary.pickupVerificationCode ?? fallback.pickupVerificationCode;
      merged.pickupVerifiedAt =
          primary.pickupVerifiedAt ?? fallback.pickupVerifiedAt;
    }

    // Details API sometimes returns store_wait_active=0 while current-orders
    final status = (primary.orderStatus ?? fallback.orderStatus ?? '')
        .toLowerCase()
        .trim();
    final atStoreWait = status == 'reached_restaurant' ||
        status == 'confirmed' ||
        status == 'processing';
    final primaryStarted = (primary.storeWaitStartedAt ?? '').trim().isNotEmpty &&
        primary.storeWaitStartedAt != 'null';
    final fallbackStarted =
        (fallback.storeWaitStartedAt ?? '').trim().isNotEmpty &&
            fallback.storeWaitStartedAt != 'null';
    final preferActive = atStoreWait &&
        (primary.storeWaitActive == 1 ||
            fallback.storeWaitActive == 1 ||
            (status == 'reached_restaurant' &&
                (primaryStarted || fallbackStarted)));

    final primaryInactive = primary.storeWaitActive == 0;
    final fallbackInactive = fallback.storeWaitActive == 0;
    if (!preferActive &&
        (primaryInactive ||
            (primary.storeWaitActive == null && fallbackInactive))) {
      merged.storeWaitActive = 0;
      merged.canPoke = 0;
      merged.storeWaitRemainingSeconds = 0;
      merged.storeWaitDeadlineAt =
          primary.storeWaitDeadlineAt ?? fallback.storeWaitDeadlineAt;
      merged.storeWaitStartedAt =
          primary.storeWaitStartedAt ?? fallback.storeWaitStartedAt;
      merged.storeWaitOverdue =
          primary.storeWaitOverdue ?? fallback.storeWaitOverdue;
      merged.storeWaitOverdueSeconds = primary.storeWaitOverdueSeconds ??
          fallback.storeWaitOverdueSeconds;
      merged.storeWaitShowExtra =
          primary.storeWaitShowExtra ?? fallback.storeWaitShowExtra;
      merged.storeWaitPacked =
          primary.storeWaitPacked ?? fallback.storeWaitPacked;
      merged.storeWaitEnabled =
          primary.storeWaitEnabled ?? fallback.storeWaitEnabled;
      merged.vendorReadyAt = primary.vendorReadyAt ?? fallback.vendorReadyAt;
      merged.pokeCount = primary.pokeCount ?? fallback.pokeCount;
      merged.pokeMax = primary.pokeMax ?? fallback.pokeMax;
      merged.nextPokeAt = primary.nextPokeAt ?? fallback.nextPokeAt;
      merged.storeLastPokeAt =
          primary.storeLastPokeAt ?? fallback.storeLastPokeAt;
    } else {
      merged.storeWaitEnabled =
          primary.storeWaitEnabled ?? fallback.storeWaitEnabled;
      merged.storeWaitActive = primary.storeWaitActive == 1 ||
              fallback.storeWaitActive == 1
          ? 1
          : (primary.storeWaitActive ?? fallback.storeWaitActive);
      if (merged.storeWaitActive != 1 &&
          status == 'reached_restaurant' &&
          (primaryStarted || fallbackStarted)) {
        merged.storeWaitActive = 1;
      }
      merged.storeWaitStartedAt =
          primary.storeWaitStartedAt ?? fallback.storeWaitStartedAt;
      merged.storeWaitDeadlineAt =
          primary.storeWaitDeadlineAt ?? fallback.storeWaitDeadlineAt;
      merged.storeWaitRemainingSeconds = primary.storeWaitRemainingSeconds ??
          fallback.storeWaitRemainingSeconds;
      merged.storeWaitOverdue =
          primary.storeWaitOverdue ?? fallback.storeWaitOverdue;
      merged.storeWaitOverdueSeconds = primary.storeWaitOverdueSeconds ??
          fallback.storeWaitOverdueSeconds;
      merged.storeWaitShowExtra =
          primary.storeWaitShowExtra ?? fallback.storeWaitShowExtra;
      merged.storeWaitPacked =
          primary.storeWaitPacked ?? fallback.storeWaitPacked;
      merged.vendorReadyAt = primary.vendorReadyAt ?? fallback.vendorReadyAt;
      merged.canPoke = primary.canPoke ?? fallback.canPoke;
      merged.pokeCount = primary.pokeCount ?? fallback.pokeCount;
      merged.pokeMax = primary.pokeMax ?? fallback.pokeMax;
      merged.nextPokeAt = primary.nextPokeAt ?? fallback.nextPokeAt;
      merged.storeLastPokeAt =
          primary.storeLastPokeAt ?? fallback.storeLastPokeAt;
    }

    // Order transfer meta from store-wait / status API must survive details merge.
    merged.orderTransferEnabled =
        (primary.orderTransferEnabled ?? 0) == 1 ||
                (fallback.orderTransferEnabled ?? 0) == 1
            ? 1
            : (primary.orderTransferEnabled ?? fallback.orderTransferEnabled);
    merged.orderTransferAlreadyDone =
        (primary.orderTransferAlreadyDone ?? 0) == 1 ||
                (fallback.orderTransferAlreadyDone ?? 0) == 1
            ? 1
            : (primary.orderTransferAlreadyDone ??
                fallback.orderTransferAlreadyDone);
    merged.orderTransferLocked =
        (primary.orderTransferLocked ?? 0) == 1 ||
                (fallback.orderTransferLocked ?? 0) == 1
            ? 1
            : (primary.orderTransferLocked ?? fallback.orderTransferLocked);
    merged.orderTransferUnlockMode =
        primary.orderTransferUnlockMode ?? fallback.orderTransferUnlockMode;
    merged.orderTransferAfterReachSeconds =
        primary.orderTransferAfterReachSeconds ??
            fallback.orderTransferAfterReachSeconds;
    merged.orderTransferOnlyAfterPrepOverdue =
        primary.orderTransferOnlyAfterPrepOverdue ??
            fallback.orderTransferOnlyAfterPrepOverdue;
    merged.orderTransferOnlyAfterReachStore =
        primary.orderTransferOnlyAfterReachStore ??
            fallback.orderTransferOnlyAfterReachStore;
    merged.orderTransferBlockAfterPackaging =
        primary.orderTransferBlockAfterPackaging ??
            fallback.orderTransferBlockAfterPackaging;
    merged.orderTransferBlockAfterPickup =
        primary.orderTransferBlockAfterPickup ??
            fallback.orderTransferBlockAfterPickup;
    merged.orderTransferBlockOutForDelivery =
        primary.orderTransferBlockOutForDelivery ??
            fallback.orderTransferBlockOutForDelivery;
    merged.orderTransferReceived =
        primary.orderTransferReceived ?? fallback.orderTransferReceived;
    merged.orderTransferFromId =
        primary.orderTransferFromId ?? fallback.orderTransferFromId;
    merged.orderTransferFromName =
        primary.orderTransferFromName ?? fallback.orderTransferFromName;
    merged.orderTransferToId =
        primary.orderTransferToId ?? fallback.orderTransferToId;
    merged.orderTransferToName =
        primary.orderTransferToName ?? fallback.orderTransferToName;
    merged.orderTransferAt =
        primary.orderTransferAt ?? fallback.orderTransferAt;

    return merged;
  }

  /// Empty `combined_orders: []` from details must not wipe a rich list/cache list.
  static List<OrderModel>? _preferCombinedOrders(
    List<OrderModel>? primary,
    List<OrderModel>? fallback,
  ) {
    if (primary != null && primary.length >= 2) return primary;
    if (fallback != null && fallback.length >= 2) return fallback;
    if (primary != null && primary.isNotEmpty) return primary;
    return fallback ?? primary;
  }

  OrderModel? _resolveDisplayOrder(OrderDetailsController controller) {
    final fromDetails = controller.orderDetails?.isNotEmpty == true
        ? controller.orderDetails!.first.orderModel
        : null;
    final cached = orderModel ?? widget.orderModel;
    var resolved = _mergeOrderModels(fromDetails, cached);

    if (resolved?.orderStatus == null) {
      final orderId = resolved?.id ?? widget.orderModel?.id;
      resolved = _mergeOrderModels(resolved, _resolveFallbackOrder(orderId));
    }

    // Live lists often advance sooner than lean order-details (incl. scheduled).
    final orderId = resolved?.id ?? widget.orderModel?.id;
    if (orderId != null && Get.isRegistered<OrderController>()) {
      final orderCtrl = Get.find<OrderController>();
      final live = [
        ...orderCtrl.currentOrders,
        ...orderCtrl.scheduledCurrentOrders,
      ];
      var matched = false;
      for (final order in live) {
        if (order.id == orderId) {
          resolved = _mergeOrderModels(resolved, order);
          matched = true;
          break;
        }
        for (final child in order.combinedOrders ?? const <OrderModel>[]) {
          if (child.id == orderId) {
            resolved = _mergeOrderModels(resolved, child);
            matched = true;
            break;
          }
        }
        if (matched) break;
      }
    }
    return resolved;
  }

  static String? _preferAdvancedOrderStatus(String? a, String? b) {
    if ((a ?? '').trim().isEmpty) return b;
    if ((b ?? '').trim().isEmpty) return a;
    // Canceled / delivered / returned / failed must not be outranked by stale OFD.
    if (OrderStatusHelper.isTerminalStatus(a)) return a;
    if (OrderStatusHelper.isTerminalStatus(b)) return b;
    return OrderStatusHelper.statusProgressRank(b) >
            OrderStatusHelper.statusProgressRank(a)
        ? b
        : a;
  }

  OrderModel? _resolveFallbackOrder(int? orderId) {
    if (orderId == null) return widget.orderModel;

    if (widget.orderModel?.orderStatus != null) {
      return widget.orderModel;
    }

    if (Get.isRegistered<OrderController>()) {
      final orderController = Get.find<OrderController>();
      for (final order in [
        ...orderController.currentOrders,
        ...orderController.scheduledCurrentOrders,
      ]) {
        if (order.id == orderId) return order;
      }
      for (final list in [
        orderController.allOrderHistory,
        orderController.deliveredOrderHistory,
        orderController.currentHistoryOrders,
      ]) {
        for (final order in list ?? const <OrderModel>[]) {
          if (order.id == orderId) return order;
        }
      }
    }

    if (Get.isRegistered<AssignmentController>()) {
      final assignment = Get.find<AssignmentController>();
      for (final offer in [
        ...assignment.pendingOffers,
        ...assignment.scheduledPendingOffers,
      ]) {
        if (offer.orderId == orderId) {
          return OrderModel(
            id: orderId,
            orderStatus: offer.orderStatus,
            orderAmount: offer.orderAmount,
            paymentStatus: offer.paymentStatus,
            deliveryDistanceInfo: offer.deliveryDistanceInfo,
          );
        }
      }
    }

    return widget.orderModel;
  }

  Widget _buildUnavailableState(BuildContext context, int? orderId) {
    final fallback = widget.orderModel ?? orderModel;
    final isHistoryView = fallback?.orderStatus != null &&
        OrderStatusHelper.isTerminalStatus(fallback!.orderStatus);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).hintColor,
            ),
            SizedBox(height: Dimensions.paddingSizeLarge),
            if (orderId != null)
              Text(
                '${'order'.tr} #$orderId',
                style: rubikMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              isHistoryView
                  ? ApiClient.timeoutMessage
                  : 'order_details_not_available'.tr,
              textAlign: TextAlign.center,
              style: rubikRegular.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            if (!isHistoryView) ...[
              SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'order_details_accept_first'.tr,
                textAlign: TextAlign.center,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
            SizedBox(height: Dimensions.paddingSizeLarge),
            QuikseeButtonWidget(
              btnTxt: 'retry'.tr,
              onTap: _loadData,
            ),
            SizedBox(height: Dimensions.paddingSizeSmall),
            if (widget.fromNotification)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const DashboardScreen(pageIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                child: Text('home'.tr),
              ),
          ],
        ),
      ),
    );
  }


  @override
  void initState() {
    orderModel = widget.orderModel;
    super.initState();
    if (Get.isRegistered<OrderDetailsController>()) {
      Get.find<OrderDetailsController>()
          .prepareForOrderScreen(widget.orderModel?.id);
    }
    // it throws setState-during-build and aborts the fetch (skeleton forever).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasCache = Get.isRegistered<OrderDetailsController>() &&
          Get.find<OrderDetailsController>()
              .hasCachedDetailsForOrder(widget.orderModel?.id);
      unawaited(_loadData(silent: hasCache));
      unawaited(_watchPickupOtpUnlock());
    });
    _startVendorReadyWatch();
    _pickupOtpWatchTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_watchPickupOtpUnlock());
    });
  }

  Timer? _vendorReadyWatchTimer;

  void _startVendorReadyWatch() {
    _vendorReadyWatchTimer?.cancel();
    _vendorReadyWatchTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final orderId = orderModel?.id ?? widget.orderModel?.id;
      if (orderId == null || orderId <= 0) return;

      final detailsCtrl = Get.find<OrderDetailsController>();
      if (!detailsCtrl.detailsFetchComplete) return;

      final status = (orderModel?.orderStatus ??
              widget.orderModel?.orderStatus ??
              '')
          .toLowerCase();
      final ready = orderModel?.vendorReadyAt?.trim() ?? '';
      final waiting = status == 'reached_restaurant' ||
          status == 'confirmed' ||
          status == 'processing';
      if (!waiting || (ready.isNotEmpty && ready != 'null')) {
        if (ready.isNotEmpty && ready != 'null') {
          unawaited(VendorReadyPopupHelper.maybeShowFromOrder(orderModel));
          _vendorReadyWatchTimer?.cancel();
          _vendorReadyWatchTimer = null;
        }
        return;
      }

      try {
        final details = await detailsCtrl.getOrderDetails(
          orderId.toString(),
          context,
          silent: true,
        );
        if (!mounted) return;
        final refreshed = details?.isNotEmpty == true
            ? details!.first.orderModel
            : null;
        if (refreshed != null) {
          orderModel = _mergeOrderModels(refreshed, orderModel);
          unawaited(VendorReadyPopupHelper.maybeShowFromOrder(orderModel));
          final newReady = orderModel?.vendorReadyAt?.trim() ?? '';
          if (newReady.isNotEmpty && newReady != 'null') {
            _vendorReadyWatchTimer?.cancel();
            _vendorReadyWatchTimer = null;
            if (mounted) setState(() {});
          }
        }
      } catch (_) {}
    });
  }

  final ScrollController _controller = ScrollController();

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(_controller.hasClients){
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(seconds: 2),
          curve: Curves.fastOutSlowIn,
        ).then((_){
          Get.find<OrderDetailsController>().setGotoEndOfPage();
        });
      }
    });
  }


  @override
  void dispose() {
    _pickupOtpWatchTimer?.cancel();
    _pickupOtpWatchTimer = null;
    _vendorReadyWatchTimer?.cancel();
    _vendorReadyWatchTimer = null;
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async{
        if(widget.fromNotification) {
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => const DashboardScreen(pageIndex: 0)), (route) => false);
        } else {
          return;
        }
      },

      child: GetBuilder<OrderDetailsController>(
        builder: (loadingController) {
          return Stack(
            children: [
              Scaffold(
        backgroundColor: Get.isDarkMode
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFF5F7F6),
        appBar: OrderDetailsAppBarWidget(
          orderId: widget.orderModel?.id ?? orderModel?.id,
          onBack: () {
            if(widget.fromNotification) {
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (BuildContext context) => const DashboardScreen(pageIndex: 0)), (route) => false);
            } else {
              Future.microtask(() {
                Get.back();
              });
            }
          },
        ),

        body: RefreshIndicator(
          onRefresh: () async {
            await _loadData(
              silent: Get.find<OrderDetailsController>()
                  .hasCachedDetailsForOrder(widget.orderModel?.id),
            );
          },
          child: GetBuilder<OrderController>(
            builder: (orderController) {
              return GetBuilder<DistancePaymentController>(
                builder: (distancePaymentController) {
              return GetBuilder<OrderDetailsController>(
                builder: (orderDetailsController) {
                  final OrderModel? displayOrder =
                      _resolveDisplayOrder(orderDetailsController);
                  if(orderDetailsController.endOfPage && !orderDetailsController.endOfPageScrolled) {
                    _scrollDown();
                  }
                  double _itemsPrice = 0;
                  double _discount = 0;
                  double _tax = 0;
                  double _subTotal = 0;
                  double _referAndEarnDiscount = 0;
                  double _couponDiscount = 0;
                  double _extraDiscount = 0;
                  double _total = 0;
                  double _tipAmount = 0;
                  double _platformFeeAmount = 0;
                  double _scheduledFeeAmount = 0;
                  double _extraIncentiveFee = 0;
                  double _manualExtraChargesTotal = 0;
                  List<Map<String, dynamic>> _manualExtraCharges =
                      const <Map<String, dynamic>>[];

                  if(displayOrder?.orderStatus != null){
                    final distanceInfo = distancePaymentController
                            .orderPaymentFor(displayOrder?.id) ??
                        displayOrder?.deliveryDistanceInfo;
                    deliveryCharge = OrderCollectAmountHelper.customerShippingOf(
                      displayOrder,
                      distanceInfo,
                    );

                    if (orderDetailsController.orderDetails?.isNotEmpty == true) {
                      _tax = OrderCollectAmountHelper.displayTaxAmount(
                        displayOrder,
                        orderDetailsController.orderDetails,
                      );
                      for (final line in orderDetailsController.orderDetails!) {
                        _itemsPrice += (line.price ?? 0) * (line.qty ?? 0);
                      }
                      _discount = OrderCollectAmountHelper.itemDiscountOf(
                        displayOrder,
                        orderDetailsController.orderDetails,
                      );
                      _couponDiscount =
                          OrderCollectAmountHelper.couponDiscountOf(displayOrder);
                      _extraDiscount =
                          OrderCollectAmountHelper.extraDiscountOf(displayOrder);
                      _referAndEarnDiscount =
                          OrderCollectAmountHelper.referDiscountOf(
                        displayOrder,
                        orderDetailsController.orderDetails,
                      );
                    }

                    _subTotal = _itemsPrice +
                        _tax -
                        _discount -
                        _couponDiscount -
                        _extraDiscount -
                        _referAndEarnDiscount;

                    _tipAmount = OrderCollectAmountHelper.tipOf(
                      displayOrder,
                      distanceInfo,
                    );
                    _platformFeeAmount =
                        OrderCollectAmountHelper.platformFeeOf(displayOrder);
                    _scheduledFeeAmount =
                        OrderCollectAmountHelper.scheduledDeliveryFeeOf(
                      displayOrder,
                    );
                    _extraIncentiveFee =
                        OrderCollectAmountHelper.extraIncentiveFeeOf(
                      displayOrder,
                    );
                    _manualExtraCharges =
                        OrderCollectAmountHelper.manualExtraChargesOf(
                      displayOrder,
                    );
                    _manualExtraChargesTotal =
                        OrderCollectAmountHelper.manualExtraChargesTotalOf(
                      displayOrder,
                    );

                    // Total = Payment Info rows, but never below server order_amount
                    // (dynamic latefee/rain charges live on server total).
                    final rowsTotal = OrderCollectAmountHelper.fromDisplayedRows(
                      itemsPrice: _itemsPrice,
                      discount: _discount,
                      tax: _tax,
                      deliveryCharge: deliveryCharge ?? 0,
                      referAndEarnDiscount: _referAndEarnDiscount,
                      couponDiscount: _couponDiscount,
                      extraDiscount: _extraDiscount,
                      platformFee: _platformFeeAmount,
                      tip: _tipAmount,
                      scheduledDeliveryFee: _scheduledFeeAmount,
                      extraIncentiveFee: _extraIncentiveFee,
                      manualExtraChargesTotal: _manualExtraChargesTotal,
                    );
                    final serverTotal =
                        OrderCollectAmountHelper.serverCollectAmount(displayOrder);
                    final collectAmount = editOrderPayment()
                        ? OrderCollectAmountHelper.resolve(
                            order: displayOrder,
                            lineItems: orderDetailsController.orderDetails,
                            distanceInfo: distanceInfo,
                            editDueAmount: _editOrderCollectableAmount ?? 0,
                            currentOrders: orderController.currentOrders,
                          )
                        : (() {
                            if (serverTotal > 0 && rowsTotal > 0) {
                              return serverTotal >= rowsTotal - 0.009
                                  ? serverTotal
                                  : rowsTotal;
                            }
                            if (rowsTotal > 0) return rowsTotal;
                            if (serverTotal > 0) return serverTotal;
                            return OrderCollectAmountHelper.resolve(
                              order: displayOrder,
                              lineItems: orderDetailsController.orderDetails,
                              distanceInfo: distanceInfo,
                              currentOrders: orderController.currentOrders,
                            );
                          })();
                    orderDetailsController.setTotalPrice = collectAmount;

                    _total = collectAmount;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      orderDetailsController.syncCollectAmount(
                        order: displayOrder,
                        editDueAmount: editOrderPayment()
                            ? (_editOrderCollectableAmount ?? 0)
                            : null,
                        distanceInfo: distanceInfo,
                      );
                    });

                  }

                  final hasLineItems =
                      orderDetailsController.orderDetails?.isNotEmpty == true;
                  final fetchComplete =
                      orderDetailsController.detailsFetchComplete;
                  final hasListSummary = displayOrder?.orderStatus != null &&
                      widget.orderModel?.id == displayOrder?.id &&
                      widget.orderModel?.orderStatus != null;

                  if (!fetchComplete) {
                    return const OrderDetailsShimmer();
                  }

                  if (!hasLineItems && !hasListSummary) {
                    return _buildUnavailableState(
                      context,
                      widget.orderModel?.id ?? orderModel?.id,
                    );
                  }

                  if (displayOrder?.orderStatus == null) {
                    return _buildUnavailableState(
                      context,
                      widget.orderModel?.id ?? orderModel?.id,
                    );
                  }

                  return Column(children: [
                    if (!hasLineItems)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          Dimensions.paddingSizeSmall,
                          Dimensions.paddingSizeSmall,
                          Dimensions.paddingSizeSmall,
                          0,
                        ),
                        child: Material(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            Dimensions.paddingSizeExtraSmall,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_off_outlined,
                                  size: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: Dimensions.paddingSizeSmall),
                                Expanded(
                                  child: Text(
                                    ApiClient.timeoutMessage,
                                    style: rubikRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(child: ListView(
                      controller: _controller,
                      physics: const BouncingScrollPhysics(),
                      padding:  EdgeInsets.all(Dimensions.paddingSizeSmall), children: [

                      OrderStatusHelper.showsDeliveryActionBar(displayOrder?.orderStatus)
                      ? DeliveryInfoWidget(orderModel: displayOrder)
                      : const SizedBox(),

                      if (displayOrder != null)
                        FoodPickupOtpCardWidget(
                          orderModel: displayOrder,
                        ),

                      if (displayOrder != null)
                        StoreWaitPokeCardWidget(orderModel: displayOrder),

                      if (displayOrder?.scheduledDeliveryDisplayLabel != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                          child: ScheduledDeliveryBadgeWidget(
                            order: displayOrder!,
                            compact: false,
                          ),
                        ),

                      if (displayOrder != null)
                        EstimatedDeliveryCardWidget(orderModel: displayOrder),

                      displayOrder != null && (
                      displayOrder.sellerInfo != null ||
                      displayOrder.sellerIs == 'admin' ||
                      OrderStatusHelper.isStoreNavigationStatus(displayOrder.orderStatus))
                      ? SellerInfoWidget(orderModel: displayOrder) : const SizedBox(),
                      SizedBox(height: Dimensions.paddingSizeSmall),

                      if (displayOrder != null)
                        PickupSequenceWidget(orderModel: displayOrder),

                      OrderInfoWidget(orderModel: displayOrder, orderController: orderDetailsController,fromDetails: true),

                      Padding(padding:  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                        child: DeliveryInfoWidget(orderModel: displayOrder)),

                      PaymentInfoWidget(
                        paymentStatus: (orderModel?.paymentStatus == 'paid' && (orderDetails?.latestEditHistory?.orderDueAmount == null || orderDetails?.latestEditHistory?.orderDueAmount == 0) ) ? 'paid' :
                        ((orderDetails?.latestEditHistory?.orderDueAmount ?? 0) >= 0 &&  orderDetails?.latestEditHistory?.orderDuePaymentStatus == 'paid') ? 'paid'
                          : (orderModel?.paymentStatus == 'paid' && (orderDetails?.latestEditHistory?.orderDueAmount ?? 0) > 0) ? 'partially_paid' : 'unpaid',
                        itemsPrice: _itemsPrice,
                        tax: _tax,
                        subTotal: _subTotal,
                        discount: _discount,
                        couponDiscount: _couponDiscount,
                        extraDiscount: _extraDiscount,
                        referAndEarnDiscount: _referAndEarnDiscount,
                        deliveryCharge: deliveryCharge,
                        platformFee: _platformFeeAmount,
                        platformFeeLabel: displayOrder?.platformFeeLabel,
                        tip: _tipAmount,
                        scheduledDeliveryFee: _scheduledFeeAmount,
                        extraIncentiveFee: _extraIncentiveFee,
                        extraIncentiveLabel: displayOrder?.extraIncentiveLabel,
                        extraIncentiveItems: displayOrder?.extraIncentiveItems,
                        manualExtraCharges: _manualExtraCharges,
                        totalPrice: _total,
                        paidAmount: editOrderPayment() ? (_total - (_editOrderCollectableAmount ?? 0)) : 0,
                        dueAmount: editOrderPayment() ? (_editOrderCollectableAmount ?? 0) : 0,
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: ChangeAmountWidget(
                          changeAmount: orderModel?.bringChangeAmount ?? 0,
                          currency: orderModel?.bringChangeAmountCurrency ?? '',
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                        child: GetBuilder<DistancePaymentController>(
                          builder: (distanceController) {
                            if (distanceController.isLoadingOrderPayment(orderModel?.id)) {
                              return Padding(
                                padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                                child: Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return DeliveryDistanceEarningWidget(order: orderModel);
                          },
                        ),
                      ),


                      SizedBox(height: Dimensions.paddingSizeSmall),
                      if((displayOrder?.orderStatus ?? orderModel?.orderStatus) == 'out_for_delivery' && Get.find<SplashController>().configModel?.imageUpload == 1)
                        Container(decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Get.find<ThemeController>().darkTheme ? Colors.black.withValues(alpha:0.10) : Colors.grey[100]!,
                              blurRadius: 5, spreadRadius: 1
                            )
                          ],
                          color: Theme.of(context).cardColor),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const QuikseeTitleWidget(title: 'completed_service_picture',),
                              Padding(padding:  EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
                                Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                                child: GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,crossAxisSpacing: 10, mainAxisSpacing: 10),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount : orderDetailsController.identityImages.length + 1 ,
                                  itemBuilder: (BuildContext context, index){
                                    return index ==  orderDetailsController.identityImages.length ?
                                    InkWell(onTap: (){
                                      showModalBottomSheet<void>(
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                            child: CameraOrGalleryWidget(orderModel: orderModel, totalPrice: orderDetailsController.totalPrice),
                                          );
                                        },
                                      );
                                    }, child: Container(decoration: BoxDecoration(
                                        color: Get.isDarkMode ? Theme.of(context).cardColor : Theme.of(context).primaryColor.withValues(alpha:.125),
                                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
                                        child: Stack(children: [
                                          Center(child: ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                              child: SizedBox(width: 40, height: 40, child: Image.asset(Images.camera))))]))) :


                                    Stack(children: [
                                      Padding(padding: EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                          child: Container(decoration:  BoxDecoration(color: Theme.of(context).cardColor,
                                            borderRadius: const BorderRadius.all(Radius.circular(20)),),
                                              child: ClipRRect(borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeExtraSmall)),
                                                  child:  Image.file(File(orderDetailsController.identityImages[index].path),
                                                      height: 400,width: 400, fit: BoxFit.cover)))),


                                      Positioned(top:0,right:0,
                                          child: InkWell(onTap :() => orderDetailsController.removeImage(index),
                                              child: Container(decoration: BoxDecoration(color: Colors.white,
                                                  borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault))),
                                                  child: const Padding(padding: EdgeInsets.all(4.0),
                                                      child: Center(child: Icon(Icons.delete_forever_rounded,color: Colors.red,size: 15))))))]);
                                  })
                              ),
                            ],
                          ),
                        ),

                    ])),


                  ]);
                },
              );
            },
          );
        },
      ),
    ),


        bottomNavigationBar: GetBuilder<OrderController>(
          builder: (orderController) {
            return GetBuilder<DistancePaymentController>(
              builder: (_) {
            return GetBuilder<OrderDetailsController>(
              builder: (orderDetailsController) {
                final OrderModel? displayOrder =
                    _resolveDisplayOrder(orderDetailsController);
                final splashController = Get.find<SplashController>();
                final config = splashController.configModel;

                final isEndOfPage = orderDetailsController.endOfPage;
                final imageUploadOff = config?.imageUpload == 0;
                final hasNoVerificationAndNoUpload = config?.orderVerification == 0 && config?.imageUpload == 0;
                final atCustomerDeliveryStage =
                    OrderStatusHelper.canDeliver(displayOrder?.orderStatus);

                final hasLineItems =
                    orderDetailsController.orderDetails?.isNotEmpty == true;

                final tallCollect = showCollectAmount() &&
                    !OrderStatusHelper.canPickUp(
                      displayOrder?.orderStatus,
                      alreadyReached: orderDetailsController
                          .hasReachedRestaurant(displayOrder?.id),
                      storeWaitStartedAt: displayOrder?.storeWaitStartedAt,
                      pickupVerificationStatus:
                          displayOrder?.pickupVerificationStatus,
                      orderTransferReceived: displayOrder?.orderTransferReceived,
                    ) &&
                    !OrderStatusHelper.canReachRestaurant(
                      displayOrder?.orderStatus,
                      alreadyReached: orderDetailsController
                          .hasReachedRestaurant(displayOrder?.id),
                      storeWaitStartedAt: displayOrder?.storeWaitStartedAt,
                      pickupVerificationStatus:
                          displayOrder?.pickupVerificationStatus,
                      orderTransferReceived: displayOrder?.orderTransferReceived,
                    );
                // or out_for_delivery (map keeps swipe there; details must match).
                final showProceedBar = atCustomerDeliveryStage &&
                    (isEndOfPage ||
                        (imageUploadOff && !hasNoVerificationAndNoUpload));
                final showsActionBar =
                    OrderStatusHelper.showsDeliveryActionBar(
                          displayOrder?.orderStatus,
                        ) &&
                        displayOrder?.isPause != true;

                if (!hasLineItems ||
                    displayOrder?.orderStatus == null ||
                    !showsActionBar) {
                  return const SizedBox.shrink();
                }

                Widget wrapBottomBar(Widget child) {
                  return Material(
                    color: Theme.of(context).cardColor,
                    elevation: 8,
                    child: SafeArea(
                      top: false,
                      child: child,
                    ),
                  );
                }

                // Proceed/upload path needs a fixed height (uses Expanded).
                if (showProceedBar) {
                  return wrapBottomBar(
                    SizedBox(
                    height: tallCollect ? 180 : 70,
                    child: Padding(
                      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: orderDetailsController.uploading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                if (showCollectAmount()) ...[
                                  if (displayOrder != null)
                                    Builder(
                                      builder: (_) {
                                        _schedulePrefetchAcceptPaymentQr(
                                            displayOrder);
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  GetBuilder<OrderController>(
                                    builder: (orderController) {
                                      return GetBuilder<
                                          DistancePaymentController>(
                                        builder: (_) {
                                          return GetBuilder<
                                              OrderDetailsController>(
                                            builder: (orderDetailsController) {
                                              final distanceInfo = Get
                                                      .isRegistered<
                                                          DistancePaymentController>()
                                                  ? Get.find<
                                                          DistancePaymentController>()
                                                      .orderPaymentFor(
                                                          displayOrder?.id)
                                                  : null;
                                              return Padding(
                                                padding: EdgeInsetsGeometry
                                                    .symmetric(horizontal: 0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'amount_to_collect_from'
                                                          .tr,
                                                      style: rubikRegular
                                                          .copyWith(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                    ),
                                                    Text(
                                                      PriceConverter
                                                          .convertPrice(
                                                        OrderCollectAmountHelper
                                                            .resolve(
                                                          order: displayOrder,
                                                          lineItems:
                                                              orderDetailsController
                                                                  .orderDetails,
                                                          distanceInfo: distanceInfo ??
                                                              displayOrder
                                                                  ?.deliveryDistanceInfo,
                                                          editDueAmount:
                                                              editOrderPayment()
                                                                  ? (_editOrderCollectableAmount ??
                                                                      0)
                                                                  : null,
                                                          currentOrders:
                                                              orderController
                                                                  .currentOrders,
                                                        ),
                                                      ),
                                                      style: rubikMedium
                                                          .copyWith(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  SizedBox(
                                      height:
                                          Dimensions.paddingSizeExtraSmall),
                                  QuikseeButtonWidget(
                                    btnTxt: 'accept_payment'.tr,
                                    isShowBorder: true,
                                    onTap: () {
                                      AcceptPaymentQrSheetWidget.show(
                                        context,
                                        amount: _resolvedCollectAmount(
                                            displayOrder!),
                                        orderId: displayOrder.id,
                                      );
                                    },
                                  ),
                                  SizedBox(
                                      height:
                                          Dimensions.paddingSizeExtraSmall),
                                ],
                                Expanded(
                                  child: QuikseeButtonWidget(
                                    btnTxt: _isPaymentConfirmedForDelivery(
                                            displayOrder!)
                                        ? 'proceed_next'.tr
                                        : 'after_payment_swipe_to_deliver'.tr,
                                    onTap: () {
                                      final splashController =
                                          Get.find<SplashController>();
                                      final config =
                                          splashController.configModel;
                                      if (!_isPaymentConfirmedForDelivery(
                                          displayOrder)) {
                                        showQuikseeSnackBarWidget(
                                          'after_payment_swipe_to_deliver'.tr,
                                        );
                                        return;
                                      }
                                      if (config?.imageUpload == 1) {
                                        _handleImageUploadFlow(
                                          context,
                                          orderDetailsController,
                                          displayOrder,
                                        );
                                      } else {
                                        _handleNonImageUploadFlow(
                                          context,
                                          orderDetailsController,
                                          displayOrder,
                                          config,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  );
                }

                return wrapBottomBar(const SizedBox.shrink());
              }
            );
              }
            );
          }
        ),

              ),
              if (loadingController.isLoading)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(child: QuikseeLoaderWidget()),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool showCollectAmount() {
    final orderId = orderModel?.id ?? orderDetails?.orderId;
    if (Get.isRegistered<OrderDetailsController>() &&
        Get.find<OrderDetailsController>().isCodPaymentCollected(orderId)) {
      return false;
    }
    return editOrderPayment() ||
        (orderDetails?.latestEditHistory?.orderDuePaymentStatus != 'paid' &&
            orderDetails?.latestEditHistory?.orderDuePaymentMethod ==
                'cash_on_delivery') ||
        (orderModel?.paymentStatus != 'paid' &&
            orderModel?.paymentMethod == 'cash_on_delivery');
  }

  void _handleImageUploadFlow(BuildContext context, OrderDetailsController orderDetailsController, OrderModel? orderModel) {
    if (orderDetailsController.identityImages.isEmpty) {
      showQuikseeSnackBarWidget('please_select_an_image'.tr, isError: true);
    } else {
      orderDetailsController.uploadOrderVerificationImage(orderModel!.id.toString()).then((value) {
        if(value.statusCode == 200) {
          _handlePostUploadFlow(Get.context!, orderDetailsController, orderModel);
        }
      });
    }
  }

  void _handlePostUploadFlow(BuildContext context, OrderDetailsController orderDetailsController, OrderModel orderModel) {
    final splashController = Get.find<SplashController>();

    if (!_isPaymentConfirmedForDelivery(orderModel)) {
      showQuikseeSnackBarWidget('after_payment_swipe_to_deliver'.tr);
      return;
    }
    if (splashController.configModel?.orderVerification == 1) {
      _showVerificationBottomSheet(context, orderModel, _resolvedCollectAmount(orderModel));
    } else {
      _completeDelivery(context, orderDetailsController, orderModel);
    }
  }

  void _handleNonImageUploadFlow(BuildContext context, OrderDetailsController orderDetailsController, OrderModel? orderModel, config.ConfigModel? config) {
    final splashController = Get.find<SplashController>();
    if (orderModel == null) return;
    if (!_isPaymentConfirmedForDelivery(orderModel)) {
      showQuikseeSnackBarWidget('after_payment_swipe_to_deliver'.tr);
      return;
    }
    if (splashController.configModel?.orderVerification == 1) {
      _showVerificationBottomSheet(context, orderModel, _resolvedCollectAmount(orderModel));
    } else {
      _completeDelivery(context, orderDetailsController, orderModel);
    }
  }

  void _schedulePrefetchAcceptPaymentQr(OrderModel order) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AcceptPaymentQrSheetWidget.prefetch(
        orderId: order.id,
        amount: _resolvedCollectAmount(order),
      );
    });
  }

  double _resolvedCollectAmount(OrderModel order) {
    final details = Get.find<OrderDetailsController>();
    final distanceInfo = Get.isRegistered<DistancePaymentController>()
        ? Get.find<DistancePaymentController>().orderPaymentFor(order.id)
        : null;
    return OrderCollectAmountHelper.resolve(
      order: order,
      lineItems: details.orderDetails,
      distanceInfo: distanceInfo ?? order.deliveryDistanceInfo,
      editDueAmount: editOrderPayment() ? (_editOrderCollectableAmount ?? 0) : null,
      currentOrders: Get.isRegistered<OrderController>()
          ? Get.find<OrderController>().currentOrders
          : null,
    );
  }

  bool _isPaymentConfirmedForDelivery(OrderModel orderModel) {
    return Get.find<OrderDetailsController>().isDeliveryPaymentConfirmed(
      orderModel,
      editOrderPaymentDue: editOrderPayment(),
    );
  }

  bool editOrderPayment() => ((orderDetails?.latestEditHistory?.orderDueAmount ?? 0) > 0 && (orderDetails?.latestEditHistory?.orderDuePaymentStatus == 'unpaid' && orderDetails?.latestEditHistory?.orderDuePaymentMethod == 'cash_on_delivery')) ;

  void _showVerificationBottomSheet(BuildContext context, OrderModel orderModel, double totalPrice) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: VerifyDeliverySheetWidget(
            orderModel: orderModel,
            totalPrice: totalPrice,
            editOrderPayment: editOrderPayment(),
          ),
        );
      },
    );
  }

  Future<void> _completeDelivery(
    BuildContext context,
    OrderDetailsController orderDetailsController,
    OrderModel orderModel,
  ) async {
    bool success = false;
    try {
      success = await orderDetailsController
          .updateOrderStatus(
            orderId: orderModel.id,
            context: context,
            status: 'delivered',
          )
          .timeout(const Duration(seconds: 35), onTimeout: () => false);
    } on TimeoutException {
      success = false;
    }

    if (success && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderDeliveredScreen(
            orderID: orderModel.id.toString(),
            orderModel: orderModel,
          ),
        ),
      );
    }
  }

}

