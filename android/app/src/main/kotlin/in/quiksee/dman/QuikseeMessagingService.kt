package `in`.quiksee.dman

import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * then wake/open the app. Flutter background handler runs last via [super.onMessageReceived].
 */
class QuikseeMessagingService : FlutterFirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        val type = data["type"]
        Log.i(TAG, "FCM received type=$type order=${data["order_id"]} offer=${data["offer_id"]}")

        when (type) {
            "delivery_assignment_offer_cancelled",
            "delivery_assignment_accepted" -> {
                OrderAlertForegroundService.stop(applicationContext)
            }
            // not treat it as a new incoming offer.
            "new_order_assigned" -> {
                if (NativeOrderAlert.isSuppressed(applicationContext)) {
                    Log.i(TAG, "new_order_assigned ignored — muted after accept")
                    OrderAlertForegroundService.stop(applicationContext)
                } else {
                    // Genuine admin/vendor direct assign while idle: ring.
                    OrderWakePrefs.persistFromFcm(applicationContext, data)
                    OrderLaunchHelper.wakeScreen(applicationContext)
                    DriverOnlineService.restartIfOnline(applicationContext)
                    OrderAlertForegroundService.start(applicationContext, data)
                    if (!AppForegroundState.isResumed) {
                        OrderWakeNotifier.ensureChannel(applicationContext)
                        OrderWakeNotifier.showOrderAlert(applicationContext, data)
                    }
                    OrderLaunchHelper.launchForOrder(applicationContext, data)
                }
            }
            "delivery_assignment_offer" -> {
                // New offer/assign always clears stale mute from a previous accept/reject.
                NativeOrderAlert.clearMuteForNewOffer(applicationContext, data["offer_id"])

                if (NativeOrderAlert.isSuppressed(applicationContext)) {
                    Log.i(TAG, "Offer FCM ignored — alert muted after accept/reject")
                    OrderAlertForegroundService.stop(applicationContext)
                } else {
                    OrderWakePrefs.persistFromFcm(applicationContext, data)
                    OrderLaunchHelper.wakeScreen(applicationContext)

                    // Keep online FGS alive after force-clear (GPS + offer poll backup).
                    DriverOnlineService.restartIfOnline(applicationContext)

                    OrderAlertForegroundService.start(applicationContext, data)

                    if (!AppForegroundState.isResumed) {
                        OrderWakeNotifier.ensureChannel(applicationContext)
                        OrderWakeNotifier.showOrderAlert(applicationContext, data)
                    }

                    // Also try direct launch (FGS retries too).
                    OrderLaunchHelper.launchForOrder(applicationContext, data)
                }
            }
            "order_transfer_request" -> {
                // New offer should clear old mute unless it is the same offer_id.
                NativeOrderAlert.clearMuteForNewOffer(
                    applicationContext,
                    data["offer_id"],
                )
                if (NativeOrderAlert.isSuppressed(applicationContext)) {
                    Log.i(TAG, "Transfer FCM ignored — muted after accept/reject")
                    OrderAlertForegroundService.stop(applicationContext)
                } else {
                    OrderWakePrefs.persistFromFcm(applicationContext, data)
                    OrderLaunchHelper.wakeScreen(applicationContext)
                    DriverOnlineService.restartIfOnline(applicationContext)
                    OrderAlertForegroundService.start(applicationContext, data)
                    if (!AppForegroundState.isResumed) {
                        OrderWakeNotifier.ensureChannel(applicationContext)
                        OrderWakeNotifier.showOrderAlert(applicationContext, data)
                    }
                    OrderLaunchHelper.launchForOrder(applicationContext, data)
                }
            }
            "order_transfer_offer_cancelled",
            "order_transfer_accepted" -> {
                OrderAlertForegroundService.stop(applicationContext)
                NativeOrderAlert.stop(applicationContext)
            }
            else -> {
                if (OrderLaunchHelper.shouldLaunchFor(data)) {
                    OrderWakePrefs.persistFromFcm(applicationContext, data)
                    OrderLaunchHelper.wakeScreen(applicationContext)
                    OrderLaunchHelper.launchForOrder(applicationContext, data)
                }
            }
        }
        super.onMessageReceived(message)
    }

    companion object {
        private const val TAG = "QuikseeFCM"
    }
}
