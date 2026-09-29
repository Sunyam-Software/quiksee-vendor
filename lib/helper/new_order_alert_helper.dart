import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:quiksee/features/splash/controllers/splash_controller.dart';
import 'package:quiksee/helper/app_foreground_helper.dart';
import 'package:quiksee/utill/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Transfer (`loopUntilStopped`): **native FGS + MediaPlayer owns audio**.
class NewOrderAlertHelper {
  static final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  static Timer? _vibrateTimer;
  static Timer? _autoStopTimer;
  static Timer? _keepAliveTimer;
  static Timer? _keepAliveKickOnce;
  static bool _active = false;
  static bool _timeoutFired = false;
  static bool _loopUntilStopped = false;
  static bool _flutterRingOn = false;
  static int _ringPlayGen = 0;
  static VoidCallback? _onTimeout;
  static const int maxAlertSeconds = 30;
  /// Assignment/transfer: ring until Accept/Deny. Hard safety cap (4h).
  static const int maxLoopUntilStoppedSeconds = 14400;

  static bool _soundEnabled() {
    if (Get.isRegistered<SplashController>()) {
      return Get.find<SplashController>().notificationSound() ?? true;
    }
    return true;
  }

  static bool get isActive => _active;
  static DateTime? _mutedUntil;
  static int _stopGeneration = 0;

  static bool get _onMainIsolate =>
      PlatformDispatcher.instance.implicitView != null;

  /// Transfer / long-ring: native owns sound (no Flutter ringtone fight).
  static bool get _nativeOwnsAudio =>
      _loopUntilStopped && !kIsWeb && Platform.isAndroid;

  /// True when this isolate or the FCM background isolate is playing an alert.
  static Future<bool> isAlertLive() async {
    if (await isMuted()) return false;
    if (_active) return true;
    final prefs = await SharedPreferences.getInstance();
    final startedAt = prefs.getInt(AppConstants.newOrderAlertActiveAt);
    if (startedAt == null) return false;
    final windowSec = maxLoopUntilStoppedSeconds + 5;
    return DateTime.now().millisecondsSinceEpoch - startedAt <
        windowSec * 1000;
  }

  /// Blocks new alert sounds (Flutter + native FCM) after accept/reject.
  static Future<void> muteFor(Duration duration, {int? offerId}) async {
    final until = DateTime.now().add(duration);
    await _persistMuteUntil(until, offerId: offerId);
    _mutedUntil = until;
  }

  static Future<void> clearMute({bool clearOfferId = true}) async {
    _mutedUntil = null;
    await _clearPersistedMute(clearOfferId: clearOfferId);
  }

  /// After Accept, mute blocks re-ring of the *same* offer. A new transfer /
  /// assignment offer_id must clear that mute or the next ring dies early.
  static Future<bool> clearMuteIfNewOffer(int? offerId) async {
    if (offerId == null || offerId <= 0) {
      if (await isMuted()) {
        await clearMute();
        return true;
      }
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      try {
        await prefs.reload();
      } catch (_) {}
      final mutedOffer =
          prefs.getString(AppConstants.newOrderAlertMutedOfferId);
      final stillMuted = await isMuted();
      if (!stillMuted) return false;
      if (mutedOffer != null && mutedOffer == offerId.toString()) {
        return false;
      }
      await clearMute();
      return true;
    } catch (_) {
      await clearMute();
      return true;
    }
  }

  static Future<bool> isMuted() async {
    // while this isolate can still hold a stale _mutedUntil (post-Accept).
    try {
      final prefs = await SharedPreferences.getInstance();
      try {
        await prefs.reload();
      } catch (_) {}
      final ms = prefs.getInt(AppConstants.newOrderAlertMutedUntil);
      if (ms == null) {
        _mutedUntil = null;
        return false;
      }
      final until = DateTime.fromMillisecondsSinceEpoch(ms);
      if (DateTime.now().isBefore(until)) {
        _mutedUntil = until;
        return true;
      }
      _mutedUntil = null;
      await prefs.remove(AppConstants.newOrderAlertMutedUntil);
      await prefs.remove(AppConstants.newOrderAlertMutedOfferId);
      return false;
    } catch (_) {
      final local = _mutedUntil;
      if (local != null && DateTime.now().isBefore(local)) return true;
      return false;
    }
  }

  static Future<void> _persistMuteUntil(DateTime until, {int? offerId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        AppConstants.newOrderAlertMutedUntil,
        until.millisecondsSinceEpoch,
      );
      if (offerId != null && offerId > 0) {
        await prefs.setString(
          AppConstants.newOrderAlertMutedOfferId,
          offerId.toString(),
        );
      } else {
        await prefs.remove(AppConstants.newOrderAlertMutedOfferId);
      }
    } catch (_) {}
  }

  static Future<void> _clearPersistedMute({bool clearOfferId = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.newOrderAlertMutedUntil);
      if (clearOfferId) {
        await prefs.remove(AppConstants.newOrderAlertMutedOfferId);
      }
    } catch (_) {}
  }

  static Future<void> _markPersistedActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      AppConstants.newOrderAlertActiveAt,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> _clearPersistedActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.newOrderAlertActiveAt);
  }

  static Future<void> _requestNativeAlertStop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.nativeAlertStopRequested, true);
  }

  static Future<void> start({
    int? maxSeconds,
    VoidCallback? onTimeout,
    bool forceRestart = false,
    bool ignoreMute = false,
    bool loopUntilStopped = false,
  }) async {
    if (kIsWeb) return;

    if (!ignoreMute && await isMuted()) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.nativeAlertStopRequested, false);
    } catch (_) {}

    _loopUntilStopped = loopUntilStopped;
    final int seconds = loopUntilStopped
        ? maxLoopUntilStoppedSeconds
        : (maxSeconds ?? maxAlertSeconds).clamp(1, 300);

    if (_active && !forceRestart) {
      if (onTimeout != null) {
        _onTimeout = onTimeout;
      }
      if (_soundEnabled()) {
        await _kickSound(hard: false);
      }
      if (_vibrateTimer == null) {
        unawaited(_vibrate());
        _vibrateTimer =
            Timer.periodic(const Duration(seconds: 2), (_) => _vibrate());
      }
      _scheduleStopOrKeepAlive(seconds);
      return;
    }

    final int startGen = _stopGeneration;

    if (!kIsWeb && Platform.isAndroid && !_onMainIsolate) {
      if (startGen != _stopGeneration) return;
      if (await isAlertLive()) return;
      if (startGen != _stopGeneration) return;
      _active = true;
      await _markPersistedActive();
      if (startGen != _stopGeneration) return;
      _scheduleStopOrKeepAlive(seconds);
      return;
    }

    final nativeAlreadyLive = await isAlertLive();
    if (startGen != _stopGeneration) return;
    if (nativeAlreadyLive && !forceRestart) {
      _onTimeout = onTimeout;
      _active = true;
      _scheduleStopOrKeepAlive(seconds);
      if (_soundEnabled()) {
        await _kickSound(hard: false);
      }
      _vibrateTimer?.cancel();
      _vibrateTimer =
          Timer.periodic(const Duration(seconds: 2), (_) => _vibrate());
      return;
    }

    // Assignment short-ring only: stop-then-restart. Transfer must never
    // stop native (that caused the ~1s chirp then silence).
    if (!loopUntilStopped && (!nativeAlreadyLive || forceRestart)) {
      await stop(
        clearPersisted: false,
        bumpGeneration: false,
        stopNative: !nativeAlreadyLive,
      );
    }
    if (startGen != _stopGeneration) return;

    _onTimeout = onTimeout;
    _timeoutFired = false;
    _active = true;

    await _vibrate();
    unawaited(AppForegroundHelper.wakeScreen());

    if (_soundEnabled()) {
      if (startGen != _stopGeneration) return;
      await _kickSound(hard: true);
    }

    await _markPersistedActive();
    _scheduleStopOrKeepAlive(seconds);
    if (startGen != _stopGeneration) {
      await stop(bumpGeneration: false);
      return;
    }

    _vibrateTimer?.cancel();
    _vibrateTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _vibrate());
  }

  /// Transfer → native FGS only. Assignment → Flutter + native soft assist.
  static Future<void> _kickSound({required bool hard}) async {
    if (!_soundEnabled()) return;
    if (_nativeOwnsAudio) {
      if (_onMainIsolate) {
        await AppForegroundHelper.startNativeAlert(force: hard);
      }
      return;
    }
    unawaited(_playFlutterRingtone(restart: hard));
    if (!kIsWeb && Platform.isAndroid && _onMainIsolate) {
      unawaited(AppForegroundHelper.startNativeAlert(force: hard));
    }
  }

  static void _scheduleStopOrKeepAlive(int seconds) {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _keepAliveKickOnce?.cancel();
    _keepAliveKickOnce = null;
    if (_loopUntilStopped) {
      _autoStopTimer = Timer(Duration(seconds: maxLoopUntilStoppedSeconds), () {
        unawaited(_fireTimeout());
      });

      // Native MediaPlayer + FGS owns the ring. KeepAlive only re-asserts
      var tick = 0;
      void keepAliveKick({required bool hard}) {
        if (!_active || !_loopUntilStopped) return;
        unawaited(() async {
          if (await isMuted()) {
            await stop();
            return;
          }
          if (!_active || !_loopUntilStopped) return;
          await _markPersistedActive();
          await _kickSound(hard: hard);
          if (_vibrateTimer == null) {
            unawaited(_vibrate());
            _vibrateTimer =
                Timer.periodic(const Duration(seconds: 2), (_) => _vibrate());
          }
        }());
      }

      _keepAliveKickOnce = Timer(const Duration(milliseconds: 800), () {
        keepAliveKick(hard: true);
      });
      _keepAliveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        tick++;
        keepAliveKick(hard: tick % 3 == 0);
      });
      return;
    }
    _autoStopTimer = Timer(Duration(seconds: seconds), () {
      unawaited(_fireTimeout());
    });
  }

  static Future<void> _playFlutterRingtone({bool restart = false}) async {
    final int gen = ++_ringPlayGen;
    if (restart) {
      _flutterRingOn = false;
      try {
        await _ringtonePlayer.stop();
      } catch (_) {}
      try {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } catch (_) {}
    }
    if (gen != _ringPlayGen) return;
    _flutterRingOn = true;
    try {
      await _ringtonePlayer.play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.alarm,
        looping: true,
        asAlarm: true,
        volume: 1.0,
      );
      return;
    } catch (_) {}
    if (gen != _ringPlayGen) return;
    try {
      await _ringtonePlayer.playRingtone(
        looping: true,
        asAlarm: true,
        volume: 1.0,
      );
      return;
    } catch (_) {}
    if (gen != _ringPlayGen) return;
    try {
      await _ringtonePlayer.play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        asAlarm: true,
        volume: 1.0,
      );
    } catch (_) {
      if (gen == _ringPlayGen) {
        _flutterRingOn = false;
      }
    }
  }

  static Future<void> _fireTimeout() async {
    if (_timeoutFired) return;
    _timeoutFired = true;
    final callback = _onTimeout;
    _onTimeout = null;
    await stop();
    callback?.call();
  }

  static Future<void> stop({
    bool clearMute = false,
    bool clearPersisted = true,
    bool bumpGeneration = true,
    bool stopNative = true,
  }) async {
    if (bumpGeneration) {
      _stopGeneration++;
    }
    if (clearMute) {
      _mutedUntil = null;
      await _clearPersistedMute();
    }
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _keepAliveKickOnce?.cancel();
    _keepAliveKickOnce = null;
    _loopUntilStopped = false;
    _onTimeout = null;
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    _active = false;
    _flutterRingOn = false;
    _ringPlayGen++;
    if (clearPersisted) {
      await _clearPersistedActive();
    }
    if (stopNative && !kIsWeb && Platform.isAndroid) {
      await _requestNativeAlertStop();
      if (_onMainIsolate) {
        await AppForegroundHelper.stopNativeAlert();
      }
    }
    try {
      await _ringtonePlayer.stop();
    } catch (_) {}
    try {
      await Vibration.cancel();
    } catch (_) {}
    if (stopNative && !kIsWeb && Platform.isAndroid && _onMainIsolate) {
      try {
        await AppForegroundHelper.stopNativeAlert();
      } catch (_) {}
      try {
        await _ringtonePlayer.stop();
      } catch (_) {}
    }
  }

  static Future<void> _vibrate() async {
    if (kIsWeb || !_active) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      const pattern = [0, 800, 200, 800, 200, 1000];
      final hasAmplitude = await Vibration.hasAmplitudeControl();
      if (hasAmplitude == true) {
        await Vibration.vibrate(
          pattern: pattern,
          intensities: [0, 255, 0, 255, 0, 255],
        );
      } else {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (_) {}
  }
}
