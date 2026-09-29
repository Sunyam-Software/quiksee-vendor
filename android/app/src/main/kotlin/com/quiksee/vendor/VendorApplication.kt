package com.quiksee.vendor

import android.app.Application

class VendorApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        VendorNotificationChannels.ensureCreated(this)
    }
}
