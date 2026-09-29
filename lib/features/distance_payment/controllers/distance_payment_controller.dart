import 'package:get/get.dart';
import 'package:quiksee/data/api/api_checker.dart';
import 'package:quiksee/features/distance_payment/domain/models/delivery_distance_info_model.dart';
import 'package:quiksee/features/distance_payment/domain/models/distance_shipping_config_model.dart';
import 'package:quiksee/features/distance_payment/domain/repositories/distance_payment_repository.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';

class DistancePaymentController extends GetxController implements GetxService {
  final DistancePaymentRepository distancePaymentRepository;

  DistancePaymentController({required this.distancePaymentRepository});

  DistanceShippingConfigModel? _config;
  DistanceShippingConfigModel? get config => _config;
  bool get isDistanceShippingEnabled => _config?.enabled == true;

  final Map<int, DeliveryDistanceInfo> _orderPayments = {};
  DeliveryDistanceInfo? orderPaymentFor(int? orderId) =>
      orderId == null ? null : _orderPayments[orderId];

  bool _loadingConfig = false;
  bool get loadingConfig => _loadingConfig;

  final Map<int, bool> _loadingOrderPayment = {};

  Future<void> loadConfig({bool silent = false}) async {
    if (_loadingConfig) return;
    _loadingConfig = true;
    if (!silent) update();

    final response = await distancePaymentRepository.getDistanceShippingConfig();
    if (response.statusCode == 200 && response.body != null) {
      _config = DistanceShippingConfigModel.fromJson(response.body);
    } else if (!silent) {
      ApiChecker.checkApi(response);
    }

    _loadingConfig = false;
    update();
  }

  Future<DeliveryDistanceInfo?> fetchOrderPayment(
    int orderId, {
    bool silentOnNotFound = false,
  }) async {
    _loadingOrderPayment[orderId] = true;
    update();

    final response =
        await distancePaymentRepository.getOrderDistancePayment(orderId);
    DeliveryDistanceInfo? info;
    if (response.statusCode == 200 && response.body != null) {
      info = DeliveryDistanceInfo.fromJson(response.body);
      _orderPayments[orderId] = info;
      _syncOrderDetailsCollectAmount(orderId, info);
    } else if (!(silentOnNotFound && response.statusCode == 404)) {
      ApiChecker.checkApi(response);
    }

    _loadingOrderPayment[orderId] = false;
    update();
    return info;
  }

  void _syncOrderDetailsCollectAmount(int orderId, DeliveryDistanceInfo info) {
    if (!Get.isRegistered<OrderDetailsController>()) return;
    final details = Get.find<OrderDetailsController>();
    final detailOrder = details.orderDetails?.isNotEmpty == true
        ? details.orderDetails!.first.orderModel
        : null;
    if (detailOrder != null && detailOrder.id != null && detailOrder.id != orderId) {
      return;
    }
    details.syncCollectAmount(
      order: detailOrder ?? OrderModel(id: orderId),
      distanceInfo: info,
    );
  }

  bool isLoadingOrderPayment(int? orderId) =>
      orderId != null && (_loadingOrderPayment[orderId] == true);

  DeliveryDistanceInfo? resolveEarningInfo(OrderModel? order) {
    if (order == null) return null;
    if (order.deliveryDistanceInfo?.hasDistanceEarning == true) {
      return order.deliveryDistanceInfo;
    }
    final orderId = order.id;
    if (orderId == null) return null;
    return _orderPayments[orderId];
  }

  double resolveDeliveryCharge(OrderModel? order) {
    if (order == null) return 0;
    final info = resolveEarningInfo(order);
    if (info != null && info.displayEarning > 0) {
      return info.displayEarning;
    }
    if (isDistanceShippingEnabled) {
      final cached = order.id != null ? _orderPayments[order.id!] : null;
      if (cached?.displayEarning != null && cached!.displayEarning > 0) {
        return cached.displayEarning;
      }
    }
    return order.deliveryManCharge ?? 0;
  }

  double resolveDisplayEarning(OrderModel? order) {
    if (order == null) return 0;
    if ((order.deliveryManTotalEarning ?? 0) > 0) {
      return order.deliveryManTotalEarning!;
    }
    final info = resolveEarningInfo(order);
    if (info != null && info.displayEarning > 0) {
      return info.displayEarning;
    }
    final distancePay = info?.displayDistancePay ??
        (order.deliveryManCharge ?? 0);
    final tip = order.deliveryManTip ?? info?.deliveryManTip ?? 0;
    final incentive = order.extraIncentiveRiderShare ??
        info?.extraIncentiveRiderShare ??
        0;
    return distancePay + tip + incentive;
  }

  bool shouldShowDistanceBreakdown(OrderModel? order) {
    if (!isDistanceShippingEnabled) return false;
    final info = resolveEarningInfo(order);
    return info?.isDistanceBasedDelivery == true;
  }

  Future<DeliveryDistanceInfo?> estimateOrderPay(int orderId) async {
    final response =
        await distancePaymentRepository.estimateDeliveryPay(orderId: orderId);
    if (response.statusCode == 200 && response.body != null) {
      final body = response.body as Map<String, dynamic>;
      if (body['estimate_available'] == false) return null;
      final info = DeliveryDistanceInfo.fromJson(body);
      if (info.displayEarning > 0) {
        _orderPayments[orderId] = info;
        update();
      }
      return info;
    }
    return null;
  }

  Future<void> enrichWalletOrderEarnings(List<int> orderIds) async {
    if (_config == null) {
      await loadConfig(silent: true);
    }
    if (!isDistanceShippingEnabled || orderIds.isEmpty) return;

    const batchSize = 4;
    for (var i = 0; i < orderIds.length; i += batchSize) {
      final batch = orderIds.skip(i).take(batchSize);
      await Future.wait(batch.map((orderId) async {
        final cached = _orderPayments[orderId];
        if (cached != null &&
            (cached.deliveryManEarning ?? 0) > 0 &&
            cached.paymentStatus != 'not_applicable') {
          return;
        }
        final payment = await fetchOrderPayment(orderId);
        if (payment != null &&
            (payment.deliveryManEarning ?? 0) > 0 &&
            payment.paymentStatus != 'not_applicable') {
          return;
        }
        await estimateOrderPay(orderId);
      }));
    }
  }

  DeliveryDistanceInfo? earningInfoForWalletOrder(int? orderId) {
    if (orderId == null) return null;
    return _orderPayments[orderId];
  }

  Future<void> prefetchEarningsForOrders(List<OrderModel> orders) async {
    if (_config == null) {
      await loadConfig(silent: true);
    }
    if (!isDistanceShippingEnabled) return;
    int fetched = 0;
    for (final order in orders) {
      if (fetched >= 3) break;
      final orderId = order.id;
      if (orderId == null) continue;
      if (order.deliveryDistanceInfo?.hasDistanceEarning == true) continue;
      if (_orderPayments.containsKey(orderId)) continue;
      await estimateOrderPay(orderId);
      fetched++;
    }
  }
}
