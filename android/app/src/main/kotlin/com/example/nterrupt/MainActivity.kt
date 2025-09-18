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
    private val BACKGROUND_COUNTDOWN_CHANNEL = "nterrupt/background_countdown"
    private val PERSISTENT_COUNTDOWN_CHANNEL = "nterrupt/persistent_countdown"
    
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
                "blockApp" -> {
                    val appName = call.argument<String>("appName") ?: "App"
                    val packageName = call.argument<String>("packageName") ?: ""
                    val durationMs = convertToLong(call.argument<Any>("durationMs"))
                    
                    if (packageName.isNotEmpty() && durationMs > 0) {
                        // Start the foreground service to block the app
                        NterruptForegroundService.startService(this)
                        
                        // Block the app using the service
                        NterruptForegroundService.blockApp(this, appName, packageName, durationMs)
                        
                        android.util.Log.d("MainActivity", "Blocked app $packageName for ${durationMs}ms via usage tracker channel")
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Package name and duration are required", null)
                    }
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
                // Persistent countdown service methods
                "startCountdown" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val appName = call.argument<String>("appName") ?: "App"
                    val durationMs = call.argument<Long>("durationMs") ?: 0L
                    
                    if (packageName.isNotEmpty() && durationMs > 0) {
                        PersistentCountdownService.startCountdown(this, packageName, appName, durationMs)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Package name and duration are required", null)
                    }
                }
                "stopCountdown" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        PersistentCountdownService.stopCountdown(this, packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "getRemainingTime" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        val remainingTime = PersistentCountdownService.getRemainingTime(packageName)
                        result.success(remainingTime)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "isCountdownActive" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        val isActive = PersistentCountdownService.isCountdownActive(packageName)
                        result.success(isActive)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "stopAllCountdowns" -> {
                    // This would require implementing a method to stop all countdowns
                    // For now, just return success
                    result.success(true)
                }
                "blockApp" -> {
                    val appName = call.argument<String>("appName") ?: "App"
                    val packageName = call.argument<String>("packageName") ?: ""
                    val durationMs = call.argument<Long>("durationMs") ?: 0L
                    
                    if (packageName.isNotEmpty() && durationMs > 0) {
                        // Start the foreground service to block the app
                        NterruptForegroundService.startService(this)
                        
                        // Block the app using the service
                        NterruptForegroundService.blockApp(this, appName, packageName, durationMs)
                        
                        android.util.Log.d("MainActivity", "Blocked app $packageName for ${durationMs}ms via Flutter call")
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Package name and duration are required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Background countdown channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_COUNTDOWN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRemainingTime" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        // Start the service to get remaining time
                        NterruptForegroundService.getRemainingTime(this, packageName)
                        
                        // For immediate response, we can also check directly
                        // The service will broadcast the result
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "isAppBlocked" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        // This would require service integration to check if app is currently blocked
                        // For now, return false as placeholder
                        result.success(false)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "getAllBlockedApps" -> {
                    // This would require service integration to get all currently blocked apps
                    // For now, return empty list as placeholder
                    result.success(emptyList<Map<String, Any>>())
                }
                else -> result.notImplemented()
            }
        }
        
        // Persistent countdown channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERSISTENT_COUNTDOWN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCountdown" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val appName = call.argument<String>("appName") ?: "App"
                    val durationMs = convertToLong(call.argument<Any>("durationMs"))
                    
                    if (packageName.isNotEmpty() && durationMs > 0) {
                        PersistentCountdownService.startCountdown(this, packageName, appName, durationMs)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Package name and duration are required", null)
                    }
                }
                "stopCountdown" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        PersistentCountdownService.stopCountdown(this, packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "getRemainingTime" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        val remainingTime = PersistentCountdownService.getRemainingTime(packageName)
                        result.success(remainingTime)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "isCountdownActive" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    if (packageName.isNotEmpty()) {
                        val isActive = PersistentCountdownService.isCountdownActive(packageName)
                        result.success(isActive)
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                "stopAllCountdowns" -> {
                    // This would require implementing a method to stop all countdowns
                    // For now, just return success
                    result.success(true)
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
        val installedPackages = pm.getInstalledPackages(PackageManager.GET_META_DATA or PackageManager.GET_PERMISSIONS)
        val apps = mutableListOf<Map<String, Any>>()

        for (packageInfo in installedPackages) {
            val appInfo = packageInfo.applicationInfo
            if (appInfo != null) {
                // Check if the app has a launch intent (is launchable)
                val launchIntent = pm.getLaunchIntentForPackage(packageInfo.packageName)
                if (launchIntent != null) {
                    val appName = appInfo.loadLabel(pm).toString()
                    val packageName = packageInfo.packageName
                    
                    // Check if it's a system app (but still include it if it's launchable)
                    val isSystemApp = (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
                    
                    // Get app icon as base64 string
                    val icon = appInfo.loadIcon(pm)
                    val iconBase64 = iconToBase64(icon)

                    apps.add(
                        mapOf(
                            "packageName" to packageName,
                            "appName" to appName,
                            "isSystemApp" to isSystemApp,
                            "iconBase64" to iconBase64
                        )
                    )
                }
            }
        }
        return apps
    }
    
    private fun iconToBase64(icon: android.graphics.drawable.Drawable): String {
        return try {
            val bitmap = when (icon) {
                is android.graphics.drawable.BitmapDrawable -> icon.bitmap
                else -> {
                    val bitmap = android.graphics.Bitmap.createBitmap(
                        icon.intrinsicWidth, icon.intrinsicHeight, android.graphics.Bitmap.Config.ARGB_8888
                    )
                    val canvas = android.graphics.Canvas(bitmap)
                    icon.setBounds(0, 0, canvas.width, canvas.height)
                    icon.draw(canvas)
                    bitmap
                }
            }
            
            val outputStream = java.io.ByteArrayOutputStream()
            bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, outputStream)
            val byteArray = outputStream.toByteArray()
            android.util.Base64.encodeToString(byteArray, android.util.Base64.DEFAULT)
        } catch (e: Exception) {
            "" // Return empty string if icon conversion fails
        }
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
