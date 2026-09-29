import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:quiksee_vendor_app/helper/app_foreground_helper.dart';
import 'package:quiksee_vendor_app/helper/app_launch_helper.dart';
import 'package:quiksee_vendor_app/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class NewOrderAlertHelper {
  static final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  static Timer? _watchdogTimer;
  static final Map<int, Timer> _retryTimers = <int, Timer>{};
  static bool _active = false;
  static int? _playingOrderId;

  static const Duration maxRingDuration = Duration(hours: 6);

  static bool get isActive => _active;

  static Future<bool> _shouldAbortStart(int? orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      try {
        await prefs.reload();
      } catch (_) {}
      final now = DateTime.now().millisecondsSinceEpoch;

      if (orderId != null && orderId > 0) {
        final acked =
            prefs.getStringList(AppConstants.acknowledgedAlertOrderIds) ??
                const <String>[];
        if (acked.contains(orderId.toString())) return true;

      } else {

        int killAllUntil = 0;
        try {
          killAllUntil =
              prefs.getInt(AppConstants.kitchenRingKillAllUntilMs) ?? 0;
        } catch (_) {
          await prefs.remove(AppConstants.kitchenRingKillAllUntilMs);
          killAllUntil = 0;
        }
        if (killAllUntil > now) return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<int> _killAllRemainingMs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int killAllUntil = 0;
      try {
        killAllUntil =
            prefs.getInt(AppConstants.kitchenRingKillAllUntilMs) ?? 0;
      } catch (_) {
        await prefs.remove(AppConstants.kitchenRingKillAllUntilMs);
        return 0;
      }
      final left = killAllUntil - DateTime.now().millisecondsSinceEpoch;
      return left > 0 ? left : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> start({Duration? maxDuration, int? orderId}) async {
    if (kIsWeb) return false;

    if (orderId != null && orderId > 0) {
      await _clearKillAllForNewOrder(orderId);
    }

    if (await _shouldAbortStart(orderId)) {

      return false;
    }

    if (orderId != null && orderId > 0) {
      final waitMs = await _killAllRemainingMs();
      if (waitMs > 0) {
        await _clearKillAllForNewOrder(orderId);
      }
    }

    if (await _shouldAbortStart(orderId)) {
      return false;
    }

    if (_active &&
        _playingOrderId != null &&
        _playingOrderId! > 0 &&
        orderId != null &&
        orderId > 0 &&
        _playingOrderId != orderId) {
      return false;
    }

    _active = true;
    _playingOrderId = orderId;
    _startWatchdog();

    await AppForegroundHelper.startNativeOrderAlert(orderId: orderId);

    if (await _shouldAbortStart(orderId)) {

      await stop(force: true, orderId: orderId);
      return false;
    }
    return true;
  }

  static void scheduleRetryStart({
    required int orderId,
    int delayMs = 1200,
    int attempt = 0,
  }) {
    if (orderId <= 0) return;
    _retryTimers[orderId]?.cancel();
    _retryTimers[orderId] = Timer(Duration(milliseconds: delayMs), () async {
      _retryTimers.remove(orderId);
      if (await _shouldAbortStart(orderId)) return;
      if (_active && _playingOrderId != null && _playingOrderId != orderId) {
        return;
      }
      if (_active && _playingOrderId == orderId) return;
      final started = await start(orderId: orderId);
      if (started) return;

      if (attempt >= 4) return;
      final nextDelay = (delayMs * 1.6).round().clamp(1200, 4000);
      scheduleRetryStart(
        orderId: orderId,
        delayMs: nextDelay,
        attempt: attempt + 1,
      );
    });
  }

  static void cancelRetry(int? orderId) {
    if (orderId == null || orderId <= 0) return;
    _retryTimers.remove(orderId)?.cancel();
  }

  static Future<void> _clearKillAllForNewOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int silencedId = 0;
      try {
        silencedId =
            prefs.getInt(AppConstants.kitchenRingSilencedOrderId) ?? 0;
      } catch (_) {
        await prefs.remove(AppConstants.kitchenRingSilencedOrderId);
        await prefs.remove(AppConstants.kitchenRingKillAllUntilMs);
        return;
      }

      if (silencedId == orderId) return;
      await prefs.remove(AppConstants.kitchenRingKillAllUntilMs);
    } catch (_) {}
  }

  static void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (!_active) return;
      if (await _shouldAbortStart(_playingOrderId)) {
        await stop(force: true, orderId: _playingOrderId);
      }
    });
  }

  static Future<void> stop({bool force = false, int? orderId}) async {
    if (!force) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final kitchenId = prefs.getInt(AppConstants.activeRingOrderId) ?? 0;
        if (kitchenId > 0) return;
      } catch (_) {}
    }

    if (orderId != null &&
        orderId > 0 &&
        _playingOrderId != null &&
        _playingOrderId! > 0 &&
        _playingOrderId != orderId) {
      return;
    }

    _active = false;
    _playingOrderId = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    try {
      await Vibration.cancel();
    } catch (_) {}

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _ringtonePlayer.stop();
      } catch (_) {}
      try {
        await FlutterRingtonePlayer().stop();
      } catch (_) {}
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
    }

    await AppForegroundHelper.stopNativeOrderAlert(orderId: orderId);
    await AppLaunchHelper.stopOrderAlert(orderId: orderId);
  }

  static bool isPlayingOrder(int? orderId) {
    if (orderId == null || orderId <= 0) return false;
    return _active && _playingOrderId == orderId;
  }

  static int get playingOrderId => _playingOrderId ?? 0;
}
