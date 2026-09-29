package `in`.quiksee.dman

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object LocationPermissionHelper {

    private const val REQ_BACKGROUND_LOCATION = 9101

    fun androidSdkInt(): Int = Build.VERSION.SDK_INT

    fun hasForegroundLocation(context: Context): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    fun hasBackgroundLocation(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return hasForegroundLocation(context)
        }
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    /** True when a separate "all the time" step exists (Android 10+). */
    fun needsBackgroundLocationStep(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
    }

    /**
     * Opens app settings where the user can set Location → Allow all the time.
     * Works on old OEM skins that ignore permission_handler dialogs.
     */
    fun openBackgroundLocationSettings(context: Context): Boolean {
        val pkg = context.applicationContext.packageName
        val intents = listOf(
            // Some OEMs expose a permissions sub-screen (best effort).
            Intent("android.settings.APPLICATION_DETAILS_SETTINGS").apply {
                data = Uri.fromParts("package", pkg, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", pkg, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
        for (intent in intents) {
            try {
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    return true
                }
            } catch (_: Exception) {
            }
        }
        return false
    }

    /**
     * Best-effort in-app request. On Android 11+ this opens Settings because
     * the OS blocks background location dialogs inside the app.
     */
    fun requestBackgroundLocation(activity: Activity): Boolean {
        if (hasBackgroundLocation(activity)) return true
        if (!hasForegroundLocation(activity)) return false

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return hasForegroundLocation(activity)
        }

        if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
            if (ContextCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    activity,
                    arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
                    REQ_BACKGROUND_LOCATION,
                )
            }
            return hasBackgroundLocation(activity)
        }

        openBackgroundLocationSettings(activity)
        return hasBackgroundLocation(activity)
    }
}
