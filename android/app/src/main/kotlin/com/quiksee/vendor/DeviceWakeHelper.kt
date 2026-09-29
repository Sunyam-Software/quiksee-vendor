package com.quiksee.vendor

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import java.util.Locale

object DeviceWakeHelper {

    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun canUseFullScreenIntent(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return notificationManager.canUseFullScreenIntent()
    }

    fun requestBatteryOptimizationExemption(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        if (isIgnoringBatteryOptimizations(context)) return true
        return tryStart(
            context,
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
    }

    fun openBatterySettings(context: Context): Boolean {
        val intents = listOf(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
        for (intent in intents) {
            if (tryStart(context, intent)) return true
        }
        return openAppDetails(context)
    }

    fun openManufacturerAutoStartSettings(context: Context): Boolean {
        val manufacturer = Build.MANUFACTURER?.lowercase(Locale.US).orEmpty()
        val brand = Build.BRAND?.lowercase(Locale.US).orEmpty()

        val targetedIntents = mutableListOf<Intent>()

        when {
            manufacturer.contains("xiaomi") ||
                manufacturer.contains("redmi") ||
                manufacturer.contains("poco") ||
                brand.contains("xiaomi") ||
                brand.contains("redmi") ||
                brand.contains("poco") -> {
                targetedIntents += componentIntent(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                )
            }

            manufacturer.contains("oppo") ||
                manufacturer.contains("realme") ||
                brand.contains("oppo") ||
                brand.contains("realme") -> {
                targetedIntents += componentIntent(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                )
                targetedIntents += componentIntent(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.permission.startup.StartupAppListActivity",
                )
            }

            manufacturer.contains("oneplus") || brand.contains("oneplus") -> {
                targetedIntents += componentIntent(
                    "com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
                )
                targetedIntents += componentIntent(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.permission.startup.StartupAppListActivity",
                )
            }

            manufacturer.contains("vivo") || brand.contains("vivo") -> {
                targetedIntents += componentIntent(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                )
                targetedIntents += componentIntent(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
                )
            }

            manufacturer.contains("huawei") ||
                manufacturer.contains("honor") ||
                brand.contains("honor") -> {
                targetedIntents += componentIntent(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                )
                targetedIntents += componentIntent(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                )
            }

            manufacturer.contains("asus") || brand.contains("asus") -> {
                targetedIntents += componentIntent(
                    "com.asus.mobilemanager",
                    "com.asus.mobilemanager.powersaver.PowerSaverSettings",
                )
            }

            manufacturer.contains("lenovo") || brand.contains("lenovo") -> {
                targetedIntents += componentIntent(
                    "com.lenovo.security",
                    "com.lenovo.security.purebackground.PureBackgroundActivity",
                )
            }

            manufacturer.contains("samsung") || brand.contains("samsung") -> {
                targetedIntents += componentIntent(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity",
                )
                targetedIntents += componentIntent(
                    "com.samsung.android.sm",
                    "com.samsung.android.sm.ui.battery.BatteryActivity",
                )
            }

            manufacturer.contains("motorola") ||
                manufacturer.contains("moto") ||
                brand.contains("motorola") -> {
                targetedIntents += componentIntent(
                    "com.motorola.actions",
                    "com.motorola.actions.ui.BatterySaverSettingsActivity",
                )
            }

            manufacturer.contains("tecno") ||
                manufacturer.contains("infinix") ||
                manufacturer.contains("itel") -> {
                targetedIntents += componentIntent(
                    "com.transsion.phonemanager",
                    "com.transsion.phonemanager.autostart.AutoStartActivity",
                )
            }

            manufacturer.contains("lava") || brand.contains("lava") -> {
                targetedIntents += componentIntent(
                    "com.android.settings",
                    "com.android.settings.Settings\$BatterySaverSettingsActivity",
                )
            }

            manufacturer.contains("nokia") || brand.contains("nokia") -> {
                targetedIntents += componentIntent(
                    "com.evenwell.powersaving",
                    "com.evenwell.powersaving.g3.exception.PowerSaverExceptionActivity",
                )
            }
        }

        targetedIntents += listOf(
            componentIntent(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            ),
            componentIntent(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            ),
            componentIntent(
                "com.oplus.safecenter",
                "com.oplus.safecenter.permission.startup.StartupAppListActivity",
            ),
            componentIntent(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            ),
            componentIntent(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            ),
            componentIntent(
                "com.samsung.android.lool",
                "com.samsung.android.sm.battery.ui.BatteryActivity",
            ),
        )

        for (intent in targetedIntents) {
            if (tryStart(context, intent)) return true
        }

        return openAppDetails(context)
    }

    fun openAppNotificationSettings(context: Context): Boolean {
        val intents = listOf(
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
        for (intent in intents) {
            if (tryStart(context, intent)) return true
        }
        return false
    }

    fun openFullScreenIntentSettings(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        if (canUseFullScreenIntent(context)) return true
        return tryStart(
            context,
            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        ) || openAppDetails(context)
    }

    fun openAppDetails(context: Context): Boolean {
        return tryStart(
            context,
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
    }

    private fun componentIntent(packageName: String, className: String): Intent {
        return Intent().apply {
            component = ComponentName(packageName, className)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    private fun tryStart(context: Context, intent: Intent): Boolean {
        return try {
            if (intent.component != null) {
                context.packageManager.getActivityInfo(intent.component!!, 0)
            }
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
