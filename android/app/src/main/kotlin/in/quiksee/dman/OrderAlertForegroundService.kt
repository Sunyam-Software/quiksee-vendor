package `in`.quiksee.dman

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground service that keeps ringtone + vibration alive after force-close /
 * process death when FCM delivers a new offer.
 *
 * Critical: [startForeground] must run before any heavy work, or Android kills
 * the service (and the ring) within seconds on Android 12+.
 */
class OrderAlertForegroundService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private val autoStopRunnable = Runnable {
        // Accept/Deny owns the real stop. Only drop the foreground service.
        Log.i(TAG, "Auto-stop FGS (native ring continues until Accept/Deny)")
        releaseCpuLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }
    private var cpuWakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        OrderWakeNotifier.ensureChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                NativeOrderAlert.stop(applicationContext)
                releaseCpuLock()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
        }

        val data = readPayload(intent)

        promoteToForeground(data)

        if (NativeOrderAlert.isSuppressed(applicationContext)) {
            Log.i(TAG, "FGS onStart suppressed — stopping")
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        acquireCpuLock()

        // 2) Ring + vibrate while FGS is alive (works even if Activity is dead).
        // cut transfer audio to a short chirp when Flutter also called start.
        NativeOrderAlert.startInstant(applicationContext, forceRestart = false)

        OrderLaunchHelper.wakeScreen(applicationContext)
        if (!AppForegroundState.isResumed) {
            OrderWakeNotifier.showOrderAlert(applicationContext, data)
        }
        OrderLaunchHelper.launchForOrder(applicationContext, data)

        handler.removeCallbacks(autoStopRunnable)
        handler.postDelayed(autoStopRunnable, ALERT_DURATION_MS)
        markRunning(true)

        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        handler.removeCallbacks(autoStopRunnable)
        releaseCpuLock()
        markRunning(false)
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        try {
            if (!NativeOrderAlert.isSuppressed(applicationContext) &&
                NativeOrderAlert.isPlaying()
            ) {
                Log.i(TAG, "Task removed — re-promoting alert FGS")
                promoteToForeground(
                    mapOf("type" to "delivery_assignment_offer", "order_id" to "?"),
                )
                return
            }
        } catch (_: Exception) {
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun readPayload(intent: Intent?): Map<String, String> {
        val map = linkedMapOf<String, String>()
        intent?.getStringExtra(EXTRA_TYPE)?.let { map["type"] = it }
        intent?.getStringExtra(EXTRA_ORDER_ID)?.let { map["order_id"] = it }
        intent?.getStringExtra(EXTRA_OFFER_ID)?.let { map["offer_id"] = it }
        intent?.getStringExtra(EXTRA_STORE_NAME)?.let { map["store_name"] = it }
        if (map["type"].isNullOrBlank()) {
            map["type"] = "delivery_assignment_offer"
        }
        return map
    }

    private fun promoteToForeground(data: Map<String, String>) {
        ensureAlertServiceChannel()
        val orderId = data["order_id"] ?: "?"
        val storeName = data["store_name"]?.takeIf { it.isNotBlank() } ?: "New order"
        val launchIntent = OrderLaunchHelper.buildLaunchIntent(this, data)
        val pending = android.app.PendingIntent.getActivity(
            this,
            orderId.hashCode(),
            launchIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                android.app.PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(this, ALERT_SERVICE_CHANNEL_ID)
            .setSmallIcon(R.drawable.notification_icon)
            .setContentTitle("New delivery order!")
            .setContentText("$storeName — Order #$orderId")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Incoming order #$orderId. Opening Quiksee…"),
            )
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(false)
            .setContentIntent(pending)
            .setFullScreenIntent(pending, true)
            .setVibrate(longArrayOf(0, 900, 250, 900, 250, 900))
            .build()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceCompat.startForeground(
                    this,
                    FOREGROUND_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
                )
            } else {
                startForeground(FOREGROUND_NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground failed: ${e.message}")
            try {
                startForeground(FOREGROUND_NOTIFICATION_ID, notification)
            } catch (_: Exception) {
            }
        }
    }

    private fun ensureAlertServiceChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        try {
            manager.deleteNotificationChannel("quiksee_order_alert_service_v2")
        } catch (_: Exception) {
        }
        if (manager.getNotificationChannel(ALERT_SERVICE_CHANNEL_ID) != null) return

        val alarmUri = android.media.RingtoneManager.getDefaultUri(
            android.media.RingtoneManager.TYPE_RINGTONE,
        ) ?: android.media.RingtoneManager.getDefaultUri(
            android.media.RingtoneManager.TYPE_ALARM,
        )

        val attrs = android.media.AudioAttributes.Builder()
            .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val channel = NotificationChannel(
            ALERT_SERVICE_CHANNEL_ID,
            "Incoming order alert",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Rings when a new order arrives while Quiksee is closed"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 900, 250, 900, 250, 900)
            setBypassDnd(true)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            if (alarmUri != null) {
                setSound(alarmUri, attrs)
            }
        }
        manager.createNotificationChannel(channel)
    }

    private fun acquireCpuLock() {
        try {
            releaseCpuLock()
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            cpuWakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "quiksee:order_alert_cpu",
            ).apply {
                acquire(ALERT_DURATION_MS + 5_000L)
            }
        } catch (_: Exception) {
        }
    }

    private fun releaseCpuLock() {
        try {
            cpuWakeLock?.let {
                if (it.isHeld) it.release()
            }
        } catch (_: Exception) {
        }
        cpuWakeLock = null
    }

    companion object {
        private const val TAG = "OrderAlertService"
        private const val ACTION_STOP = "in.quiksee.dman.action.STOP_ORDER_ALERT"
        private const val EXTRA_TYPE = "extra_type"
        private const val EXTRA_ORDER_ID = "extra_order_id"
        private const val EXTRA_OFFER_ID = "extra_offer_id"
        private const val EXTRA_STORE_NAME = "extra_store_name"
        private const val FOREGROUND_NOTIFICATION_ID = 9002
        private const val ALERT_SERVICE_CHANNEL_ID = "quiksee_order_alert_service_v3"
        private const val ALERT_DURATION_MS = 120_000L

        @Volatile
        private var running = false

        private fun markRunning(active: Boolean) {
            running = active
        }

        fun start(context: Context, data: Map<String, String>) {
            if (NativeOrderAlert.isSuppressed(context)) {
                Log.i(TAG, "Skip FGS start — alert muted")
                return
            }
            try {
                val intent = Intent(context, OrderAlertForegroundService::class.java).apply {
                    putExtra(EXTRA_TYPE, data["type"])
                    putExtra(EXTRA_ORDER_ID, data["order_id"])
                    putExtra(EXTRA_OFFER_ID, data["offer_id"])
                    putExtra(EXTRA_STORE_NAME, data["store_name"])
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                markRunning(true)
                Log.i(TAG, "Order alert service started for order ${data["order_id"]}")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to start order alert service: ${e.message}")
                NativeOrderAlert.startInstant(context, forceRestart = true)
                OrderWakeNotifier.showOrderAlert(context, data)
                OrderLaunchHelper.launchForOrder(context, data)
            }
        }

        fun stop(context: Context) {
            markRunning(false)
            OrderWakeNotifier.dismiss(context)
            NativeOrderAlert.stop(context)
            try {
                val intent = Intent(context, OrderAlertForegroundService::class.java).apply {
                    action = ACTION_STOP
                }
                context.startService(intent)
            } catch (_: Exception) {
            }
            try {
                context.stopService(Intent(context, OrderAlertForegroundService::class.java))
            } catch (_: Exception) {
            }
        }

        fun isRunning(): Boolean = running
    }
}
