import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:quiksee/features/live_tracking/controllers/rider_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order_details/widgets/cal_chat_widget.dart';
import 'package:quiksee/helper/location_permission_helper.dart';
import 'package:quiksee/utill/styles.dart';

/// Swiggy/Zomato-style in-app turn-by-turn using Google Navigation SDK.
class OrderNavigationSdkScreen extends StatefulWidget {
  final OrderModel? orderModel;
  final bool openForDeliver;

  const OrderNavigationSdkScreen({
    super.key,
    this.orderModel,
    this.openForDeliver = false,
  });

  @override
  State<OrderNavigationSdkScreen> createState() =>
      _OrderNavigationSdkScreenState();
}

class _OrderNavigationSdkScreenState extends State<OrderNavigationSdkScreen> {
  GoogleNavigationViewController? _navViewController;
  bool _sessionReady = false;
  bool _guidanceRunning = false;
  bool _starting = false;
  bool _retargetScheduled = false;
  String? _error;
  String _destLabel = '';
  bool _destIsStore = true;
  double? _remainMeters;
  double? _remainSeconds;

  StreamSubscription<RemainingTimeOrDistanceChangedEvent>? _etaSub;
  StreamSubscription<OnArrivalEvent>? _arrivalSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final order = widget.orderModel;
    if (order == null) {
      setState(() => _error = 'Order not found');
      return;
    }

    final ok = await LocationPermissionHelper.ensureLocationReady(
      context: context,
      showDialog: true,
    );
    if (!ok) {
      if (mounted) {
        setState(() => _error = 'Location permission required for navigation');
      }
      return;
    }

    if (order.id != null && Get.isRegistered<OrderDetailsController>()) {
      if (!mounted) return;
      await Get.find<OrderDetailsController>().getOrderDetails(
        '${order.id}',
        context,
        silent: true,
      );
    }
    if (!mounted) return;

    try {
      if (!await GoogleMapsNavigator.areTermsAccepted()) {
        await GoogleMapsNavigator.showTermsAndConditionsDialog(
          'Quiksee Navigation',
          'QUIKSEE PRIVATE LIMITED',
        );
      }
      if (!await GoogleMapsNavigator.areTermsAccepted()) {
        if (mounted) {
          setState(() => _error = 'Please accept navigation terms to continue');
        }
        return;
      }

      await GoogleMapsNavigator.initializeNavigationSession(
        taskRemovedBehavior: TaskRemovedBehavior.continueService,
      );
      await GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.alertsAndGuidance,
        ),
      );

      _etaSub = GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
        (event) {
          if (!mounted) return;
          setState(() {
            _remainMeters = event.remainingDistance;
            _remainSeconds = event.remainingTime;
          });
        },
      );
      _arrivalSub = GoogleMapsNavigator.setOnArrivalListener((_) {});

      if (!mounted) return;
      setState(() => _sessionReady = true);
      await _startOrUpdateRoute();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Nav SDK bootstrap failed: $e\n$st');
      }
      if (mounted) {
        setState(() => _error = 'Could not start navigation');
      }
    }
  }

  OrderModel? _liveOrder() {
    final details = Get.isRegistered<OrderDetailsController>()
        ? Get.find<OrderDetailsController>()
        : null;
    final fromApi = details?.orderDetails?.isNotEmpty == true
        ? details!.orderDetails!.first.orderModel
        : null;
    final rider = Get.isRegistered<RiderController>()
        ? Get.find<RiderController>().trackingOrder
        : null;
    return fromApi ?? rider ?? widget.orderModel;
  }

  Future<void> _startOrUpdateRoute() async {
    if (_starting || !_sessionReady) return;
    final order = _liveOrder();
    if (order == null) return;

    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final rider = Get.find<RiderController>();
      final target = await rider.resolveNavigationTarget(order);
      if (target == null) {
        if (mounted) {
          setState(() {
            _error = OrderStatusHelper.isStoreNavigationStatus(order.orderStatus)
                ? 'Could not find store location'
                : 'Could not find customer location';
            _starting = false;
          });
        }
        return;
      }

      _destLabel = target.label;
      _destIsStore = target.isStore;

      // SDK needs a location fix before setDestinations.
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final destinations = Destinations(
        waypoints: <NavigationWaypoint>[
          NavigationWaypoint.withLatLngTarget(
            title: target.label,
            target: LatLng(latitude: target.lat, longitude: target.lng),
          ),
        ],
        displayOptions: NavigationDisplayOptions(
          showDestinationMarkers: true,
        ),
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
          locationTimeoutMs: 20000,
        ),
      );

      final status = await GoogleMapsNavigator.setDestinations(destinations);
      if (status != NavigationRouteStatus.statusOk) {
        if (mounted) {
          setState(() {
            _error = _routeStatusMessage(status);
            _starting = false;
          });
        }
        // Retry once if GPS was not ready.
        if (status == NavigationRouteStatus.locationUnavailable ||
            status == NavigationRouteStatus.locationUnknown) {
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted && !_guidanceRunning) {
            setState(() => _starting = false);
            await _startOrUpdateRoute();
          }
        }
        return;
      }

      await GoogleMapsNavigator.startGuidance();
      await _navViewController?.followMyLocation(CameraPerspective.tilted);
      if (mounted) {
        setState(() {
          _guidanceRunning = true;
          _starting = false;
          _error = null;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Nav route failed: $e');
      if (mounted) {
        setState(() {
          _error = 'Navigation failed';
          _starting = false;
        });
      }
    }
  }

  String _routeStatusMessage(NavigationRouteStatus status) {
    switch (status) {
      case NavigationRouteStatus.apiKeyNotAuthorized:
        return 'API key not authorized for Navigation SDK';
      case NavigationRouteStatus.quotaExceeded:
      case NavigationRouteStatus.quotaCheckFailed:
        return 'Navigation quota exceeded';
      case NavigationRouteStatus.locationUnavailable:
      case NavigationRouteStatus.locationUnknown:
        return 'Waiting for GPS location…';
      case NavigationRouteStatus.networkError:
        return 'Network required to calculate route';
      case NavigationRouteStatus.routeNotFound:
        return 'Route could not be calculated';
      default:
        return 'Could not start route';
    }
  }

  Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
    _navViewController = controller;
    await controller.setMyLocationEnabled(true);
    if (_guidanceRunning) {
      await controller.followMyLocation(CameraPerspective.tilted);
    }
  }

  Future<void> _stopAndExit() async {
    try {
      if (await GoogleMapsNavigator.isGuidanceRunning()) {
        await GoogleMapsNavigator.stopGuidance();
      }
      await GoogleMapsNavigator.clearDestinations();
      await GoogleMapsNavigator.cleanup();
    } catch (_) {}
    if (mounted) Get.back();
  }

  @override
  void dispose() {
    _etaSub?.cancel();
    _arrivalSub?.cancel();
    unawaited(() async {
      try {
        if (await GoogleMapsNavigator.isInitialized()) {
          if (await GoogleMapsNavigator.isGuidanceRunning()) {
            await GoogleMapsNavigator.stopGuidance();
          }
          await GoogleMapsNavigator.cleanup();
        }
      } catch (_) {}
    }());
    super.dispose();
  }

  String get _etaText {
    final sec = _remainSeconds;
    if (sec == null) return '--';
    final mins = (sec / 60).ceil();
    if (mins < 1) return '< 1 min';
    return '$mins min';
  }

  String get _distanceText {
    final m = _remainMeters;
    if (m == null) return '--';
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return GetBuilder<OrderDetailsController>(
      builder: (_) {
        final order = _liveOrder();
        final wantStore =
            OrderStatusHelper.isStoreNavigationStatus(order?.orderStatus);
        if (_guidanceRunning &&
            !_starting &&
            !_retargetScheduled &&
            wantStore != _destIsStore) {
          _retargetScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _startOrUpdateRoute();
            _retargetScheduled = false;
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_sessionReady)
                GoogleMapsNavigationView(
                  onViewCreated: _onViewCreated,
                  initialNavigationUIEnabledPreference:
                      NavigationUIEnabledPreference.automatic,
                  initialForceNightMode: NavigationForceNightMode.auto,
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              Positioned(
                top: topInset + 8,
                left: 10,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _stopAndExit,
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.close_rounded, size: 22),
                    ),
                  ),
                ),
              ),

              if (_starting)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              if (_error != null)
                Positioned(
                  top: topInset + 56,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: rubikMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _etaStrip(context),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _destinationCard(context, order),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _etaStrip(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _etaText,
              style: rubikBold.copyWith(
                fontSize: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('·', style: rubikBold.copyWith(fontSize: 18)),
            ),
            Text(
              _distanceText,
              style: rubikMedium.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationCard(BuildContext context, OrderModel? order) {
    final title = _destIsStore
        ? (order?.displayStoreName?.trim().isNotEmpty == true
            ? order!.displayStoreName!
            : 'Store')
        : (order?.shippingAddress?.contactPersonName?.trim().isNotEmpty == true
            ? order!.shippingAddress!.contactPersonName!.trim()
            : 'Customer');
    final badge = _destIsStore ? 'Store' : 'Customer';
    final address = _destLabel.isNotEmpty
        ? _destLabel
        : (order?.shippingAddress?.address ?? '');
    final hideContact =
        OrderStatusHelper.shouldHideCustomerContact(order?.orderStatus);

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: rubikBold.copyWith(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: rubikMedium.copyWith(
                            fontSize: 11,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: rubikRegular.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    '${'order'.tr} #${order?.id ?? '--'}',
                    style: rubikRegular.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (!hideContact && order != null && !_destIsStore)
              CallAndChatWidget(orderModel: order),
          ],
        ),
      ),
    );
  }
}
