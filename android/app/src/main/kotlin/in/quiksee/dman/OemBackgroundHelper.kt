package `in`.quiksee.dman

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * Opens OEM-specific Autostart / Battery / App-launch screens so FCM can
 * wake Quiksee on Xiaomi, Oppo, Vivo, Realme, Samsung, Huawei, etc.
 *
 * Stock Android only needs battery optimization; Chinese OEMs kill background
 * apps unless Autostart / "Allow background activity" is enabled manually.
 */
object OemBackgroundHelper {

    private const val TAG = "OemBackgroundHelper"

    fun manufacturerLabel(): String {
        val m = Build.MANUFACTURER?.trim().orEmpty()
        val b = Build.BRAND?.trim().orEmpty()
        return when {
            m.isNotEmpty() -> m
            b.isNotEmpty() -> b
            else -> "Android"
        }
    }

    /**
     * Almost every Android OEM restricts background wake. Always guide the
     * driver through battery + autostart / app-details setup.
     */
    fun needsOemAutostart(): Boolean = true

    /**
     * Opens the best available screen so Quiksee can wake on any Android phone:
     * brand Autostart → battery exemption → app details.
     */
    fun openBackgroundSetup(context: Context): Boolean {
        val appCtx = context.applicationContext
        if (openOemAutostartOrBattery(appCtx)) return true
        if (openStockBatteryExemption(appCtx)) return true
        return openAppDetails(appCtx)
    }

    fun openOemAutostartOrBattery(context: Context): Boolean {
        val appCtx = context.applicationContext
        val pkg = appCtx.packageName
        val candidates = oemIntentCandidates(pkg)

        for (intent in candidates) {
            if (tryStart(appCtx, intent)) {
                Log.i(TAG, "Opened OEM screen: ${intent.component ?: intent.action}")
                return true
            }
        }
        return false
    }

    fun openStockBatteryExemption(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val powerManager =
            context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                ?: return false
        if (powerManager.isIgnoringBatteryOptimizations(context.packageName)) {
            return false
        }
        return tryStart(
            context,
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
            },
        )
    }

    fun openAppDetails(context: Context): Boolean {
        return tryStart(
            context,
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
            },
        )
    }

    private fun oemKey(): String {
        return (Build.MANUFACTURER.orEmpty() + " " + Build.BRAND.orEmpty())
            .lowercase()
            .replace(Regex("[^a-z0-9]+"), " ")
            .trim()
            .let { raw ->
                listOf(
                    "xiaomi", "redmi", "poco", "mi",
                    "oppo", "realme", "oneplus", "oplus",
                    "vivo", "iqoo",
                    "huawei", "honor",
                    "samsung",
                    "asus", "meizu", "letv", "leeco",
                    "tecno", "infinix", "itel",
                    "nokia", "nothing", "motorola", "lenovo",
                ).firstOrNull { raw.contains(it) } ?: raw.split(" ").firstOrNull().orEmpty()
            }
    }

    private fun oemIntentCandidates(packageName: String): List<Intent> {
        val key = oemKey()
        val list = mutableListOf<Intent>()

        fun component(pkg: String, cls: String, extras: Map<String, String> = emptyMap()) {
            list.add(
                Intent().apply {
                    component = ComponentName(pkg, cls)
                    extras.forEach { (k, v) -> putExtra(k, v) }
                    putExtra("packageName", packageName)
                    putExtra("package_name", packageName)
                    putExtra("packages", packageName)
                    putExtra("extra_pkgname", packageName)
                },
            )
        }

        when (key) {
            "xiaomi", "redmi", "poco", "mi" -> {
                // Autostart
                component(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                )
                component(
                    "com.miui.securitycenter",
                    "com.miui.powercenter.PowerSettings",
                )
                // App battery saver → No restrictions
                component(
                    "com.miui.powerkeeper",
                    "com.miui.powerkeeper.ui.HiddenAppsConfigActivity",
                    mapOf("package_name" to packageName, "package_label" to "Quiksee"),
                )
            }
            "oppo", "realme", "oneplus", "oplus" -> {
                component(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                )
                component(
                    "com.oppo.safe",
                    "com.oppo.safe.permission.startup.StartupAppListActivity",
                )
                component(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity",
                )
                component(
                    "com.oplus.safecenter",
                    "com.oplus.safecenter.startupapp.view.StartupAppListActivity",
                )
                component(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity",
                )
                component(
                    "com.oneplus.security",
                    "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
                )
            }
            "vivo", "iqoo" -> {
                component(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
                )
                component(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                )
                component(
                    "com.iqoo.secure",
                    "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
                )
                component(
                    "com.vivo.abe",
                    "com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity",
                )
            }
            "huawei", "honor" -> {
                component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                )
                component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                )
                component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity",
                )
                component(
                    "com.hihonor.systemmanager",
                    "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                )
            }
            "samsung" -> {
                // Sleeping apps / never sleeping apps (varies by One UI version)
                component(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity",
                )
                component(
                    "com.samsung.android.sm",
                    "com.samsung.android.sm.ui.battery.BatteryActivity",
                )
                list.add(
                    Intent().apply {
                        action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                        data = Uri.parse("package:$packageName")
                    },
                )
            }
            "asus" -> {
                component(
                    "com.asus.mobilemanager",
                    "com.asus.mobilemanager.autostart.AutoStartActivity",
                )
                component(
                    "com.asus.mobilemanager",
                    "com.asus.mobilemanager.entry.FunctionActivity",
                )
            }
            "letv", "leeco" -> {
                component(
                    "com.letv.android.letvsafe",
                    "com.letv.android.letvsafe.AutobootManageActivity",
                )
            }
            "meizu" -> {
                component(
                    "com.meizu.safe",
                    "com.meizu.safe.permission.SmartBGActivity",
                )
            }
            "tecno", "infinix", "itel" -> {
                component(
                    "com.transsion.phonemanager",
                    "com.transsion.phonemanager.module.appmanager.AppManagerActivity",
                )
                component(
                    "com.ito.pwrmgr",
                    "com.transsion.powermanager.ui.PowerManagerActivity",
                )
            }
            "nokia" -> {
                list.add(
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                )
            }
            else -> {
                list.add(
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                )
            }
        }

        // Universal fallbacks after brand-specific ones
        list.add(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        list.add(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            },
        )
        return list
    }

    private fun tryStart(context: Context, intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(context.packageManager) == null &&
                intent.component != null
            ) {
                // Component may still resolve even if resolveActivity is null on some OEMs.
                try {
                    context.packageManager.getActivityInfo(
                        intent.component!!,
                        PackageManager.MATCH_DEFAULT_ONLY,
                    )
                } catch (_: Exception) {
                    return false
                }
            } else if (intent.resolveActivity(context.packageManager) == null &&
                intent.component == null
            ) {
                return false
            }
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.w(TAG, "Failed intent ${intent.component ?: intent.action}: ${e.message}")
            false
        }
    }
}
