package `in`.quiksee.dman

import android.content.Context
import android.content.Intent

object ActiveNavigationReturnPrefs {

    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_ORDER_ID = "flutter.pending_navigation_return_order_id"

    fun persistFromIntent(context: Context, intent: Intent?) {
        if (intent?.getBooleanExtra("navigation_return_wake", false) != true) return
        val orderId = intent.getIntExtra("navigation_return_order_id", 0)
        if (orderId <= 0) return
        persist(context, orderId)
    }

    fun persist(context: Context, orderId: Int) {
        if (orderId <= 0) return
        // commit() so Flutter onResume can read before apply() flushes.
        context.applicationContext
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_ORDER_ID, orderId.toLong())
            .commit()
    }
}
