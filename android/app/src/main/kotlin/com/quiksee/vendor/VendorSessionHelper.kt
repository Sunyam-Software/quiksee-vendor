package com.quiksee.vendor

import android.content.Context

object VendorSessionHelper {
    private const val PREFS = "FlutterSharedPreferences"
    private const val TOKEN_KEY = "flutter.token"

    fun isLoggedIn(context: Context): Boolean {
        val token = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(TOKEN_KEY, null)
        return !token.isNullOrBlank()
    }
}
