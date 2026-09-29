import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/distance_payment/controllers/distance_payment_controller.dart';
import 'package:quiksee/features/order/controllers/order_controller.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:quiksee/features/order/widgets/new_order_action_buttons_widget.dart';
import 'package:quiksee/features/order_details/controllers/order_details_controller.dart';
import 'package:quiksee/helper/price_converter.dart';
import 'package:quiksee/utill/dimensions.dart';
import 'package:quiksee/utill/styles.dart';

class NewOrderActionSheet extends StatefulWidget {
  final int orderId;

  const NewOrderActionSheet({super.key, required this.orderId});

  @override
  State<NewOrderActionSheet> createState() => _NewOrderActionSheetState();
}

class _NewOrderActionSheetState extends State<NewOrderActionSheet> {
  static const Color _brandGreen = Color(0xFF0F6B2D);
  static const Color _brandGold = Color(0xFFD4A62A);

  OrderModel? _order;
  String? _productSummary;
  bool _detailsLoading = true;

  @override
  void initState() {
    super.initState();
    _hydrateFromCache();
    _loadDetailsInBackground();
  }

  void _hydrateFromCache() {
    final cached = Get.find<OrderController>().currentOrders
        .cast<OrderModel?>()
        .firstWhere((o) => o?.id == widget.orderId, orElse: () => null);
    if (cached != null) {
      _order = cached;
    }
  }

  Future<void> _loadDetailsInBackground() async {
    final orderController = Get.find<OrderController>();
    await orderController.refreshCurrentOrdersOnly(force: true, promptAccept: false);
    if (!mounted) return;
    _order = orderController.currentOrders
        .cast<OrderModel?>()
        .firstWhere((o) => o?.id == widget.orderId, orElse: () => null);

    if (_order == null) {
      try {
        final details = await Get.find<OrderDetailsController>()
            .getOrderDetails(widget.orderId.toString(), context, silent: true);
        if (details != null && details.isNotEmpty) {
          _order = details.first.orderModel;
          _productSummary = details
              .map((d) =>
                  '${d.productDetails?.name ?? ''}${d.qty != null ? ' (${d.qty})' : ''}')
              .where((s) => s.trim().isNotEmpty)
              .join(', ');
        }
      } catch (_) {}
    }

    if (_order == null) {
      _order = await orderController.resolveOrderForAction(widget.orderId);
    }

    if (_order != null && Get.isRegistered<DistancePaymentController>()) {
      Get.find<DistancePaymentController>()
          .fetchOrderPayment(widget.orderId, silentOnNotFound: true)
          .then((_) {
        if (mounted) setState(() {});
      });
    }

    if (mounted) {
      setState(() {
        _detailsLoading = false;
      });
    }
  }

  String _addressLine(OrderModel? order) {
    final addr = order?.shippingAddress;
    if (addr == null) return '';
    final parts = <String>[
      if (addr.address != null && addr.address!.isNotEmpty) addr.address!,
      if (addr.city != null && addr.city!.isNotEmpty) addr.city!,
      if (addr.zip != null && addr.zip!.isNotEmpty) addr.zip!,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final distanceController = Get.isRegistered<DistancePaymentController>()
        ? Get.find<DistancePaymentController>()
        : null;
    final earningInfo = distanceController?.resolveEarningInfo(_order);
    final earning = earningInfo?.displayEarning ??
        _order?.effectiveDeliveryEarning ??
        0.0;
    final distanceKm = earningInfo?.displayDistance ?? 0.0;

    return Container(
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.paddingSizeDefault),
        ),
        border: Border.all(color: _brandGold, width: 1.5),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active,
                    color: _brandGreen, size: Dimensions.iconSizeDefault),
                SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text(
                    '${'new_order'.tr} #${widget.orderId}',
                    style: rubikBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: _brandGreen,
                    ),
                  ),
                ),
                GetBuilder<OrderController>(builder: (orderController) {
                  final seconds = orderController.newOrderSecondsRemaining;
                  if (seconds == null) return const SizedBox.shrink();
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      color: seconds <= 10
                          ? Colors.red.withValues(alpha: .12)
                          : _brandGold.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${seconds}s',
                      style: rubikMedium.copyWith(
                        color: seconds <= 10 ? Colors.red : _brandGreen,
                      ),
                    ),
                  );
                }),
              ],
            ),
            if (_detailsLoading && _order == null)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeSmall,
                ),
                child: Text(
                  'loading_order_details'.tr,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            if (_productSummary != null && _productSummary!.isNotEmpty)
              _infoRow(Icons.shopping_bag_outlined, _productSummary!),
            if (_order?.sellerInfo?.shop?.name != null)
              _infoRow(Icons.store, _order!.sellerInfo!.shop!.name!),
            if (_addressLine(_order).isNotEmpty)
              _infoRow(Icons.location_on_outlined, _addressLine(_order)),
            if (earning > 0)
              _infoRow(
                Icons.payments_outlined,
                '${'your_earning'.tr}: ${PriceConverter.convertPrice(earning)}',
              ),
            if (distanceKm > 0)
              _infoRow(
                Icons.route,
                '${distanceKm.toStringAsFixed(1)} ${'km'.tr}',
              ),
            SizedBox(height: Dimensions.paddingSizeDefault),
            NewOrderActionButtonsWidget(orderId: widget.orderId),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: Dimensions.iconSizeSmall, color: _brandGreen),
          SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              text,
              style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}
