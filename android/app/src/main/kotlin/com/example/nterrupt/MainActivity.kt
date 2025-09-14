package com.example.nterrupt

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "nterrupt/permissions"
    private val APP_DISCOVERY_CHANNEL = "nterrupt/app_discovery"
    private val MONITORING_CHANNEL = "nterrupt/monitoring"
    private val USAGE_TRACKER_CHANNEL = "nterrupt/usage_tracker"
    private val FOREGROUND_SERVICE_CHANNEL = "nterrupt/foreground_service"
    private val OVERLAY_BLOCKING_CHANNEL = "nterrupt/overlay_blocking"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Permissions channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUsageAccessSettings" -> {
                    openUsageAccessSettings()
                    result.success(null)
                }
                "openAppSettings" -> {
                    openAppSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // App discovery channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_DISCOVERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                "isAppRunning" -> {
                    val packageName = call.argument<String>("packageName")
                    val isRunning = isAppRunning(packageName)
                    result.success(isRunning)
                }
                "getCurrentForegroundApp" -> {
                    val currentApp = getCurrentForegroundApp()
                    result.success(currentApp)
                }
                else -> result.notImplemented()
            }
        }
        
        // Monitoring channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MONITORING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showBlockOverlay" -> {
                    val appName = call.argument<String>("appName")
                    val packageName = call.argument<String>("packageName")
                    showBlockOverlay(appName, packageName)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Usage tracker channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_TRACKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentForegroundApp" -> {
                    val currentApp = getCurrentForegroundApp()
                    result.success(currentApp)
                }
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                else -> result.notImplemented()
            }
        }

        // Foreground service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    NterruptForegroundService.startService(this)
                    result.success(null)
                }
                "stopForegroundService" -> {
                    NterruptForegroundService.stopService(this)
                    result.success(null)
                }
                "blockApp" -> {
                    val appName = call.argument<String>("appName") ?: "App"
                    val packageName = call.argument<String>("packageName") ?: ""
                    val durationMs = convertToLong(call.argument<Any>("durationMs"))

                    if (packageName.isNotEmpty() && durationMs > 0) {
                        NterruptForegroundService.blockApp(this, appName, packageName, durationMs)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid app name, package name, or duration", null)
                    }
                }
                "unblockApp" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        NterruptForegroundService.unblockApp(this, packageName)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid package name", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

// Overlay blocking channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_BLOCKING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverlay" -> {
                    val appName = call.argument<String>("appName") ?: "App"
                    val packageName = call.argument<String>("packageName") ?: ""
                    val durationMs = convertToLong(call.argument<Any>("durationMs"))

                    if (packageName.isNotEmpty() && durationMs > 0) {
                        FullScreenOverlayActivity.showOverlay(this, appName, packageName, durationMs)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Invalid arguments", null)
                    }
                }
                "dismissOverlay" -> {
                    // Send broadcast to dismiss overlay
                    val intent = Intent("com.example.nterrupt.DISMISS_OVERLAY")
                    sendBroadcast(intent)
                    result.success(null)
                }
                "hasOverlayPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        Settings.canDrawOverlays(this)
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                            intent.data = Uri.parse("package:$packageName")
                            startActivity(intent)
                        }
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "updateCountdown" -> {
                    val remainingMs = convertToLong(call.argument<Any>("remainingMs"))
                    // Can be used for additional logic if needed
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }
    private fun convertToLong(value: Any?): Long {
        return when (value) {
            is Int -> value.toLong()
            is Long -> value
            is Double -> value.toLong()
            is Float -> value.toLong()
            is String -> value.toLongOrNull() ?: 0L
            else -> 0L
        }
    }
    
    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.parse("package:$packageName")
        startActivity(intent)
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val installedPackages = pm.getInstalledPackages(PackageManager.GET_META_DATA)
        val apps = mutableListOf<Map<String, Any>>()

        for (packageInfo in installedPackages) {
            val appInfo = packageInfo.applicationInfo
            if (appInfo != null) {
                val appName = appInfo.loadLabel(pm).toString()
                val packageName = packageInfo.packageName
                val isSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0

                apps.add(
                    mapOf(
                        "packageName" to packageName,
                        "appName" to appName,
                        "isSystemApp" to isSystemApp
                    )
                )
            }
        }
        return apps
    }

    private fun isAppRunning(packageName: String?): Boolean {
        if (packageName == null) return false
        
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val runningApps = activityManager.runningAppProcesses
        
        return runningApps?.any { it.processName == packageName } ?: false
    }
    
    private fun getCurrentForegroundApp(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 60,
                time
            )
            
            var mostRecentStats: UsageStats? = null
            for (usageStats in stats) {
                if (mostRecentStats == null || usageStats.lastTimeUsed > mostRecentStats.lastTimeUsed) {
                    mostRecentStats = usageStats
                }
            }
            
            mostRecentStats?.packageName
        } else {
            null
        }
    }
    
    private fun showBlockOverlay(appName: String?, packageName: String?) {
        // This would typically show an overlay window
        // For now, we'll just log it
        println("Blocking app: $appName ($packageName)")
    }
}
