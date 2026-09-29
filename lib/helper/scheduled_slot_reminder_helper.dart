import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/order/domain/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduledSlotReminderHelper {
  ScheduledSlotReminderHelper._();

  static const _startedPhase = 'started';
  static const _advanceOffsetsMinutes = [30, 15];
  static const _pollWindowMinutes = 2;

  static String _prefKey(int orderId, String phase) =>
      'sched_slot_reminder_${orderId}_$phase';

  static String _advancePhase(int minutesBefore) => 'advance_$minutesBefore';

  static bool _isActiveScheduledOrder(OrderModel order) {
    final status = order.orderStatus?.toLowerCase() ?? '';
    const inactive = {
      'delivered',
      'canceled',
      'cancelled',
      'return',
      'returned',
      'failed',
    };
    return !inactive.contains(status);
  }

  static int? _resolveMinutesUntil(OrderModel order) {
    final apiMinutes = order.scheduledDelivery?.minutesUntilSlot;
    if (apiMinutes != null) return apiMinutes;
    return order.minutesUntilScheduledSlot;
  }

  static Future<void> syncOrders({
    required List<OrderModel> orders,
  }) async {
    if (orders.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    for (final order in orders) {
      final orderId = order.id;
      if (orderId == null || !_isActiveScheduledOrder(order)) continue;
      if (!order.isScheduledDeliveryOrder) continue;

      final slotStart = order.scheduledSlotStartAt;
      if (slotStart == null) continue;

      final minutesUntil = _resolveMinutesUntil(order);
      if (minutesUntil == null) continue;

      final slotLabel =
          order.scheduledDeliveryDisplayLabel ?? slotStart.toString();

      if (minutesUntil < -15) {
        await clearForOrder(orderId);
        continue;
      }

      if (minutesUntil <= 0) {
        if (prefs.getBool(_prefKey(orderId, _startedPhase)) == true) {
          continue;
        }
        await _notify(
          orderId: orderId,
          phase: _startedPhase,
          title: 'scheduled_slot_started_title'.tr,
          body: 'scheduled_slot_started_body'.trParams({
            'order': '$orderId',
            'slot': slotLabel,
          }),
          urgent: true,
        );
        await prefs.setBool(_prefKey(orderId, _startedPhase), true);
        continue;
      }

      for (final minutesBefore in _advanceOffsetsMinutes) {
        final phase = _advancePhase(minutesBefore);
        if (prefs.getBool(_prefKey(orderId, phase)) == true) {
          continue;
        }

        final notifyAt = slotStart.subtract(Duration(minutes: minutesBefore));
        final untilNotifyMinutes =
            notifyAt.difference(DateTime.now()).inMinutes;

        if (untilNotifyMinutes > 1) {
          continue;
        }

        final windowLow = minutesBefore - _pollWindowMinutes;
        final windowHigh = minutesBefore + _pollWindowMinutes;
        if (minutesUntil >= windowLow && minutesUntil <= windowHigh) {
          await _notifyAdvance(
            orderId: orderId,
            phase: phase,
            minutesBefore: minutesBefore,
            slotLabel: slotLabel,
          );
          await prefs.setBool(_prefKey(orderId, phase), true);
        }
      }
    }
  }

  @Deprecated('Use syncOrders')
  static Future<void> checkOrders({
    required List<OrderModel> orders,
    required int leadTimeMinutes,
  }) =>
      syncOrders(orders: orders);

  static Future<void> _notifyAdvance({
    required int orderId,
    required String phase,
    required int minutesBefore,
    required String slotLabel,
  }) {
    final copy = _advanceCopy(
      orderId: orderId,
      minutesBefore: minutesBefore,
      slotLabel: slotLabel,
    );
    return _notify(
      orderId: orderId,
      phase: phase,
      title: copy.title,
      body: copy.body,
      urgent: true,
    );
  }

  static ({String title, String body}) _advanceCopy({
    required int orderId,
    required int minutesBefore,
    required String slotLabel,
  }) {
    if (minutesBefore <= 15) {
      return (
        title: 'scheduled_slot_15min_title'.tr,
        body: 'scheduled_slot_15min_body'.trParams({
          'order': '$orderId',
          'minutes': '$minutesBefore',
          'slot': slotLabel,
        }),
      );
    }
    return (
      title: 'scheduled_slot_30min_title'.tr,
      body: 'scheduled_slot_30min_body'.trParams({
        'order': '$orderId',
        'minutes': '$minutesBefore',
        'slot': slotLabel,
      }),
    );
  }

  static Future<void> _notify({
    required int orderId,
    required String phase,
    required String title,
    required String body,
    required bool urgent,
  }) async {
    if (kDebugMode) {
      debugPrint('Scheduled slot reminder [$phase] order #$orderId: $body');
    }
  }

  static Future<void> clearForOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final minutesBefore in _advanceOffsetsMinutes) {
      await prefs.remove(_prefKey(orderId, _advancePhase(minutesBefore)));
    }
    await prefs.remove(_prefKey(orderId, _startedPhase));
  }
}
