package `in`.quiksee.dman

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object ForegroundMethodHandler {

    const val CHANNEL = "in.quiksee.dman/foreground"

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bringToForeground" -> {
                    val orderId = call.argument<String>("orderId")
                    val offerId = call.argument<String>("offerId")
                    val type = call.argument<String>("type")
                    bringToForeground(context, orderId, offerId, type)
                    result.success(true)
                }
                "wakeScreen" -> {
                    wakeScreen(context)
                    result.success(true)
                }
                "startNativeAlert" -> {
                    val force = call.argument<Boolean>("force") == true
                    OrderAlertForegroundService.start(
                        context,
                        mapOf(
                            "type" to "order_alert",
                            "order_id" to "0",
                        ),
                    )
                    NativeOrderAlert.startInstant(context, forceRestart = force)
                    wakeScreen(context)
                    result.success(true)
                }
                "stopNativeAlert" -> {
                    NativeOrderAlert.stop(context)
                    OrderAlertForegroundService.stop(context)
                    result.success(true)
                }
                "dismissOrderWakeHeadsUp" -> {
                    // Keep ringtone; only remove the small non-interactive banner.
                    OrderWakeNotifier.dismiss(context)
                    result.success(true)
                }
                "startOnlineService" -> {
                    DriverOnlineService.start(context)
                    result.success(true)
                }
                "stopOnlineService" -> {
                    DriverOnlineService.stop(context)
                    result.success(true)
                }
                "startNavigationService" -> {
                    val orderId = call.argument<Int>("orderId") ?: 0
                    val address = call.argument<String>("address") ?: ""
                    if (orderId > 0) {
                        NavigationForegroundService.start(context, orderId, address)
                    }
                    result.success(true)
                }
                "stopNavigationService" -> {
                    NavigationForegroundService.stop(context)
                    result.success(true)
                }
                "requestBatteryOptimizationExemption" -> {
                    OemBackgroundHelper.openStockBatteryExemption(context)
                    result.success(true)
                }
                "needsOemAutostart" -> {
                    result.success(OemBackgroundHelper.needsOemAutostart())
                }
                "oemManufacturerLabel" -> {
                    result.success(OemBackgroundHelper.manufacturerLabel())
                }
                "openOemAutostartSettings" -> {
                    // Universal: battery dialog + brand Autostart + app details.
                    val opened = OemBackgroundHelper.openBackgroundSetup(context)
                    result.success(opened)
                }
                "canUseFullScreenIntent" -> {
                    result.success(canUseFullScreenIntent(context))
                }
                "requestFullScreenIntentPermission" -> {
                    requestFullScreenIntentPermission(context)
                    result.success(true)
                }
                "showNavigationDeliverAlert" -> {
                    val orderId = call.argument<Int>("orderId") ?: 0
                    val title = call.argument<String>("title") ?: "Delivery arrived"
                    val address = call.argument<String>("address") ?: ""
                    if (orderId > 0) {
                        NavigationDeliverPrefs.persist(context, orderId)
                        NavigationDeliverNotifier.showArrivalAlert(
                            context,
                            orderId,
                            title,
                            address,
                        )
                        wakeScreen(context)
                    }
                    result.success(true)
                }
                "dismissNavigationDeliverAlert" -> {
                    val orderId = call.argument<Int>("orderId") ?: 0
                    if (orderId > 0) {
                        NavigationDeliverNotifier.dismiss(context, orderId)
                    }
                    result.success(true)
                }
                "hasBackgroundLocationPermission" -> {
                    result.success(
                        LocationPermissionHelper.hasBackgroundLocation(context),
                    )
                }
                "needsBackgroundLocationStep" -> {
                    result.success(LocationPermissionHelper.needsBackgroundLocationStep())
                }
                "androidSdkInt" -> {
                    result.success(LocationPermissionHelper.androidSdkInt())
                }
                "openBackgroundLocationSettings" -> {
                    result.success(
                        LocationPermissionHelper.openBackgroundLocationSettings(context),
                    )
                }
                "requestBackgroundLocationNative" -> {
                    val activity = context as? Activity
                    if (activity == null) {
                        result.success(
                            LocationPermissionHelper.openBackgroundLocationSettings(context),
                        )
                    } else {
                        result.success(
                            LocationPermissionHelper.requestBackgroundLocation(activity),
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun canUseFullScreenIntent(context: Context): Boolean {
        if (android.os.Build.VERSION.SDK_INT < 34) return true
        return try {
            val manager = context.getSystemService(android.app.NotificationManager::class.java)
            manager?.canUseFullScreenIntent() == true
        } catch (_: Exception) {
            true
        }
    }

    private fun requestFullScreenIntentPermission(context: Context) {
        if (android.os.Build.VERSION.SDK_INT < 34) return
        if (canUseFullScreenIntent(context)) return
        try {
            val intent = android.content.Intent(
                android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
            ).apply {
                data = android.net.Uri.parse("package:${context.packageName}")
                addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (_: Exception) {
            try {
                val intent = android.content.Intent(
                    android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS,
                ).apply {
                    putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName)
                    addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (_: Exception) {
            }
        }
    }

    private fun bringToForeground(
        context: Context,
        orderId: String? = null,
        offerId: String? = null,
        type: String? = null,
    ) {
        val data = linkedMapOf<String, String>()
        data["type"] = type?.takeIf { it.isNotBlank() } ?: "delivery_assignment_offer"
        orderId?.takeIf { it.isNotBlank() }?.let { data["order_id"] = it }
        offerId?.takeIf { it.isNotBlank() }?.let { data["offer_id"] = it }
        OrderLaunchHelper.launchForOrder(context, data)
    }

    private fun wakeScreen(context: Context) {
        OrderLaunchHelper.wakeScreen(context.applicationContext)
    }
}
