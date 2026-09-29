import 'dart:async';

import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quiksee/data/repository/rider_repository.dart';
import 'package:quiksee/features/live_tracking/domain/models/distance_model.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/features/order/helpers/order_status_helper.dart';
import 'package:quiksee/helper/gps_location_helper.dart';
import 'package:quiksee/helper/location_permission_helper.dart';
import 'package:quiksee/helper/map_navigation_helper.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:quiksee/utill/images.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderController extends GetxController implements GetxService {
  RiderController({required this.riderRepo});

  final RiderRepository riderRepo;

  double _persistentContentHeight = Get.context!.width <= 400 ? 220 : 260;
  double get persistentContentHeight => _persistentContentHeight;

  double? _distance;
  double? get distance => _distance;
  String? _etaText;
  String? get etaText => _etaText;

  Position? _position;
  Position? get position => _position;

  LatLng _initialPosition = const LatLng(20.5937, 78.9629);
  LatLng get initialPosition => _initialPosition;

  LatLng get mapCameraTarget {
    if (_hasGpsFix) return _initialPosition;
    if (_destination != null) return _destination!;
    return _initialPosition;
  }

  double get mapInitialZoom => _hasGpsFix ? 15 : (_destination != null ? 13 : 5);

  LatLng? _destination;
  LatLng? get destination => _destination;
  String? _destinationAddressLabel;
  String? get destinationAddressLabel => _destinationAddressLabel;
  OrderModel? _trackingOrder;
  OrderModel? get trackingOrder => _trackingOrder;

  final List<MarkerData> _customMarkers = [];
  List<MarkerData> get customMarkers => _customMarkers;

  final Map<PolylineId, Polyline> polylines = {};

  GoogleMapController? mapController;
  StreamSubscription<Position>? _positionStream;
  Timer? _gpsBroadcastTimer;
  int? _gpsOrderId;
  bool _sendingLocation = false;
  DateTime? _lastLocationSentAt;
  static const Duration _gpsBroadcastInterval = Duration(seconds: 20);

  bool _isRouteLoading = false;
  bool get isRouteLoading => _isRouteLoading;

  bool _hasGpsFix = false;
  bool get hasGpsFix => _hasGpsFix;

  DateTime? _lastDistanceApiCall;
  DateTime? _lastPolylineRefresh;
  LatLng? _lastPolylineOrigin;
  DateTime? _lastCameraFit;
  bool _isUpdatingMetrics = false;

  int? _externalNavOrderId;
  bool _arrivalNotificationSent = false;
  Timer? _externalNavWatchTimer;
  static const double _arrivalRadiusMeters = 850;

  static const double _polylineRefreshMeters = 120;
  static const Duration _polylineRefreshMinInterval = Duration(seconds: 40);
  static const Duration _distanceApiMinInterval = Duration(seconds: 10);

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapExternalNavWatcher());
  }

  Future<void> _bootstrapExternalNavWatcher() async {
    await _restoreExternalNavState();
    if (_externalNavOrderId != null && _destination != null) {
      _startExternalNavWatcher();
    }
  }

  String get formattedDistanceLabel {
    if (!_hasGpsFix || _distance == null) return '...';
    final double km = _distance!;
    if (km < 0.1) {
      final int meters = (km * 1000).round().clamp(1, 999);
      return '$meters m';
    }
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(2)} km';
  }

  String get formattedTripLabel {
    if (_destination == null && (_destinationAddressLabel?.isNotEmpty ?? false)) {
      return 'receiver'.tr;
    }
    final String distancePart = formattedDistanceLabel;
    if (distancePart == '...') {
      if (_destination != null) return 'receiver'.tr;
      return distancePart;
    }
    final String? eta = _etaText;
    if (eta == null || eta.isEmpty) return distancePart;
    return '$distancePart • $eta';
  }

  Future<bool> openExternalNavigation({
    int? orderId,
    OrderModel? order,
  }) async {
    // until getCurrentOrders returns after swipe.
    final preferredStatus =
        order?.orderStatus ?? _trackingOrder?.orderStatus;
    OrderModel? resolved = order ?? _trackingOrder;
    final id = orderId ?? resolved?.id;
    if (id != null) {
      final fromList = _findOrderById(id);
      if (fromList != null) {
        resolved = resolved == null
            ? fromList
            : _mergeOrderAddresses(resolved, fromList);
      }
    }
    if (resolved != null) {
      resolved = _enrichOrderFromDetails(resolved);
      if (preferredStatus != null && preferredStatus.isNotEmpty) {
        resolved.orderStatus = _preferAdvancedStatus(
              preferredStatus,
              resolved.orderStatus,
            ) ??
            preferredStatus;
      }
      resolved = _withFreshStatus(resolved);
      _trackingOrder = resolved;
    }

    String? navAddress = resolved != null
        ? _navigationAddressForOrder(resolved)
        : null;
    navAddress ??= _destinationAddressLabel;

    // Always resolve by current status first (pickup = store, deliver = customer).
    LatLng? navTarget;
    if (resolved != null) {
      navTarget = await _resolveDestination(resolved);
    }
    if (!_isPickupNavigationStatus(resolved?.orderStatus)) {
      navTarget ??=
          _coordsFromShipping(resolved?.resolvedCustomerShipping) ??
          _coordsFromShipping(resolved?.shippingAddress);
    }
    if (navTarget == null) {
      navTarget = _destination;
    }

    if (navTarget == null && resolved != null) {
      if (_isPickupNavigationStatus(resolved.orderStatus)) {
        navTarget = await _resolveStoreLocationForOrder(resolved);
      } else {
        navTarget = await _resolveReceiverLocation(
          resolved.resolvedCustomerShipping ?? resolved.shippingAddress,
        );
      }
    }

    if ((navAddress == null || navAddress.isEmpty) && navTarget == null) {
      if (kDebugMode) {
        debugPrint(
          'openExternalNavigation failed: no address/coords for order=$orderId',
        );
      }
      return false;
    }

    if (kDebugMode) {
      debugPrint(
        'openExternalNavigation order=${resolved?.id ?? orderId} '
        'status=${resolved?.orderStatus} '
        'address=$navAddress '
        'coords=${navTarget != null ? '${navTarget.latitude},${navTarget.longitude}' : 'none'}',
      );
    }

    final resolvedOrderId = orderId ?? resolved?.id;
    final alreadyAtDestination = navTarget != null && _isWithinArrivalRadius();
    if (resolvedOrderId != null && resolvedOrderId > 0 && navTarget != null) {
      _destination = navTarget;
      _destinationAddressLabel = navAddress ?? _destinationAddressLabel;
      _externalNavOrderId = resolvedOrderId;
      _arrivalNotificationSent = false;
      await _persistExternalNavOrderId(resolvedOrderId);
      await _persistExternalNavDestination(
        navTarget,
        navAddress ?? _destinationAddressLabel,
      );
      _startExternalNavWatcher();
    }

    final opened = await MapNavigationHelper.openDrivingNavigation(
      latitude: navTarget?.latitude,
      longitude: navTarget?.longitude,
      address: navAddress,
    );

    if (resolvedOrderId != null && resolvedOrderId > 0) {
      if (alreadyAtDestination) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await _showArrivalDeliverPopup(resolvedOrderId);
      } else {
      }
    }

    return opened;
  }

  OrderModel? _findOrderById(int orderId) {
    if (Get.isRegistered<OrderController>()) {
      final orderCtrl = Get.find<OrderController>();
      for (final candidate in [
        ...orderCtrl.currentOrders,
        ...orderCtrl.scheduledCurrentOrders,
      ]) {
        if (candidate.id == orderId) return candidate;
      }
    }
    if (Get.isRegistered<OrderDetailsController>()) {
      final details = Get.find<OrderDetailsController>().orderDetails;
      if (details != null) {
        for (final entry in details) {
          final model = entry.orderModel;
          if (model?.id == orderId) return model;
        }
      }
    }
    if (_trackingOrder?.id == orderId) return _trackingOrder;
    return null;
  }

  /// Copy missing address / seller fields from [other] onto [base].
  OrderModel _mergeOrderAddresses(OrderModel base, OrderModel other) {
    if (other.shippingAddress != null) {
      _mergeShippingAddress(base.shippingAddress, other.shippingAddress!);
      base.shippingAddress ??= other.shippingAddress;
    }
    if (other.sellerInfo != null) {
      base.sellerInfo ??= other.sellerInfo;
    }
    base.orderStatus = _preferAdvancedStatus(
          base.orderStatus,
          other.orderStatus,
        ) ??
        base.orderStatus ??
        other.orderStatus;
    return base;
  }

  /// Merge freshest status / addresses into the order used for navigation.
  OrderModel _withFreshStatus(OrderModel order) {
    final fresh = order.id != null ? _findOrderById(order.id!) : null;
    if (fresh == null) return order;
    return _mergeOrderAddresses(order, fresh);
  }

  /// Keep the furthest delivery stage (local swipe may be ahead of list refresh).
  String? _preferAdvancedStatus(String? a, String? b) {
    final left = (a ?? '').toLowerCase();
    final right = (b ?? '').toLowerCase();
    final ra = OrderStatusHelper.statusRank(left);
    final rb = OrderStatusHelper.statusRank(right);
    if (ra < 0 && rb < 0) return null;
    if (ra >= rb) return left.isEmpty ? null : left;
    return right.isEmpty ? null : right;
  }

  OrderModel resolveOrderForTracking(OrderModel order) {
    var resolved = _enrichOrderFromDetails(order);
    if ((resolved.shippingAddress == null ||
            !_hasUsableShippingCoords(resolved.shippingAddress)) &&
        resolved.id != null) {
      final fromList = _findOrderById(resolved.id!);
      if (fromList != null) {
        resolved = _enrichOrderFromDetails(fromList);
      }
    }
    return resolved;
  }

  bool _hasUsableShippingCoords(ShippingAddress? address) {
    return _coordsFromShipping(address) != null;
  }

  LatLng? _coordsFromShipping(ShippingAddress? address) {
    if (address == null) return null;
    final double? lat = _parseCoordinate(address.latitude);
    final double? lng = _parseCoordinate(address.longitude);
    if (!_isValidCoordinatePair(lat, lng)) return null;
    return LatLng(lat!, lng!);
  }

  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return double.tryParse(value.toString());
  }

  bool _isValidCoordinatePair(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    // Reject clearly non-India pins (seen: Sydney defaults from bad geocode).
    if (lat < 6.0 || lat > 38.0 || lng < 68.0 || lng > 98.0) return false;
    return true;
  }

  @override
  void onClose() {
    _stopExternalNavWatcher();
    stopMapTracking(clearExternalNav: true);
    stopGpsBroadcast();
    super.onClose();
  }

  void setFullView() {
    final double height = Get.context != null
        ? MediaQuery.sizeOf(Get.context!).height
        : 800;
    _persistentContentHeight = (height * 0.42).clamp(260, 520);
    update();
  }

  void setHalfView() {
    final double height = Get.context != null
        ? MediaQuery.sizeOf(Get.context!).height
        : 800;
    _persistentContentHeight = (height * 0.22).clamp(180, 280);
    update();
  }

  void stopOrderTracking() {
    stopMapTracking(clearExternalNav: true);
  }

  void stopMapTracking({bool clearExternalNav = false}) {
    _positionStream?.cancel();
    _positionStream = null;
    if (clearExternalNav) {
      final navOrderId = _externalNavOrderId;
      _stopExternalNavWatcher();
      _externalNavOrderId = null;
      _arrivalNotificationSent = false;
      unawaited(_clearExternalNavState(orderId: navOrderId));
    }
    _destination = null;
    _destinationAddressLabel = null;
    _trackingOrder = null;
    _customMarkers.clear();
    polylines.clear();
    _distance = null;
    _etaText = null;
    _hasGpsFix = false;
    _lastDistanceApiCall = null;
    _lastPolylineRefresh = null;
    _lastPolylineOrigin = null;
  }

  /// Sends GPS to server every 12s while order is out for delivery.
  void startGpsBroadcast(int orderId) {
    if (_gpsOrderId == orderId && _gpsBroadcastTimer != null) {
      return;
    }
    stopGpsBroadcast();
    _gpsOrderId = orderId;
    sendLocationToServer(orderId);
    _gpsBroadcastTimer = Timer.periodic(_gpsBroadcastInterval, (_) {
      final activeOrderId = _gpsOrderId;
      if (activeOrderId != null) {
        sendLocationToServer(activeOrderId);
      }
    });
  }

  void stopGpsBroadcast() {
    _gpsBroadcastTimer?.cancel();
    _gpsBroadcastTimer = null;
    _gpsOrderId = null;
  }

  int? get activeGpsOrderId => _gpsOrderId;

  Future<void> sendLocationToServer(int orderId) async {
    if (_sendingLocation) return;
    final DateTime now = DateTime.now();
    if (_lastLocationSentAt != null &&
        now.difference(_lastLocationSentAt!) < const Duration(seconds: 15)) {
      return;
    }

    _sendingLocation = true;
    try {
      Position? current;
      if (_position != null && GpsLocationHelper.isUsableForUpload(_position!)) {
        current = _position;
      } else {
        current = await GpsLocationHelper.resolveFreshPosition(
          timeout: const Duration(seconds: 10),
        );
      }
      if (current == null) {
        return;
      }
      final String locationText = '${current.latitude}, ${current.longitude}';
      final Response response = await riderRepo.recordLocationData(
        orderId: orderId,
        latitude: current.latitude,
        longitude: current.longitude,
        location: locationText,
      );
      if (response.statusCode == 200) {
        _lastLocationSentAt = now;
      } else {
        debugPrint('record-location-data failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('sendLocationToServer: $e');
    } finally {
      _sendingLocation = false;
    }
  }

  /// Resume GPS broadcast when app opens with an active delivery.
  void resumeGpsForOrders(List<OrderModel> orders) {
    for (final OrderModel order in orders) {
      if (order.id == null) continue;
      if (order.orderStatus == 'out_for_delivery') {
        startGpsBroadcast(order.id!);
        return;
      }
    }
    stopGpsBroadcast();
  }

  /// Entry point from order tracking screen.
  Future<void> startOrderTracking(OrderModel order) async {
    stopMapTracking();
    _trackingOrder = order;
    if (order.id != null && order.orderStatus == 'out_for_delivery') {
      startGpsBroadcast(order.id!);
    }
    _isRouteLoading = true;
    update();

    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) {
      _isRouteLoading = false;
      update();
      return;
    }

    // Auto-fetch driver's current location first.
    await _acquireCurrentLocation();

    final OrderModel trackingOrder =
        _withFreshStatus(resolveOrderForTracking(order));
    _trackingOrder = trackingOrder;
    LatLng? resolvedDestination = await _resolveDestination(trackingOrder);
    final isPickupPhase =
        _isPickupNavigationStatus(trackingOrder.orderStatus);
    // Pickup phase → store only. Never fall back to customer coords (wrong pin).
    if (resolvedDestination == null && !isPickupPhase) {
      resolvedDestination =
          _coordsFromShipping(trackingOrder.resolvedCustomerShipping) ??
          _coordsFromShipping(trackingOrder.shippingAddress);
    }
    if (resolvedDestination == null) {
      final String? navAddress = _navigationAddressForOrder(trackingOrder);
      if (navAddress != null && navAddress.isNotEmpty) {
        _destinationAddressLabel = navAddress;
        resolvedDestination = await _geocodeQuery([navAddress]);
      }
    }
    if (resolvedDestination == null) {
      _isRouteLoading = false;
      update();
      Get.snackbar(
        'location'.tr,
        isPickupPhase
            ? 'Could not find store location for pickup.'
            : 'Could not find customer delivery location.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _destination = resolvedDestination;
    Get.find<OrderController>().setSelectedOrderLatLng(resolvedDestination);

    if (_hasGpsFix) {
      _applyInstantDistance(_initialPosition, _destination!);
      await getPolyline(from: _initialPosition, to: _destination!);
      await setDestinationMarker(_destination!);
      _lastPolylineOrigin = _initialPosition;
      _lastPolylineRefresh = DateTime.now();
      await _updateTripMetrics(_initialPosition, _destination!);
    } else {
      await setDestinationMarker(_destination!);
    }

    _startLiveLocationUpdates();
    _isRouteLoading = false;
    update();

    if (mapController != null) {
      await _fitCameraToRoute();
    }
  }

  Future<void> _acquireCurrentLocation() async {
    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (GpsLocationHelper.isUsableLastKnown(last)) {
        _applyPosition(last!);
        update();
      }
    } catch (_) {}

    try {
      final Position current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _applyPosition(current);
      update();
    } catch (e) {
      debugPrint('acquireCurrentLocation: $e');
      if (!_hasGpsFix) {
        Get.snackbar(
          'share_your_location'.tr,
          'enable_gps_for_live_tracking'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _applyPosition(Position position) {
    _position = position;
    _hasGpsFix = true;
    _initialPosition = LatLng(position.latitude, position.longitude);
  }

  Future<void> onMapReady(GoogleMapController controller) async {
    mapController = controller;
    if (!_hasGpsFix) {
      await _acquireCurrentLocation();
    }
    if (_destination != null && _hasGpsFix) {
      await getPolyline(from: _initialPosition, to: _destination!);
      await setDestinationMarker(_destination!);
    }
    await _fitCameraToRoute();
  }

  Future<void> focusOnDeliveryRoute() async {
    await _refreshFromCurrentLocation();
    await _fitCameraToRoute();
  }

  OrderModel _enrichOrderFromDetails(OrderModel order) {
    if (!Get.isRegistered<OrderDetailsController>()) return order;
    final details = Get.find<OrderDetailsController>().orderDetails;
    if (details == null || details.isEmpty) return order;
    final detailed = details.first.orderModel;
    if (detailed == null || detailed.id != order.id) return order;
    if (detailed.shippingAddress != null) {
      _mergeShippingAddress(order.shippingAddress, detailed.shippingAddress!);
      order.shippingAddress = detailed.shippingAddress;
    }
    if (detailed.sellerInfo != null) {
      order.sellerInfo = detailed.sellerInfo;
    }
    return order;
  }

  void _mergeShippingAddress(ShippingAddress? existing, ShippingAddress incoming) {
    if (existing == null) return;
    if (!_isValidCoordinate(incoming.latitude, incoming.longitude) &&
        _isValidCoordinate(existing.latitude, existing.longitude)) {
      incoming.latitude = existing.latitude;
      incoming.longitude = existing.longitude;
    }
  }

  /// Public: resolve lat/lng + label for in-app Navigation SDK.
  Future<({double lat, double lng, String label, bool isStore})?>
      resolveNavigationTarget(OrderModel order) async {
    final tracking = resolveOrderForTracking(order);
    final fresh = _withFreshStatus(tracking);
    final isStore = _isPickupNavigationStatus(fresh.orderStatus);
    final LatLng? dest = await _resolveDestination(fresh);
    if (dest == null) return null;
    final label = _navigationAddressForOrder(fresh) ??
        (isStore
            ? (fresh.displayStoreName ?? 'Store')
            : (fresh.shippingAddress?.contactPersonName ?? 'Customer'));
    return (
      lat: dest.latitude,
      lng: dest.longitude,
      label: label,
      isStore: isStore,
    );
  }

  /// Pickup navigation = store until order is picked up.
  /// After pickup (`processing`) and `out_for_delivery` → customer.
  bool _isPickupNavigationStatus(String? status) {
    return OrderStatusHelper.isStoreNavigationStatus(status);
  }

  String? _navigationAddressForOrder(OrderModel order) {
    if (_isPickupNavigationStatus(order.orderStatus)) {
      return _strictStoreNavigationAddress(order.sellerInfo?.shop);
    }
    return _strictNavigationAddress(
      order.resolvedCustomerShipping ?? order.shippingAddress,
    );
  }

  Future<LatLng?> _resolveDestination(OrderModel order) async {
    if (_isPickupNavigationStatus(order.orderStatus)) {
      return _resolveStoreLocationForOrder(order);
    }

    return _resolveReceiverLocation(
      order.resolvedCustomerShipping ?? order.shippingAddress,
    );
  }

  /// After pickup / out-for-delivery, switch map + notification to customer.
  Future<void> retargetNavigationForOrder(OrderModel order) async {
    if (order.id == null) return;

    final String? swipeStatus = order.orderStatus;
    var updated = _withFreshStatus(order);
    updated.orderStatus = _preferAdvancedStatus(
          swipeStatus,
          updated.orderStatus,
        ) ??
        swipeStatus ??
        updated.orderStatus;
    if (_isPickupNavigationStatus(updated.orderStatus)) return;

    _trackingOrder = updated;
    final LatLng? dest = await _resolveDestination(updated);
    final String? label = _navigationAddressForOrder(updated);
    if (dest == null && (label == null || label.isEmpty)) return;

    if (dest != null) {
      _destination = dest;
      Get.find<OrderController>().setSelectedOrderLatLng(dest);
    }
    if (label != null && label.isNotEmpty) {
      _destinationAddressLabel = label;
    }
    if (_destination != null) {
      _externalNavOrderId = updated.id;
      await _persistExternalNavOrderId(updated.id!);
      await _persistExternalNavDestination(
        _destination!,
        _destinationAddressLabel,
      );
      _startExternalNavWatcher();
      // In-app map must jump from store → customer immediately on swipe.
      await _refreshMapRouteToDestination();
    }
    update();
  }

  Future<void> _refreshMapRouteToDestination() async {
    if (_destination == null) return;
    try {
      if (!_hasGpsFix) {
        await _acquireCurrentLocation();
      }
      await setDestinationMarker(_destination!);
      if (_hasGpsFix) {
        _applyInstantDistance(_initialPosition, _destination!);
        await getPolyline(from: _initialPosition, to: _destination!);
        _lastPolylineOrigin = _initialPosition;
        _lastPolylineRefresh = DateTime.now();
        await _updateTripMetrics(_initialPosition, _destination!);
        await _fitCameraToRoute();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('refreshMapRouteToDestination failed: $e');
      }
    }
  }

  /// Public: store pin for reach-restaurant GPS gate / map.
  Future<LatLng?> resolveStoreLatLng(OrderModel order) {
    return _resolveStoreLocationForOrder(order);
  }

  /// True when rider is within [radiusMeters] of the restaurant.
  Future<({bool near, double? distanceMeters, String? errorKey, Position? position})>
      checkNearRestaurant(
    OrderModel order, {
    double radiusMeters = 500,
  }) async {
    final store = await resolveStoreLatLng(order);
    if (store == null) {
      return (
        near: false,
        distanceMeters: null,
        errorKey: 'store_location_unavailable',
        position: null,
      );
    }
    final pos = await GpsLocationHelper.resolveFreshPosition();
    if (pos == null) {
      return (
        near: false,
        distanceMeters: null,
        errorKey: 'gps_required_for_accept',
        position: null,
      );
    }
    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      store.latitude,
      store.longitude,
    );
    return (
      near: distance <= radiusMeters,
      distanceMeters: distance,
      errorKey: distance <= radiusMeters ? null : 'not_near_restaurant',
      position: pos,
    );
  }

  Future<LatLng?> _resolveStoreLocationForOrder(OrderModel order) async {
    final fromShop = await _resolveStoreLocation(order.sellerInfo?.shop);
    if (fromShop != null) return fromShop;

    // Fallback: plain store_address on order payload (scheduled orders sometimes).
    final storeAddress = order.resolvedStoreAddress;
    if (storeAddress != null && storeAddress.isNotEmpty) {
      final geocoded = await _geocodeQuery([storeAddress, 'India']);
      if (geocoded != null) return geocoded;
    }
    return null;
  }

  Future<LatLng?> _resolveStoreLocation(Shop? shop) async {
    if (shop == null) return null;

    _destinationAddressLabel = _formatStoreLabel(shop);

    // Prefer server coordinates when present.
    final lat = _parseCoordinate(shop.latitude);
    final lng = _parseCoordinate(shop.longitude);
    if (_isValidCoordinatePair(lat, lng)) {
      return LatLng(lat!, lng!);
    }

    final address = shop.address?.trim();
    if (address != null && address.isNotEmpty) {
      for (final query in <List<String?>>[
        [address],
        [address, 'India'],
        if (shop.name != null && shop.name!.trim().isNotEmpty)
          [shop.name!.trim(), address, 'India'],
      ]) {
        final LatLng? geocoded = await _geocodeQuery(query);
        if (geocoded != null) return geocoded;
      }
    }

    // Last resort: shop name only (may be imprecise, better than blocking reach).
    if (shop.name != null && shop.name!.trim().isNotEmpty) {
      final LatLng? byName = await _geocodeQuery([shop.name!.trim(), 'India']);
      if (byName != null) return byName;
    }

    return null;
  }

  String _formatStoreLabel(Shop shop) {
    final parts = <String>[
      if (shop.name != null && shop.name!.trim().isNotEmpty) shop.name!.trim(),
      if (shop.address != null && shop.address!.trim().isNotEmpty)
        shop.address!.trim(),
    ];
    return parts.join(', ');
  }

  Future<LatLng?> _resolveReceiverLocation(ShippingAddress? address) async {
    if (address == null) return null;

    _destinationAddressLabel = _formatDisplayAddress(address);

    final LatLng? storedCoords = _coordsFromShipping(address);

    // Plus codes (e.g. VJ66+P2) are pin-accurate. Full "Sanjharia, …" geocode
    final LatLng? plusCoords = await _resolvePlusCodeLocation(address);
    if (plusCoords != null) {
      if (storedCoords == null) return plusCoords;
      final drift = Geolocator.distanceBetween(
        storedCoords.latitude,
        storedCoords.longitude,
        plusCoords.latitude,
        plusCoords.longitude,
      );
      // Trust plus code when saved GPS disagrees by more than a block.
      if (drift > 250) return plusCoords;
      return storedCoords;
    }

    if (storedCoords != null) return storedCoords;

    // Geocode when API did not provide usable coordinates / plus code.
    final String strictAddress = _formatStrictNavigationAddress(address);
    if (strictAddress.isNotEmpty) {
      final LatLng? geocoded = await _geocodeQuery([strictAddress]);
      if (geocoded != null) return geocoded;
    }

    final String geocodeQuery = _formatGeocodeQuery(address);
    if (geocodeQuery.isNotEmpty && geocodeQuery != strictAddress) {
      final LatLng? geocoded = await _geocodeQuery([geocodeQuery]);
      if (geocoded != null) return geocoded;
    }

    return null;
  }

  static final RegExp _plusCodeRegex = RegExp(
    r'\b([23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,3})\b',
    caseSensitive: false,
  );

  String? _extractPlusCode(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final match = _plusCodeRegex.firstMatch(text.toUpperCase());
    return match?.group(1);
  }

  Future<LatLng?> _resolvePlusCodeLocation(ShippingAddress address) async {
    final plus = _extractPlusCode(address.address) ??
        _extractPlusCode(address.area) ??
        _extractPlusCode(_formatDisplayAddress(address));
    if (plus == null) return null;

    for (final query in <List<String?>>[
      [plus, address.city, address.state, 'India'],
      [plus, address.area, address.city, 'India'],
      [plus, 'Jaipur', 'Rajasthan', 'India'],
      [plus, 'India'],
    ]) {
      final LatLng? hit = await _geocodeQuery(query);
      if (hit != null) return hit;
    }
    return null;
  }

  String? _strictNavigationAddress(ShippingAddress? address) {
    if (address == null) return null;
    final strict = _formatStrictNavigationAddress(address);
    return strict.isEmpty ? null : strict;
  }

  String _formatStrictNavigationAddress(ShippingAddress address) {
    if (address.address != null && address.address!.trim().isNotEmpty) {
      return address.address!.trim();
    }
    return _formatGeocodeQuery(address);
  }

  String? _strictStoreNavigationAddress(Shop? shop) {
    if (shop == null) return null;
    if (shop.address != null && shop.address!.trim().isNotEmpty) {
      return shop.address!.trim();
    }
    return _formatStoreLabel(shop).isEmpty ? null : _formatStoreLabel(shop);
  }

  /// Full line for in-app labels (marker snippet, receiver card).
  String _formatDisplayAddress(ShippingAddress address) {
    final parts = <String>[
      if (address.contactPersonName != null &&
          address.contactPersonName!.trim().isNotEmpty)
        address.contactPersonName!.trim(),
      if (address.address != null && address.address!.trim().isNotEmpty)
        address.address!.trim(),
      if (address.area != null && address.area!.trim().isNotEmpty)
        address.area!.trim(),
      if (address.city != null && address.city!.trim().isNotEmpty)
        address.city!.trim(),
      if (address.state != null && address.state!.trim().isNotEmpty)
        address.state!.trim(),
      if (address.zip != null && address.zip!.trim().isNotEmpty)
        address.zip!.trim(),
      if (address.country != null && address.country!.trim().isNotEmpty)
        address.country!.trim()
      else
        'India',
    ];
    return parts.join(', ');
  }

  String _formatGeocodeQuery(ShippingAddress address) {
    final parts = <String>[
      if (address.address != null && address.address!.trim().isNotEmpty)
        address.address!.trim(),
      if (address.area != null && address.area!.trim().isNotEmpty)
        address.area!.trim(),
      if (address.city != null && address.city!.trim().isNotEmpty)
        address.city!.trim(),
      if (address.state != null && address.state!.trim().isNotEmpty)
        address.state!.trim(),
      if (address.zip != null && address.zip!.trim().isNotEmpty)
        address.zip!.trim(),
      if (address.country != null && address.country!.trim().isNotEmpty)
        address.country!.trim()
      else
        'India',
    ];
    return parts.join(', ');
  }

  Future<LatLng?> _geocodeQuery(List<String?> parts) async {
    final String query = parts
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
    if (query.isEmpty) return null;
    try {
      final List<Location> locations = await locationFromAddress(query);
      for (final loc in locations) {
        final lat = loc.latitude;
        final lng = loc.longitude;
        if (_isValidCoordinatePair(lat, lng)) {
          return LatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('Geocode failed: $e');
    }
    return null;
  }

  bool _isValidCoordinate(String? lat, String? lng) {
    return _isValidCoordinatePair(_parseCoordinate(lat), _parseCoordinate(lng));
  }

  Future<bool> _ensureLocationPermission() async {
    return LocationPermissionHelper.ensureLocationReady();
  }

  void _startLiveLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 8,
      ),
    ).listen((Position position) {
      if (!GpsLocationHelper.hasValidCoordinates(
        position.latitude,
        position.longitude,
      )) {
        return;
      }
      unawaited(_onRiderMoved(position));
    });
  }

  Future<void> _onRiderMoved(Position position) async {
    _applyPosition(position);
    final LatLng riderLatLng = _initialPosition;

    if (_destination == null) {
      update();
      return;
    }

    _applyInstantDistance(riderLatLng, _destination!);
    _checkArrivalDeliverNotification(riderLatLng);
    unawaited(_refreshDrivingMetricsIfNeeded(riderLatLng));
    unawaited(_refreshPolylineIfNeeded(riderLatLng));
    unawaited(_maybeFitCamera());
    update();
  }

  void _applyInstantDistance(LatLng from, LatLng to) {
    _distance = Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000;
    if (_etaText == null && _distance != null && _distance! > 0) {
      final int approxSeconds = (_distance! / 30 * 3600).round();
      _etaText = _formatDuration(approxSeconds);
    }
  }

  void _checkArrivalDeliverNotification(LatLng riderLatLng) {
    if (_externalNavOrderId == null) return;
    if (_destination == null) return;
    if (!_isDeliverableNavStatus()) return;
    if (!_isWithinArrivalRadius(from: riderLatLng)) return;

    unawaited(_showArrivalDeliverPopup(_externalNavOrderId!));
  }

  bool _isDeliverableNavStatus() {
    var status = (_trackingOrder?.orderStatus ?? '').toLowerCase();
    if (status.isEmpty && _externalNavOrderId != null) {
      status = (_orderStatusForId(_externalNavOrderId!) ?? '').toLowerCase();
    }
    return status == 'out_for_delivery' || status == 'processing';
  }

  String? _orderStatusForId(int orderId) {
    if (!Get.isRegistered<OrderController>()) return null;
    final orders = Get.find<OrderController>();
    for (final order in orders.currentOrders) {
      if (order.id == orderId) return order.orderStatus;
    }
    for (final order in orders.scheduledCurrentOrders) {
      if (order.id == orderId) return order.orderStatus;
    }
    return null;
  }

  bool _isWithinArrivalRadius({LatLng? from}) {
    if (_destination == null) return false;
    final origin = from ?? _initialPosition;
    final meters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    return meters <= _arrivalRadiusMeters;
  }

  Future<void> _persistExternalNavOrderId(int orderId) async {
    if (orderId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.activeExternalNavOrderId, orderId);
  }

  Future<void> _persistExternalNavDestination(
    LatLng target,
    String? label,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.activeExternalNavDestLat, target.latitude);
    await prefs.setDouble(AppConstants.activeExternalNavDestLng, target.longitude);
    if (label != null && label.trim().isNotEmpty) {
      await prefs.setString(AppConstants.activeExternalNavDestLabel, label.trim());
    }
  }

  Future<void> _clearExternalNavState({int? orderId}) async {
    final prefs = await SharedPreferences.getInstance();
    final navOrderId = orderId ??
        _externalNavOrderId ??
        prefs.getInt(AppConstants.activeExternalNavOrderId) ??
        0;
    await prefs.remove(AppConstants.activeExternalNavOrderId);
    await prefs.remove(AppConstants.activeExternalNavDestLat);
    await prefs.remove(AppConstants.activeExternalNavDestLng);
    await prefs.remove(AppConstants.activeExternalNavDestLabel);
  }

  Future<void> _restoreExternalNavState() async {
    await _restoreExternalNavOrderId();
    if (_destination != null) return;
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.activeExternalNavDestLat);
    final lng = prefs.getDouble(AppConstants.activeExternalNavDestLng);
    if (lat == null || lng == null) return;
    _destination = LatLng(lat, lng);
    _destinationAddressLabel =
        prefs.getString(AppConstants.activeExternalNavDestLabel);
  }

  Future<void> _restoreExternalNavOrderId() async {
    if (_externalNavOrderId != null) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(AppConstants.activeExternalNavOrderId) ?? 0;
    if (stored > 0) {
      _externalNavOrderId = stored;
    }
  }

  Future<void> _showArrivalDeliverPopup(int orderId, {bool force = false}) async {
    if (orderId <= 0) return;
    if (_arrivalNotificationSent && !force) return;
    _arrivalNotificationSent = true;
    await AppForegroundHelper.wakeScreen();
    if (kDebugMode) {
      debugPrint('Arrival deliver popup shown for order #$orderId');
    }
  }

  void _startExternalNavWatcher() {
    _externalNavWatchTimer?.cancel();
    _externalNavWatchTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(pollExternalNavigationArrival()),
    );
  }

  void _stopExternalNavWatcher() {
    _externalNavWatchTimer?.cancel();
    _externalNavWatchTimer = null;
  }

  Future<void> pollExternalNavigationArrival() async {
    await _restoreExternalNavState();
    if (_externalNavOrderId == null || _destination == null) return;

    // Keep the return notification alive while Google Maps is in the foreground.

    if (!_isDeliverableNavStatus()) {
      final prefs = await SharedPreferences.getInstance();
      final persisted =
          prefs.getInt(AppConstants.activeExternalNavOrderId) ?? 0;
      if (persisted <= 0) {
        stopMapTracking(clearExternalNav: true);
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _checkArrivalDeliverNotification(
        LatLng(position.latitude, position.longitude),
      );
    } catch (_) {
      if (!_arrivalNotificationSent && _isWithinArrivalRadius()) {
        await _showArrivalDeliverPopup(_externalNavOrderId!);
      }
    }
  }

  /// After returning from Google Maps, re-check proximity for arrival alert.
  Future<void> checkArrivalOnResume() async {
    await _restoreExternalNavState();
    if (_externalNavOrderId == null || _destination == null) return;
    if (!_isDeliverableNavStatus()) return;
    if (_arrivalNotificationSent) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _applyPosition(position);
      if (_isWithinArrivalRadius(from: _initialPosition)) {
        await _showArrivalDeliverPopup(_externalNavOrderId!);
      }
    } catch (_) {
      if (_isWithinArrivalRadius()) {
        await _showArrivalDeliverPopup(_externalNavOrderId!);
      }
    }
  }

  Future<void> _refreshDrivingMetricsIfNeeded(LatLng riderLatLng) async {
    if (_destination == null || _isUpdatingMetrics) return;
    final DateTime now = DateTime.now();
    if (_lastDistanceApiCall != null &&
        now.difference(_lastDistanceApiCall!) < _distanceApiMinInterval) {
      return;
    }
    _isUpdatingMetrics = true;
    _lastDistanceApiCall = now;
    try {
      await _updateTripMetrics(riderLatLng, _destination!);
      update();
    } finally {
      _isUpdatingMetrics = false;
    }
  }

  Future<void> _refreshPolylineIfNeeded(LatLng riderLatLng) async {
    if (_destination == null) return;
    final DateTime now = DateTime.now();
    final LatLng? lastOrigin = _lastPolylineOrigin;
    final bool movedEnough = lastOrigin == null ||
        Geolocator.distanceBetween(
              lastOrigin.latitude,
              lastOrigin.longitude,
              riderLatLng.latitude,
              riderLatLng.longitude,
            ) >=
            _polylineRefreshMeters;
    final bool intervalElapsed = _lastPolylineRefresh == null ||
        now.difference(_lastPolylineRefresh!) >= _polylineRefreshMinInterval;

    if (!movedEnough && !intervalElapsed && polylines.isNotEmpty) return;

    _lastPolylineOrigin = riderLatLng;
    _lastPolylineRefresh = now;
    await getPolyline(from: riderLatLng, to: _destination!);
    update();
  }

  Future<void> _maybeFitCamera() async {
    if (mapController == null || _destination == null || !_hasGpsFix) return;
    final DateTime now = DateTime.now();
    if (_lastCameraFit != null &&
        now.difference(_lastCameraFit!) < const Duration(seconds: 6)) {
      return;
    }
    _lastCameraFit = now;
    await _fitCameraToRoute();
  }

  Future<void> _refreshFromCurrentLocation() async {
    await _acquireCurrentLocation();
    if (_destination != null && _hasGpsFix) {
      _applyInstantDistance(_initialPosition, _destination!);
      await getPolyline(from: _initialPosition, to: _destination!);
      await setDestinationMarker(_destination!);
      _lastPolylineOrigin = _initialPosition;
      _lastPolylineRefresh = DateTime.now();
      await _updateTripMetrics(_initialPosition, _destination!);
      await _fitCameraToRoute();
    }
  }

  Future<void> getCurrentLocation() async {
    await _refreshFromCurrentLocation();
  }

  Future<void> _updateTripMetrics(LatLng originLatLng, LatLng destinationLatLng) async {
    final Response response =
        await riderRepo.getDistanceInMeter(originLatLng, destinationLatLng);

    try {
      if (response.statusCode == 200 && response.body['status'] == 'OK') {
        final Elements? element = DistanceModel.fromJson(response.body)
            .rows
            ?.firstOrNull
            ?.elements
            ?.firstOrNull;

        final double? distanceMeters = element?.distance?.value;
        if (distanceMeters != null && distanceMeters > 0) {
          _distance = distanceMeters / 1000;
        }

        final double? durationSeconds = element?.duration?.value;
        if (durationSeconds != null && durationSeconds > 0) {
          _etaText = _formatDuration(durationSeconds.toInt());
        }
        return;
      }
    } catch (_) {}

    _applyInstantDistance(originLatLng, destinationLatLng);
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = (totalSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }

  Future<double?> getDistanceInKM(LatLng originLatLng, LatLng destinationLatLng) async {
    final Response response =
        await riderRepo.getDistanceInMeter(originLatLng, destinationLatLng);
    try {
      if (response.statusCode == 200 && response.body['status'] == 'OK') {
        return DistanceModel.fromJson(response.body)
                .rows![0]
                .elements![0]
                .distance!
                .value! /
            1000;
      }
    } catch (_) {}

    return Geolocator.distanceBetween(
          originLatLng.latitude,
          originLatLng.longitude,
          destinationLatLng.latitude,
          destinationLatLng.longitude,
        ) /
        1000;
  }

  Future<void> getPolyline({required LatLng from, required LatLng to}) async {
    final List<LatLng> polylineCoordinates = [];
    final PolylinePoints points = PolylinePoints(apiKey: AppConstants.polylineMapKey);

    try {
      final RoutesApiResponse response = await points.getRouteBetweenCoordinatesV2(
        request: RoutesApiRequest(
          origin: PointLatLng(from.latitude, from.longitude),
          destination: PointLatLng(to.latitude, to.longitude),
          travelMode: TravelMode.driving,
        ),
      );

      if (response.routes.isNotEmpty) {
        final route = response.routes.first;
        final List<PointLatLng>? routePoints = route.polylinePoints;
        if (routePoints != null && routePoints.isNotEmpty) {
          polylineCoordinates.addAll(
            routePoints.map((p) => LatLng(p.latitude, p.longitude)),
          );
        } else if (route.polylineEncoded != null && route.polylineEncoded!.isNotEmpty) {
          final decoded = PolylinePoints.decodePolyline(route.polylineEncoded!);
          polylineCoordinates.addAll(
            decoded.map((p) => LatLng(p.latitude, p.longitude)),
          );
        }
      }
    } catch (e) {
      debugPrint('getPolyline: $e');
    }

    if (polylineCoordinates.isEmpty) {
      polylineCoordinates.addAll([from, to]);
    }

    _addPolyLine(polylineCoordinates);
  }

  void _addPolyLine(List<LatLng> polylineCoordinates) {
    polylines.clear();
    if (polylineCoordinates.isEmpty) return;

    polylines[const PolylineId('route')] = Polyline(
      polylineId: const PolylineId('route'),
      points: polylineCoordinates,
      width: 5,
      color: Theme.of(Get.context!).primaryColor,
    );
    update();
  }

  Future<void> setDestinationMarker(LatLng to) async {
    _customMarkers
      ..clear()
      ..add(
        MarkerData(
          marker: Marker(
            markerId: const MarkerId('destination'),
            position: to,
            infoWindow: InfoWindow(
              title: 'receiver'.tr,
              snippet: _destinationAddressLabel,
            ),
          ),
          child: Image.asset(Images.destinationIcon, height: 44, width: 44),
        ),
      );
    update();
  }

  Future<void> _fitCameraToRoute() async {
    if (mapController == null) return;

    try {
      if (_destination != null && _hasGpsFix) {
        final LatLngBounds bounds = _boundsFrom(_initialPosition, _destination!);
        await mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
        return;
      }
      if (_hasGpsFix) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _initialPosition, zoom: 16),
          ),
        );
        return;
      }
      if (_destination != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _destination!, zoom: 14),
          ),
        );
      }
    } catch (e) {
      debugPrint('fitCamera: $e');
    }
  }

  LatLngBounds _boundsFrom(LatLng a, LatLng b) {
    const double pad = 0.004;
    return LatLngBounds(
      southwest: LatLng(
        (a.latitude < b.latitude ? a.latitude : b.latitude) - pad,
        (a.longitude < b.longitude ? a.longitude : b.longitude) - pad,
      ),
      northeast: LatLng(
        (a.latitude > b.latitude ? a.latitude : b.latitude) + pad,
        (a.longitude > b.longitude ? a.longitude : b.longitude) + pad,
      ),
    );
  }
}
