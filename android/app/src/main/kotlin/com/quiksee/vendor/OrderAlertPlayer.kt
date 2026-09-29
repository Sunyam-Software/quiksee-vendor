package com.quiksee.vendor

import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

object OrderAlertPlayer {
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var stopHandler: Handler? = null
    private var watchdogHandler: Handler? = null
    private const val MAX_RING_DURATION_MS = 6 * 60 * 60 * 1000L
    private const val SILENCE_SAME_ORDER_MS = 24 * 60 * 60 * 1000L
    private const val SILENCE_BLANK_STOP_MS = 8_000L
    private const val WATCHDOG_MS = 400L
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val LOCAL_ORDER_NOTIFICATION_ID = 9001
    private const val GENERAL_NOTIFICATION_ID = 0

    @Volatile
    private var playingOrderId: Int = 0
    @Volatile
    private var silencedOrderId: Int = 0
    @Volatile
    private var silencedUntilMs: Long = 0L
    @Volatile
    private var killAllUntilMs: Long = 0L
    @Volatile
    private var lastVibrateEnsureMs: Long = 0L

    fun start(context: Context, orderId: Int = 0) {
        val appContext = context.applicationContext
        if (orderId > 0 && orderId != silencedOrderId) {
            killAllUntilMs = 0L
            silencedUntilMs = 0L
            silencedOrderId = 0
            try {
                appContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
                    .edit()
                    .remove("flutter.kitchen_ring_kill_all_until_ms")
                    .apply()
            } catch (_: Exception) {
            }
        }
        if (orderId > 0 && orderId == silencedOrderId && !isAckedInPrefs(appContext, orderId)) {
            silencedOrderId = 0
            silencedUntilMs = 0L
            killAllUntilMs = 0L
        }
        if (shouldStaySilent(appContext, orderId)) {
            stopInternal(appContext, interruptOtherAlarms = false)
            return
        }

        stopInternal(appContext, interruptOtherAlarms = false)
        playingOrderId = orderId
        vibrate(appContext)
        if (isKitchenRingEnabled(appContext)) {
            requestAlarmFocus(appContext)
            playAlarm(appContext)
        }

        if (shouldStaySilent(appContext, orderId)) {
            stopInternal(appContext, interruptOtherAlarms = true)
            return
        }

        stopHandler = Handler(Looper.getMainLooper())
        stopHandler?.postDelayed({
            stopInternal(appContext)
        }, MAX_RING_DURATION_MS)
        startWatchdog(appContext)
    }

    fun stop(context: Context, orderId: Int = 0) {
        val appContext = context.applicationContext
        val now = System.currentTimeMillis()

        if (orderId > 0 && playingOrderId > 0 && orderId != playingOrderId) {
            silencedOrderId = orderId
            silencedUntilMs = now + SILENCE_SAME_ORDER_MS
            clearKillAllPref(appContext)
            return
        }

        killAllUntilMs = now + SILENCE_BLANK_STOP_MS
        if (orderId > 0) {
            silencedOrderId = orderId
            silencedUntilMs = now + SILENCE_SAME_ORDER_MS
        } else {
            silencedUntilMs = now + SILENCE_BLANK_STOP_MS
        }
        clearKillAllPref(appContext)
        stopInternal(appContext, interruptOtherAlarms = true)
        cancelKitchenNotifications(appContext)
    }

    private fun shouldStaySilent(context: Context, orderId: Int): Boolean {
        val now = System.currentTimeMillis()
        val acked = orderId > 0 && isAckedInPrefs(context, orderId)
        if (orderId > 0 && orderId == silencedOrderId && acked) return true
        if (now < killAllUntilMs) {
            if (orderId <= 0) return true
            if (silencedOrderId > 0 && orderId == silencedOrderId && acked) return true
        }
        if (now < silencedUntilMs) {
            if (orderId <= 0) return true
            if (silencedOrderId > 0 && orderId == silencedOrderId && acked) return true
        }
        return isOrderBlocked(context, orderId)
    }

    private fun startWatchdog(context: Context) {
        watchdogHandler?.removeCallbacksAndMessages(null)
        watchdogHandler = Handler(Looper.getMainLooper())
        val runnable = object : Runnable {
            override fun run() {
                val id = playingOrderId
                if (shouldStaySilent(context, id)) {
                    stopInternal(context, interruptOtherAlarms = true)
                    cancelKitchenNotifications(context)
                    return
                }
                if (isKitchenRingEnabled(context)) {
                    val player = mediaPlayer
                    if (player == null || !player.isPlaying) {
                        playAlarm(context)
                    }
                } else {
                    stopAlarmOnly()
                    val now = System.currentTimeMillis()
                    if (vibrator == null || now - lastVibrateEnsureMs > 3500L) {
                        vibrate(context)
                        lastVibrateEnsureMs = now
                    }
                }
                watchdogHandler?.postDelayed(this, WATCHDOG_MS)
            }
        }
        watchdogHandler?.postDelayed(runnable, WATCHDOG_MS)
    }

    private fun isKitchenRingEnabled(context: Context): Boolean {
        return try {
            val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val key = "flutter.kitchen_ring_enabled"
            if (!prefs.contains(key)) return true
            try {
                prefs.getBoolean(key, true)
            } catch (_: ClassCastException) {
                try {
                    prefs.getInt(key, 1) != 0
                } catch (_: Exception) {
                    true
                }
            }
        } catch (_: Exception) {
            true
        }
    }

    private fun isAckedInPrefs(context: Context, orderId: Int): Boolean {
        if (orderId <= 0) return false
        return try {
            val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val id = orderId.toString()
            val acked = prefs.getStringSet("flutter.acknowledged_alert_order_ids", null)
            if (acked != null && acked.contains(id)) return true
            val ackedRaw = prefs.getString("flutter.acknowledged_alert_order_ids", null)
                ?: return false
            Regex(""""$id"(?!\d)""").containsMatchIn(ackedRaw)
        } catch (_: Exception) {
            false
        }
    }

    private fun isOrderBlocked(context: Context, orderId: Int): Boolean {
        return isAckedInPrefs(context, orderId)
    }

    private fun clearKillAllPref(context: Context) {
        try {
            context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
                .edit()
                .remove("flutter.kitchen_ring_kill_all_until_ms")
                .apply()
        } catch (_: Exception) {
        }
    }

    private fun readFlutterInt(
        prefs: android.content.SharedPreferences,
        key: String
    ): Int {
        return readFlutterLong(prefs, key).toInt()
    }

    private fun readFlutterLong(
        prefs: android.content.SharedPreferences,
        key: String
    ): Long {
        val flutterKey = "flutter.$key"
        return try {
            prefs.getLong(flutterKey, 0L)
        } catch (_: ClassCastException) {
            try {
                prefs.getInt(flutterKey, 0).toLong()
            } catch (_: Exception) {
                0L
            }
        }
    }

    private fun stopAlarmOnly() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null
    }

    private fun stopInternal(context: Context, interruptOtherAlarms: Boolean = false) {
        stopHandler?.removeCallbacksAndMessages(null)
        stopHandler = null
        watchdogHandler?.removeCallbacksAndMessages(null)
        watchdogHandler = null
        playingOrderId = 0

        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null

        try {
            vibrator?.cancel()
        } catch (_: Exception) {
        }
        vibrator = null

        if (interruptOtherAlarms) {
            interruptFlutterAlarms(context)
        }
    }

    private fun interruptFlutterAlarms(context: Context) {
        try {
            val alarm = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            RingtoneManager.getRingtone(context, alarm)?.stop()
        } catch (_: Exception) {
        }
        try {
            val ring = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            RingtoneManager.getRingtone(context, ring)?.stop()
        } catch (_: Exception) {
        }
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN,
            )
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_RING,
                AudioManager.AUDIOFOCUS_GAIN,
            )
        } catch (_: Exception) {
        }
    }

    private fun cancelKitchenNotifications(context: Context) {
        try {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(LOCAL_ORDER_NOTIFICATION_ID)
            manager.cancel(GENERAL_NOTIFICATION_ID)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                manager.activeNotifications
                    ?.filter { it.notification.channelId == VendorNotificationChannels.ORDER_CHANNEL_ID }
                    ?.forEach { manager.cancel(it.id) }
            }
        } catch (_: Exception) {
        }
    }

    private fun requestAlarmFocus(context: Context) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        } catch (_: Exception) {
        }
    }

    private fun playAlarm(context: Context) {
        val appContext = context.applicationContext
        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }
        mediaPlayer = null
        val candidates = listOfNotNull(
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
            RingtoneManager.getActualDefaultRingtoneUri(
                appContext,
                RingtoneManager.TYPE_ALARM
            ),
            RingtoneManager.getActualDefaultRingtoneUri(
                appContext,
                RingtoneManager.TYPE_RINGTONE
            ),
        )

        for (uri in candidates) {
            if (tryPlay(appContext, uri, AudioAttributes.USAGE_ALARM)) return
        }
        for (uri in candidates) {
            if (tryPlay(appContext, uri, AudioAttributes.USAGE_NOTIFICATION_RINGTONE)) return
        }
        for (uri in candidates) {
            if (tryPlay(appContext, uri, AudioAttributes.USAGE_NOTIFICATION)) return
        }
        if (candidates.isNotEmpty()) {
            tryPlayStreamAlarm(appContext, candidates[0])
        }
    }

    private fun tryPlayStreamAlarm(context: Context, uri: Uri?): Boolean {
        if (uri == null) return false
        return try {
            mediaPlayer = MediaPlayer().apply {
                @Suppress("DEPRECATION")
                setAudioStreamType(AudioManager.STREAM_ALARM)
                setDataSource(context, uri)
                isLooping = true
                prepare()
                start()
            }
            true
        } catch (_: Exception) {
            try {
                mediaPlayer?.release()
            } catch (_: Exception) {
            }
            mediaPlayer = null
            false
        }
    }

    private fun tryPlay(context: Context, uri: Uri, usage: Int): Boolean {
        return try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(usage)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(context, uri)
                isLooping = true
                prepare()
                start()
            }
            true
        } catch (_: Exception) {
            try {
                mediaPlayer?.release()
            } catch (_: Exception) {
            }
            mediaPlayer = null
            false
        }
    }

    private fun vibrate(context: Context) {
        try {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager =
                    context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            lastVibrateEnsureMs = System.currentTimeMillis()
            val pattern = longArrayOf(0, 600, 150, 600, 150, 800)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createWaveform(pattern, 0),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {
        }
    }
}
