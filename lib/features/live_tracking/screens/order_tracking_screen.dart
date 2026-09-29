
import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/features/live_tracking/widgets/expendale_bottom_sheet_widget.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class OrderLiveTrackingScreen extends StatefulWidget {
  final OrderModel? orderModel;
  final bool openForDeliver;
  const OrderLiveTrackingScreen({
    super.key,
    this.orderModel,
    this.openForDeliver = false,
  });

  @override
  State<OrderLiveTrackingScreen> createState() => _OrderLiveTrackingScreenState();
}

class _OrderLiveTrackingScreenState extends State<OrderLiveTrackingScreen> {
  bool _isRefreshingRoute = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderModel != null) {
      final rider = Get.find<RiderController>();
      if (widget.openForDeliver) {
        rider.setFullView();
      } else {
        rider.setHalfView();
      }
      _loadTracking();
    }
  }

  Future<void> _loadTracking() async {
    final order = widget.orderModel!;
    if (order.id != null && Get.isRegistered<OrderDetailsController>()) {
      await Get.find<OrderDetailsController>()
          .getOrderDetails('${order.id}', context, silent: true);
    }
    if (!mounted) return;
    final rider = Get.find<RiderController>();
    final trackingOrder = rider.resolveOrderForTracking(order);
    await rider.startOrderTracking(trackingOrder);
  }

  @override
  void dispose() {
    // Keep external-nav arrival monitoring while Google Maps is in the foreground.
    Get.find<RiderController>().stopMapTracking(clearExternalNav: false);
    super.dispose();
  }

  String _distanceLabel(RiderController riderController) {
    if (riderController.isRouteLoading) return '...';
    return riderController.formattedTripLabel;
  }

  Future<void> _openDirection(RiderController riderController) async {
    if (_isRefreshingRoute) return;
    setState(() => _isRefreshingRoute = true);

    try {
      // Prefer rider's live tracking order (status after swipe) over the
      // stale OrderModel snapshot passed into this screen.
      final OrderModel? liveOrder =
          riderController.trackingOrder ?? widget.orderModel;
      final opened = await riderController.openExternalNavigation(
        orderId: liveOrder?.id ?? widget.orderModel?.id,
        order: liveOrder,
      );
      if (!opened) {
        Get.snackbar(
          'direction'.tr,
          'could_not_open_maps'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double sheetExpandedHeight = screenHeight * 0.55;

    return GetBuilder<RiderController>(
      builder: (riderController) {
        return GetBuilder<OrderDetailsController>(
          builder: (_) {
        final Widget? deliverBar = _buildDeliverBar(context);
        final orderForBar = _resolveTrackingOrder();
        final detailsCtrl = Get.isRegistered<OrderDetailsController>()
            ? Get.find<OrderDetailsController>()
            : null;
        final bool needsCodPayment = orderForBar != null &&
            orderForBar.paymentMethod == 'cash_on_delivery' &&
            orderForBar.paymentStatus != 'paid' &&
            !(detailsCtrl?.isCodPaymentCollected(orderForBar.id) ?? false);
        final alreadyReached = detailsCtrl
                ?.hasReachedRestaurant(orderForBar?.id) ??
            false;
        final canReach = OrderStatusHelper.canReachRestaurant(
          orderForBar?.orderStatus,
          alreadyReached: alreadyReached,
          storeWaitStartedAt: orderForBar?.storeWaitStartedAt,
          pickupVerificationStatus: orderForBar?.pickupVerificationStatus,
          orderTransferReceived: orderForBar?.orderTransferReceived,
        );
        final canPick = OrderStatusHelper.canPickUp(
          orderForBar?.orderStatus,
          alreadyReached: alreadyReached,
          storeWaitStartedAt: orderForBar?.storeWaitStartedAt,
          pickupVerificationStatus: orderForBar?.pickupVerificationStatus,
          orderTransferReceived: orderForBar?.orderTransferReceived,
        );
        final showCollectUi = needsCodPayment && !canReach && !canPick;
        final showAcceptPayment = showCollectUi &&
            (OrderStatusHelper.canDeliver(orderForBar?.orderStatus) ||
                OrderStatusHelper.canArriveAtCustomer(
                    orderForBar?.orderStatus) ||
                OrderStatusHelper.canStartOutForDelivery(
                    orderForBar?.orderStatus));
        final bottomSafe = MediaQuery.paddingOf(context).bottom;
        // Match real bar height so map isn't covered / over-padded.
        final double deliverBarInset = deliverBar == null
            ? 0
            : showAcceptPayment
                ? 148 + bottomSafe
                : showCollectUi
                    ? 92 + bottomSafe
                    : 74 + bottomSafe;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: deliverBarInset),
                child: ExpandableBottomSheet(
                  background: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomGoogleMapMarkerBuilder(
                    customMarkers: riderController.customMarkers,
                    builder: (context, markers) {
                      return GoogleMap(
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        initialCameraPosition: CameraPosition(
                          target: riderController.mapCameraTarget,
                          zoom: riderController.mapInitialZoom,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          riderController.onMapReady(controller);
                        },
                        minMaxZoomPreference: const MinMaxZoomPreference(5, 18),
                        markers: Set<Marker>.of(markers ?? []),
                        polylines:
                            Set<Polyline>.of(riderController.polylines.values),
                        zoomControlsEnabled: false,
                        compassEnabled: true,
                        mapToolbarEnabled: false,
                      );
                    },
                  ),
                ),
                if (riderController.isRouteLoading)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: .125),
                            blurRadius: 5,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _openDirection(riderController),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: .125),
                            blurRadius: 5,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isRefreshingRoute
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                )
                              : Icon(
                                  Icons.navigation_rounded,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                          const SizedBox(width: 6),
                          Text(
                            _isRefreshingRoute ? 'Updating...' : 'direction'.tr,
                            style: rubikMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            persistentHeader: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeExtraSmall,
              ),
              margin: EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeDefault),
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                _distanceLabel(riderController),
                style: rubikRegular.copyWith(
                  color: Get.isDarkMode
                      ? Theme.of(context).highlightColor
                      : Theme.of(context).cardColor,
                ),
              ),
            ),
            persistentFooter: const SizedBox.shrink(),
            persistentContentHeight: riderController.persistentContentHeight,
            expandableContent: SizedBox(
              height: sheetExpandedHeight,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: RiderBottomSheetWidget(orderModel: widget.orderModel),
              ),
            ),
                ),
              ),
              if (deliverBar != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: deliverBar,
                ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  OrderModel? _resolveTrackingOrder() {
    final detailsController = Get.isRegistered<OrderDetailsController>()
        ? Get.find<OrderDetailsController>()
        : null;
    final fromApi = detailsController?.orderDetails?.isNotEmpty == true
        ? detailsController!.orderDetails!.first.orderModel
        : null;
    final fallback = widget.orderModel;
    final resolved = fromApi ?? fallback;
    if (resolved == null) return null;

    if (fromApi != null && fallback != null && fromApi.id == fallback.id) {
      final method = (fromApi.paymentMethod ?? '').trim();
      final fallbackMethod = (fallback.paymentMethod ?? '').trim();
      if (method.isEmpty && fallbackMethod.isNotEmpty) {
        fromApi.paymentMethod = fallback.paymentMethod;
      }
      final payStatus = (fromApi.paymentStatus ?? '').trim();
      final fallbackPayStatus = (fallback.paymentStatus ?? '').trim();
      if (payStatus.isEmpty && fallbackPayStatus.isNotEmpty) {
        fromApi.paymentStatus = fallback.paymentStatus;
      }
    }

    if (Get.isRegistered<OrderController>()) {
      final orderCtrl = Get.find<OrderController>();
      for (final o in [
        ...orderCtrl.currentOrders,
        ...orderCtrl.scheduledCurrentOrders,
      ]) {
        if (o.id != resolved.id) continue;
        final liveRank =
            OrderStatusHelper.statusProgressRank(o.orderStatus);
        final viewRank =
            OrderStatusHelper.statusProgressRank(resolved.orderStatus);
        if (liveRank > viewRank) {
          resolved.orderStatus = o.orderStatus;
        }
        resolved.storeWaitStartedAt ??= o.storeWaitStartedAt;
        if ((o.orderTransferReceived ?? 0) == 1) {
          resolved.orderTransferReceived = 1;
        }
        if ((o.pickupVerificationStatus ?? 0) == 1) {
          resolved.pickupVerificationStatus = 1;
        }
        final method = (resolved.paymentMethod ?? '').trim();
        final liveMethod = (o.paymentMethod ?? '').trim();
        if (method.isEmpty && liveMethod.isNotEmpty) {
          resolved.paymentMethod = o.paymentMethod;
        }
        final payStatus = (resolved.paymentStatus ?? '').trim();
        final livePayStatus = (o.paymentStatus ?? '').trim();
        if (payStatus.isEmpty && livePayStatus.isNotEmpty) {
          resolved.paymentStatus = o.paymentStatus;
        }
        break;
      }
    }
    return resolved;
  }

  Widget? _buildDeliverBar(BuildContext context) {
    return null;
  }
}
