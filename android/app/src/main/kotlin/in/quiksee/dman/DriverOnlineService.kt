package `in`.quiksee.dman

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.io.BufferedReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * Keeps the driver reachable after swipe / force-clear:
 * - Sticky foreground service (survives recents clear)
 * - Native GPS → update-live-location (so server keeps assigning)
 * - Polls pending-offers when FCM is delayed / dropped
 */
class DriverOnlineService : Service(), LocationListener {

    private val handler = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private var locationManager: LocationManager? = null
    private var lastLocation: Location? = null
    private var lastOfferAlertAt = 0L

    private val tickRunnable = object : Runnable {
        override fun run() {
            io.execute { tickOnce() }
            handler.postDelayed(this, TICK_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        try {
            ensureChannel()
            promoteToForeground()
            startLocationUpdates()
            handler.removeCallbacks(tickRunnable)
            handler.post(tickRunnable)
        } catch (e: Exception) {
            Log.w(TAG, "onCreate failed: ${e.message}")
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            markOnlinePref(true)
            promoteToForeground()
            if (locationManager == null) startLocationUpdates()
            handler.removeCallbacks(tickRunnable)
            handler.post(tickRunnable)
        } catch (e: Exception) {
            Log.w(TAG, "onStartCommand failed: ${e.message}")
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(TAG, "Task removed — restarting online service")
        markOnlinePref(true)
        try {
            val restart = Intent(applicationContext, DriverOnlineService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(restart)
            } else {
                applicationContext.startService(restart)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Restart after task remove failed: ${e.message}")
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        handler.removeCallbacks(tickRunnable)
        stopLocationUpdates()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onLocationChanged(location: Location) {
        lastLocation = location
    }

    @Deprecated("Deprecated in API")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

    override fun onProviderEnabled(provider: String) {}

    override fun onProviderDisabled(provider: String) {}

    private fun tickOnce() {
        if (!isOnlinePref()) {
            Log.i(TAG, "Offline pref — stopping")
            stopSelf()
            return
        }
        val token = readToken()
        if (token.isNullOrBlank()) {
            Log.w(TAG, "No auth token — skip tick")
            return
        }

        postLiveLocation(token)
        pollPendingOffers(token)
    }

    private fun postLiveLocation(token: String) {
        val loc = lastLocation ?: readLastKnownLocation() ?: return
        lastLocation = loc
        try {
            val body = JSONObject()
                .put("latitude", loc.latitude)
                .put("longitude", loc.longitude)
                .put(
                    "location",
                    "${"%.5f".format(loc.latitude)}, ${"%.5f".format(loc.longitude)}",
                )
            httpPost(UPDATE_LIVE_LOCATION, token, body.toString())
            Log.i(TAG, "Posted live location lat=${loc.latitude} lng=${loc.longitude}")
        } catch (e: Exception) {
            Log.w(TAG, "postLiveLocation failed: ${e.message}")
        }
    }

    private fun pollPendingOffers(token: String) {
        if (NativeOrderAlert.isSuppressed(applicationContext)) return
        if (NativeOrderAlert.isPlaying()) return
        if (AppForegroundState.isResumed) return
        val now = System.currentTimeMillis()
        if (now - lastOfferAlertAt < OFFER_ALERT_COOLDOWN_MS) return

        try {
            val raw = httpGet(PENDING_OFFERS, token) ?: return
            val json = JSONObject(raw)
            if (json.optBoolean("driver_busy", false)) return
            val offers = json.optJSONArray("offers") ?: return
            if (offers.length() <= 0) return

            val first = offers.optJSONObject(0) ?: return
            val orderId = first.optString("order_id").ifBlank {
                first.optInt("order_id", 0).toString()
            }
            val offerId = first.optString("offer_id").ifBlank {
                first.optInt("offer_id", 0).toString()
            }
            val storeName = first.optString("store_name")
                .ifBlank { first.optString("restaurant_name", "New order") }

            if (orderId.isBlank() || orderId == "0") return

            Log.i(TAG, "Pending offer found order=$orderId offer=$offerId — waking")
            lastOfferAlertAt = now

            val data = linkedMapOf(
                "type" to "delivery_assignment_offer",
                "order_id" to orderId,
                "offer_id" to offerId,
                "store_name" to storeName,
            )
            OrderWakePrefs.persistFromFcm(applicationContext, data)
            handler.post {
                OrderAlertForegroundService.start(applicationContext, data)
                OrderWakeNotifier.showOrderAlert(applicationContext, data)
                OrderLaunchHelper.launchForOrder(applicationContext, data)
            }
        } catch (e: Exception) {
            Log.w(TAG, "pollPendingOffers failed: ${e.message}")
        }
    }

    private fun startLocationUpdates() {
        if (ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.ACCESS_FINE_LOCATION,
            ) != PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.ACCESS_COARSE_LOCATION,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "Location permission missing")
            return
        }
        try {
            val lm = getSystemService(LOCATION_SERVICE) as LocationManager
            locationManager = lm
            lastLocation = readLastKnownLocation()
            val minTime = 15_000L
            val minDist = 25f
            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                lm.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    minTime,
                    minDist,
                    this,
                    Looper.getMainLooper(),
                )
            }
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                lm.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    minTime,
                    minDist,
                    this,
                    Looper.getMainLooper(),
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "startLocationUpdates failed: ${e.message}")
        }
    }

    private fun stopLocationUpdates() {
        try {
            locationManager?.removeUpdates(this)
        } catch (_: Exception) {
        }
        locationManager = null
    }

    private fun readLastKnownLocation(): Location? {
        if (ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.ACCESS_FINE_LOCATION,
            ) != PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(
                this,
                android.Manifest.permission.ACCESS_COARSE_LOCATION,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return null
        }
        return try {
            val lm = getSystemService(LOCATION_SERVICE) as LocationManager
            lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                ?: lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
        } catch (_: Exception) {
            null
        }
    }

    private fun promoteToForeground() {
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceCompat.startForeground(
                    this,
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground location|dataSync failed: ${e.message}")
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceCompat.startForeground(
                        this,
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } catch (e2: Exception) {
                Log.w(TAG, "startForeground fallback failed: ${e2.message}")
            }
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Driver online",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps Quiksee online so new orders arrive when app is closed"
            setShowBadge(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Quiksee Delivery")
            .setContentText("Online — waiting for new orders")
            .setSmallIcon(R.drawable.notification_icon)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun prefs() =
        getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun markOnlinePref(online: Boolean) {
        prefs().edit().putBoolean(KEY_DRIVER_ONLINE, online).apply()
    }

    private fun isOnlinePref(): Boolean =
        prefs().getBoolean(KEY_DRIVER_ONLINE, false)

    private fun readToken(): String? =
        prefs().getString(KEY_TOKEN, null)?.takeIf { it.isNotBlank() }

    private fun httpGet(path: String, token: String): String? {
        var conn: HttpURLConnection? = null
        return try {
            conn = (URL(BASE_URL + path).openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 12_000
                readTimeout = 12_000
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Accept", "application/json")
                setRequestProperty("X-localization", "en")
            }
            val code = conn.responseCode
            val stream = if (code in 200..299) conn.inputStream else conn.errorStream
            stream?.bufferedReader()?.use(BufferedReader::readText)
        } catch (e: Exception) {
            Log.w(TAG, "httpGet $path failed: ${e.message}")
            null
        } finally {
            conn?.disconnect()
        }
    }

    private fun httpPost(path: String, token: String, jsonBody: String) {
        var conn: HttpURLConnection? = null
        try {
            conn = (URL(BASE_URL + path).openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 12_000
                readTimeout = 12_000
                doOutput = true
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Accept", "application/json")
                setRequestProperty("Content-Type", "application/json")
                setRequestProperty("X-localization", "en")
            }
            OutputStreamWriter(conn.outputStream).use { it.write(jsonBody) }
            val code = conn.responseCode
            // Drain body so connection can be reused / closed cleanly.
            (if (code in 200..299) conn.inputStream else conn.errorStream)
                ?.bufferedReader()?.use(BufferedReader::readText)
            if (code !in 200..299) {
                Log.w(TAG, "httpPost $path status=$code")
            }
        } catch (e: Exception) {
            Log.w(TAG, "httpPost $path failed: ${e.message}")
        } finally {
            conn?.disconnect()
        }
    }

    companion object {
        private const val TAG = "DriverOnlineService"
        private const val CHANNEL_ID = "quiksee_driver_online"
        private const val NOTIFICATION_ID = 9101
        private const val PREFS = "FlutterSharedPreferences"
        private const val KEY_DRIVER_ONLINE = "flutter.driver_online"
        private const val KEY_TOKEN = "flutter.token"
        private const val BASE_URL = "https://quiksee.in"
        private const val UPDATE_LIVE_LOCATION = "/api/v2/delivery-man/update-live-location"
        private const val PENDING_OFFERS = "/api/v2/delivery-man/pending-offers"
        private const val TICK_MS = 15_000L
        private const val OFFER_ALERT_COOLDOWN_MS = 20_000L

        fun start(context: Context) {
            try {
                context.applicationContext
                    .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean(KEY_DRIVER_ONLINE, true)
                    .apply()
                val intent = Intent(context, DriverOnlineService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                DriverKeepAliveScheduler.schedule(context)
                Log.i(TAG, "Driver online service start requested")
            } catch (e: Exception) {
                Log.w(TAG, "start failed: ${e.message}")
                // Even if FGS fails, keep chaining alarms so we retry.
                DriverKeepAliveScheduler.schedule(context)
            }
        }

        fun stop(context: Context) {
            try {
                context.applicationContext
                    .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    .edit()
                    .putBoolean(KEY_DRIVER_ONLINE, false)
                    .apply()
                DriverKeepAliveScheduler.cancel(context)
                context.stopService(Intent(context, DriverOnlineService::class.java))
            } catch (_: Exception) {
            }
        }

        fun restartIfOnline(context: Context) {
            val online = context.applicationContext
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_DRIVER_ONLINE, false)
            if (online) start(context)
        }
    }
}
