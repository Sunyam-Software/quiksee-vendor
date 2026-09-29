import 'package:quiksee/features/order/domain/models/order_model.dart';

class CombinedOrderHelper {
  static bool _isRealGroup(String? groupId) {
    final value = groupId?.trim() ?? '';
    return value.isNotEmpty && value != 'def-order-group';
  }

  static List<OrderModel> groupOrders(List<OrderModel> orders) {
    if (orders.isEmpty) return orders;

    if (orders.any((order) => order.isCombinedCheckout)) {
      return List<OrderModel>.from(orders);
    }

    final grouped = <String, List<OrderModel>>{};
    final singles = <OrderModel>[];

    for (final order in orders) {
      if (!_isRealGroup(order.orderGroupId)) {
        singles.add(order);
        continue;
      }

      final key =
          '${order.orderGroupId}|${order.customerId ?? 0}|${order.isGuest == true ? 1 : 0}';
      grouped.putIfAbsent(key, () => []).add(order);
    }

    final result = <OrderModel>[];

    for (final siblings in grouped.values) {
      if (siblings.length <= 1) {
        result.add(siblings.first);
        continue;
      }
      result.add(OrderModel.mergeCombinedGroup(siblings));
    }

    result.addAll(singles);
    result.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return result;
  }
}
