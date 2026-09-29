package `in`.quiksee.dman

import android.content.Context
import android.content.Intent

/**
 * Persists new-order wake data into Flutter [SharedPreferences] so the Dart side
 * can open the offer sheet after a cold start (app was fully closed).
 */
object OrderWakePrefs {

    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_ORDER_ID = "flutter.pending_wake_order_id"
    private const val KEY_ORDER_TYPE = "flutter.pending_wake_order_type"
    private const val KEY_OFFER_ID = "flutter.pending_wake_offer_id"
    private const val KEY_STORED_AT = "flutter.pending_wake_stored_at_ms"

    fun persistFromIntent(context: Context, intent: Intent?) {
        if (intent?.getBooleanExtra("new_order_wake", false) != true) return
        val orderId = intent.getStringExtra("wake_order_id")?.toLongOrNull() ?: return
        if (orderId <= 0L) return

        val type = intent.getStringExtra("wake_order_type")
            ?.takeIf { it.isNotBlank() }
            ?: "new_order_assigned"
        val offerId = intent.getStringExtra("wake_offer_id")?.toLongOrNull()

        persist(context, orderId, type, offerId)
    }

    fun persistFromFcm(context: Context, data: Map<String, String>) {
        if (!OrderLaunchHelper.shouldLaunchFor(data)) return
        val orderId = data["order_id"]?.toLongOrNull() ?: return
        if (orderId <= 0L) return

        val type = data["type"]?.takeIf { it.isNotBlank() } ?: "new_order_assigned"
        val offerId = data["offer_id"]?.toLongOrNull()
        persist(context, orderId, type, offerId)
    }

    private fun persist(
        context: Context,
        orderId: Long,
        type: String,
        offerId: Long?,
    ) {
        val editor = context.applicationContext
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_ORDER_ID, orderId)
            .putString(KEY_ORDER_TYPE, type)
            .putLong(KEY_STORED_AT, System.currentTimeMillis())

        if (offerId != null && offerId > 0L) {
            editor.putLong(KEY_OFFER_ID, offerId)
        } else {
            editor.remove(KEY_OFFER_ID)
        }
        editor.apply()
    }
}
