package `in`.quiksee.dman

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        OrderWakeNotifier.ensureChannel(this)
        NavigationDeliverNotifier.ensureChannel(this)
        if (isWakeIntent(intent)) {
            prepareForLockScreenWake()
        }
        OrderWakePrefs.persistFromIntent(this, intent)
        NavigationDeliverPrefs.persistFromIntent(this, intent)
        ActiveNavigationReturnPrefs.persistFromIntent(this, intent)
        dismissNearAlertIfRequested(intent)
        if (!isWakeIntent(intent)) {
            OrderWakeNotifier.dismiss(this)
        }
        super.onCreate(savedInstanceState)
        if (isWakeIntent(intent)) {
            OrderLaunchHelper.wakeScreen(applicationContext)
            keepScreenOnWhileAlerting()
        }
    }

    override fun onResume() {
        super.onResume()
        AppForegroundState.markResumed()
        // Delay dismiss on wake so notification/FGS ring is not cut off before
        // NativeOrderAlert / Flutter sheet takes over.
        if (isWakeIntent(intent)) {
            prepareForLockScreenWake()
            OrderLaunchHelper.wakeScreen(applicationContext)
            keepScreenOnWhileAlerting()
            OrderLaunchHelper.releaseWakeLock()
            window.decorView.postDelayed({
                if (AppForegroundState.isResumed) {
                    OrderWakeNotifier.dismiss(this)
                }
            }, 4_000L)
        } else {
            OrderWakeNotifier.dismiss(this)
        }
        dismissNearAlertIfRequested(intent)
        DriverOnlineService.restartIfOnline(applicationContext)
        if (DriverKeepAliveScheduler.isDriverOnline(applicationContext)) {
            DriverKeepAliveScheduler.schedule(applicationContext)
        }
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        if (prefs.getBoolean("flutter.native_alert_stop_requested", false)) {
            OrderAlertForegroundService.stop(applicationContext)
            prefs.edit().remove("flutter.native_alert_stop_requested").apply()
        } else if (NativeOrderAlert.shouldKeepAlertAlive(applicationContext)) {
            // Cold start / splash: Flutter keepAlive is not running yet.
            // Re-assert native ring so it does not die until Accept/Deny.
            NativeOrderAlert.reassertIfNeeded(applicationContext)
            if (!OrderAlertForegroundService.isRunning()) {
                OrderAlertForegroundService.start(
                    applicationContext,
                    mapOf(
                        "type" to "order_alert",
                        "order_id" to "0",
                    ),
                )
            }
        }
    }

    override fun onPause() {
        AppForegroundState.markPaused()
        super.onPause()
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        OrderWakePrefs.persistFromIntent(this, intent)
        NavigationDeliverPrefs.persistFromIntent(this, intent)
        ActiveNavigationReturnPrefs.persistFromIntent(this, intent)
        dismissNearAlertIfRequested(intent)
        if (!isWakeIntent(intent)) {
            OrderWakeNotifier.dismiss(this)
        }
        if (isWakeIntent(intent)) {
            prepareForLockScreenWake()
            OrderLaunchHelper.wakeScreen(applicationContext)
            keepScreenOnWhileAlerting()
        }
    }

    /** EXIT on near-customer popup → hide alert. Sticky FGS stopped only on EXIT. */
    private fun dismissNearAlertIfRequested(intent: Intent?) {
        if (intent == null) return
        val isExit = intent.getBooleanExtra("dismiss_near_alert", false) ||
            (
                intent.getBooleanExtra("navigation_return_wake", false) &&
                    !intent.getBooleanExtra("navigation_deliver_wake", false)
            )
        if (!isExit) return
        val orderId = intent.getIntExtra("navigation_return_order_id", 0)
            .takeIf { it > 0 }
            ?: intent.getIntExtra("order_id", 0)
        NavigationDeliverNotifier.dismiss(this, orderId)
        NavigationForegroundService.stop(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ForegroundMethodHandler.register(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "in.quiksee.dman/maps")
            .setMethodCallHandler { call, result ->
                if (call.method == "openNavigation") {
                    val address = call.argument<String>("address")?.trim()
                    val lat = call.argument<Double>("latitude")
                    val lng = call.argument<Double>("longitude")
                    val opened = when {
                        !address.isNullOrEmpty() ->
                            openGoogleMapsNavigationWithAddress(address)
                        lat != null && lng != null ->
                            openGoogleMapsNavigation(lat, lng)
                        else -> false
                    }
                    result.success(opened)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun isWakeIntent(intent: Intent?): Boolean {
        return intent?.getBooleanExtra("new_order_wake", false) == true ||
            intent?.getBooleanExtra("navigation_deliver_wake", false) == true ||
            intent?.getBooleanExtra("navigation_return_wake", false) == true
    }

    private fun prepareForLockScreenWake() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            try {
                val keyguardManager =
                    getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguardManager.requestDismissKeyguard(
                    this,
                    object : KeyguardManager.KeyguardDismissCallback() {
                        override fun onDismissSucceeded() {
                            keepScreenOnWhileAlerting()
                        }

                        override fun onDismissCancelled() {
                            keepScreenOnWhileAlerting()
                        }

                        override fun onDismissError() {
                            keepScreenOnWhileAlerting()
                        }
                    },
                )
            } catch (_: Exception) {
                keepScreenOnWhileAlerting()
            }
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        }
    }

    private fun keepScreenOnWhileAlerting() {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun openGoogleMapsNavigationWithAddress(address: String): Boolean {
        val query = Uri.encode(address)
        val mapsPackage = "com.google.android.apps.maps"

        val navUri = Uri.parse("google.navigation:q=$query&mode=d")
        val navIntent = Intent(Intent.ACTION_VIEW, navUri).apply {
            setPackage(mapsPackage)
        }
        if (navIntent.resolveActivity(packageManager) != null) {
            startActivity(navIntent)
            return true
        }

        val dirUri = Uri.parse(
            "https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving",
        )
        val dirIntent = Intent(Intent.ACTION_VIEW, dirUri).apply {
            setPackage(mapsPackage)
        }
        if (dirIntent.resolveActivity(packageManager) != null) {
            startActivity(dirIntent)
            return true
        }

        return false
    }

    private fun openGoogleMapsNavigation(lat: Double, lng: Double): Boolean {
        val coords = "$lat,$lng"
        val mapsPackage = "com.google.android.apps.maps"

        val navUri = Uri.parse("google.navigation:q=$coords&mode=d")
        val navIntent = Intent(Intent.ACTION_VIEW, navUri).apply {
            setPackage(mapsPackage)
        }
        if (navIntent.resolveActivity(packageManager) != null) {
            startActivity(navIntent)
            return true
        }

        val dirUri = Uri.parse(
            "https://www.google.com/maps/dir/?api=1&destination=$coords&travelmode=driving",
        )
        val dirIntent = Intent(Intent.ACTION_VIEW, dirUri).apply {
            setPackage(mapsPackage)
        }
        if (dirIntent.resolveActivity(packageManager) != null) {
            startActivity(dirIntent)
            return true
        }

        return false
    }
}
