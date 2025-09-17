package com.example.nterrupt

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class NterruptForegroundService : Service() {

    private var foregroundCheckTimer: java.util.Timer? = null
    private var countdownTimer: java.util.Timer? = null

    // Persistent blocking map: packageName → expiryTimestamp
    private val blockedAppsMap = mutableMapOf<String, Long>()

    // Additional info for blocked apps (instance-based)
    private val blockedAppsInfo = mutableMapOf<String, BlockedAppInfo>()

    // Countdown broadcast listeners (overlay activities)
    private val countdownListeners = mutableSetOf<String>()
    
    // SharedPreferences for persistent countdown storage
    private lateinit var sharedPreferences: SharedPreferences

    data class BlockedAppInfo(
        val appName: String,
        val packageName: String,
        val blockId: String
    )

    companion object {
        const val CHANNEL_ID = "nterrupt_monitoring_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START_SERVICE = "START_SERVICE"
        const val ACTION_STOP_SERVICE = "STOP_SERVICE"
        const val ACTION_BLOCK_APP = "BLOCK_APP"
        const val ACTION_UNBLOCK_APP = "UNBLOCK_APP"
        const val ACTION_BLOCK_ENDED = "BLOCK_ENDED"
        const val ACTION_CHECK_FOREGROUND = "CHECK_FOREGROUND"
        const val ACTION_GET_REMAINING_TIME = "GET_REMAINING_TIME"
        const val ACTION_SUBSCRIBE_COUNTDOWN = "SUBSCRIBE_COUNTDOWN"
        const val ACTION_UNSUBSCRIBE_COUNTDOWN = "UNSUBSCRIBE_COUNTDOWN"

        // Broadcast actions for countdown updates
        const val BROADCAST_COUNTDOWN_UPDATE = "com.example.nterrupt.COUNTDOWN_UPDATE"
        const val BROADCAST_BLOCK_EXPIRED = "com.example.nterrupt.BLOCK_EXPIRED"

        fun startService(context: Context) {
            val intent = Intent(context, NterruptForegroundService::class.java)
            intent.action = ACTION_START_SERVICE
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            val intent = Intent(context, NterruptForegroundService::class.java)
            intent.action = ACTION_STOP_SERVICE
            context.startService(intent)
        }

        fun blockApp(context: Context, appName: String, packageName: String, durationMs: Long) {
            val intent = Intent(context, NterruptForegroundService::class.java)
            intent.action = ACTION_BLOCK_APP
            intent.putExtra("app_name", appName)
            intent.putExtra("package_name", packageName)
            intent.putExtra("duration_ms", durationMs)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun getRemainingTime(context: Context, packageName: String) {
            val intent = Intent(context, NterruptForegroundService::class.java)
            intent.action = ACTION_GET_REMAINING_TIME
            intent.putExtra("package_name", packageName)
            context.startService(intent)
        }

        fun subscribeToCountdown(context: Context, packageName: String) {
            val intent = Intent(context, NterruptForegroundService::class.java)
            intent.action = ACTION_SUBSCRIBE_COUNTDOWN
            intent.putExtra("package_name", packageName)
            context.startService(intent)
        }

        fun unsubscribeFromCountdown(context: Context, packageName: String) {
            val intent = Intent(context, NterruptForegroundService::class.java)
            intent.action = ACTION_UNSUBSCRIBE_COUNTDOWN
            intent.putExtra("package_name", packageName)
            context.startService(intent)
        }

        fun unblockApp(context: Context, packageName: String) {
            val intent = Intent(context, NterruptForegroundService::class.java)
            intent.action = ACTION_UNBLOCK_APP
            intent.putExtra("package_name", packageName)
            context.startService(intent)
        }
        
        // Static method to get block info - we'll store it in a static map
        private val staticBlockedAppsInfo = mutableMapOf<String, BlockedAppInfo>()
        private val staticBlockedAppsMap = mutableMapOf<String, Long>()
        
        fun getBlockInfoStatic(packageName: String): BlockedAppInfo? {
            return staticBlockedAppsInfo[packageName]
        }
        
        fun setBlockInfoStatic(packageName: String, blockInfo: BlockedAppInfo) {
            staticBlockedAppsInfo[packageName] = blockInfo
        }
        
        fun setBlockExpiryStatic(packageName: String, expiryTimestamp: Long) {
            staticBlockedAppsMap[packageName] = expiryTimestamp
        }
        
        fun removeBlockInfoStatic(packageName: String) {
            staticBlockedAppsInfo.remove(packageName)
            staticBlockedAppsMap.remove(packageName)
        }
        
        fun getRemainingBlockTime(packageName: String): Long {
            val expiryTimestamp = staticBlockedAppsMap[packageName] ?: return 0L
            val currentTime = System.currentTimeMillis()
            return maxOf(0, expiryTimestamp - currentTime)
        }
        
        // SharedPreferences methods for persistent countdown storage
        fun saveRemainingTime(context: Context, packageName: String, remainingTimeMs: Long) {
            val prefs = context.getSharedPreferences("nterrupt_countdown", Context.MODE_PRIVATE)
            prefs.edit().putLong("remaining_time_$packageName", remainingTimeMs).apply()
            android.util.Log.d("NterruptService", "Saved remaining time for $packageName: ${remainingTimeMs}ms")
        }
        
        fun getRemainingTimeFromPrefs(context: Context, packageName: String): Long {
            val prefs = context.getSharedPreferences("nterrupt_countdown", Context.MODE_PRIVATE)
            val remainingTime = prefs.getLong("remaining_time_$packageName", 0L)
            android.util.Log.d("NterruptService", "Retrieved remaining time for $packageName: ${remainingTime}ms")
            
            // Debug: Check if the key exists
            val allKeys = prefs.all
            android.util.Log.d("NterruptService", "All SharedPreferences keys: $allKeys")
            
            return remainingTime
        }
        
        fun clearRemainingTime(context: Context, packageName: String) {
            val prefs = context.getSharedPreferences("nterrupt_countdown", Context.MODE_PRIVATE)
            prefs.edit().remove("remaining_time_$packageName").apply()
            android.util.Log.d("NterruptService", "Cleared remaining time for $packageName")
        }
    }

    /** INSTANCE-BASED getBlockInfo **/
    fun getBlockInfo(packageName: String): BlockedAppInfo? {
        return blockedAppsInfo[packageName]
    }

    // The rest of your service implementation remains unchanged...
    // (All other methods: onCreate, onStartCommand, startAppBlock, endAppBlock, etc.)
    // I only moved getBlockInfo() out of the companion object.

    override fun onCreate() {
        super.onCreate()
        sharedPreferences = getSharedPreferences("nterrupt_countdown", Context.MODE_PRIVATE)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                try {
                    createNotificationChannel()
                    startForegroundService()
                    startForegroundAppMonitoring()
                } catch (e: Exception) {
                    android.util.Log.e("NterruptService", "Failed to start foreground service", e)
                    stopSelf()
                }
            }
            ACTION_STOP_SERVICE -> {
                try {
                    stopForegroundAppMonitoring()
                    stopForeground(true)
                    stopSelf()
                } catch (e: Exception) {
                    android.util.Log.e("NterruptService", "Error stopping service", e)
                    stopSelf()
                }
            }
            ACTION_BLOCK_APP -> {
                val appName = intent?.getStringExtra("app_name") ?: "App"
                val packageName = intent?.getStringExtra("package_name") ?: ""
                val durationMs = intent?.getLongExtra("duration_ms", 0) ?: 0

                if (packageName.isNotEmpty() && durationMs > 0) {
                    startAppBlock(appName, packageName, durationMs)
                }
            }
            ACTION_UNBLOCK_APP -> {
                val packageName = intent?.getStringExtra("package_name") ?: ""
                if (packageName.isNotEmpty()) {
                    endAppBlock(packageName)
                }
            }
            ACTION_BLOCK_ENDED -> {
                val blockId = intent?.getStringExtra("block_id") ?: ""
                handleBlockEnded(blockId)
            }
            ACTION_CHECK_FOREGROUND -> {
                checkForegroundApp()
            }
            "UPDATE_COUNTDOWN" -> {
                val remainingMs = intent?.getLongExtra("remaining_ms", 0) ?: 0
                updateCountdownNotification(remainingMs)
            }
            ACTION_GET_REMAINING_TIME -> {
                val packageName = intent?.getStringExtra("package_name") ?: ""
                if (packageName.isNotEmpty()) {
                    val remainingTime = getRemainingBlockTime(packageName)
                    broadcastRemainingTime(packageName, remainingTime)
                }
            }
            ACTION_SUBSCRIBE_COUNTDOWN -> {
                val packageName = intent?.getStringExtra("package_name") ?: ""
                if (packageName.isNotEmpty()) {
                    countdownListeners.add(packageName)
                    val remainingTime = getRemainingBlockTime(packageName)
                    if (remainingTime > 0) {
                        broadcastCountdownUpdate(packageName, remainingTime)
                    }
                }
            }
            ACTION_UNSUBSCRIBE_COUNTDOWN -> {
                val packageName = intent?.getStringExtra("package_name") ?: ""
                if (packageName.isNotEmpty()) {
                    countdownListeners.remove(packageName)
                }
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Delete existing channel if it exists (in case of issues)
            try {
                notificationManager.deleteNotificationChannel(CHANNEL_ID)
            } catch (e: Exception) {
                // Ignore errors when deleting
            }
            
            // Create new channel with proper settings
            val channelName = "Nterrupt Monitoring"
            val channelDescription = "App usage monitoring service"
            val importance = NotificationManager.IMPORTANCE_LOW
            
            val channel = NotificationChannel(CHANNEL_ID, channelName, importance).apply {
                description = channelDescription
                // Explicitly set these to prevent issues
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            
            notificationManager.createNotificationChannel(channel)
            
            // Verify the channel was created
            val createdChannel = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (createdChannel == null) {
                throw RuntimeException("Failed to create notification channel")
            }
        }
    }
    
    private fun startForegroundService() {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
    }
    
    private fun createNotification(): Notification {
        // Create intent that opens MainActivity when notification is tapped
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, pendingIntentFlags
        )
        
        // Use your custom PNG icon
        val iconResource = R.drawable.ic_notification
        
        // Build notification with all required fields explicitly set
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nterrupt Monitoring")
            .setContentText("Monitoring app usage and enforcing limits")
            .setSmallIcon(iconResource)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        
        // Set priority based on Android version
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // For Android 8+, priority is handled by the channel
            builder.setPriority(NotificationCompat.PRIORITY_LOW)
        } else {
            // For older versions
            builder.setPriority(NotificationCompat.PRIORITY_LOW)
        }
        
        // Additional safety settings
        builder.setDefaults(0) // No defaults (sound, vibration, etc.)
        builder.setSound(null)
        builder.setVibrate(null)
        builder.setLights(0, 0, 0)
        
        try {
            return builder.build()
        } catch (e: Exception) {
            // Fallback: create the most basic notification possible
            return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Monitoring")
                .setContentText("Service running")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .build()
        }
    }
    
    private fun startAppBlock(appName: String, packageName: String, durationMs: Long) {
        val currentTime = System.currentTimeMillis()
        val expiryTimestamp = currentTime + durationMs
        val blockId = "${packageName}_${currentTime}"
        
        // Set expiry time in persistent map
        blockedAppsMap[packageName] = expiryTimestamp
        
        // Store additional info
        val blockInfo = BlockedAppInfo(appName, packageName, blockId)
        blockedAppsInfo[packageName] = blockInfo
        
        // Also store in static map for access from static context
        setBlockInfoStatic(packageName, blockInfo)
        setBlockExpiryStatic(packageName, expiryTimestamp)
        
        android.util.Log.d("NterruptService", "Started blocking $appName until timestamp: $expiryTimestamp (${durationMs}ms from now)")
        
        // Save initial remaining time to SharedPreferences
        saveRemainingTime(this, packageName, durationMs)
        android.util.Log.d("NterruptService", "Initial save: $packageName = ${durationMs}ms")
        
        // Use persistent countdown service for reliable countdown timing
        PersistentCountdownService.startCountdown(this, packageName, appName, durationMs)
        
        // Start background countdown for this app (fallback)
        startBackgroundCountdown()
        
        // Immediately check if we need to show overlay
        checkAndShowOverlayIfNeeded(packageName)
        
        // Update notification to show active blocks
        updateNotificationWithBlocks()
    }
    
    private fun endAppBlock(packageName: String) {
        blockedAppsMap.remove(packageName)
        blockedAppsInfo.remove(packageName)
        
        // Also remove from static map
        removeBlockInfoStatic(packageName)
        
        // Clear remaining time from SharedPreferences
        clearRemainingTime(this, packageName)
        
        // Stop persistent countdown for this package
        PersistentCountdownService.stopCountdown(this, packageName)
        
        // Clear overlay state for this package
        FullScreenOverlayActivity.clearOverlayStateForPackage(packageName)
        
        android.util.Log.d("NterruptService", "Ended blocking for $packageName")
        
        // Update notification
        updateNotificationWithBlocks()
    }
    
    private fun handleBlockEnded(blockId: String) {
        // Find and remove the block with this ID
        val packageToRemove = blockedAppsInfo.entries.find { it.value.blockId == blockId }?.key
        packageToRemove?.let { 
            endAppBlock(it)
        }
    }
    
    private fun startForegroundAppMonitoring() {
        // Start timer to check foreground app every 2 seconds
        foregroundCheckTimer?.cancel()
        foregroundCheckTimer = java.util.Timer()
        foregroundCheckTimer?.scheduleAtFixedRate(object : java.util.TimerTask() {
            override fun run() {
                checkForegroundApp()
            }
        }, 0, 2000) // Check every 2 seconds
        
        // Also start background countdown monitoring if we have blocked apps
        if (blockedAppsMap.isNotEmpty()) {
            startBackgroundCountdown()
        }
    }
    
    private fun stopForegroundAppMonitoring() {
        foregroundCheckTimer?.cancel()
        foregroundCheckTimer = null
    }
    
    private fun startBackgroundCountdown() {
        // Stop existing countdown timer
        countdownTimer?.cancel()
        
        // Start continuous background countdown that runs every second
        countdownTimer = java.util.Timer()
        countdownTimer?.scheduleAtFixedRate(object : java.util.TimerTask() {
            override fun run() {
                processBackgroundCountdown()
            }
        }, 0, 1000) // Update every second
        
        android.util.Log.d("NterruptService", "Started background countdown timer")
    }
    
    private fun stopBackgroundCountdown() {
        countdownTimer?.cancel()
        countdownTimer = null
        android.util.Log.d("NterruptService", "Stopped background countdown timer")
    }
    
    private fun processBackgroundCountdown() {
        val currentTime = System.currentTimeMillis()
        val expiredPackages = mutableListOf<String>()
        
        android.util.Log.d("NterruptService", "Processing background countdown for ${blockedAppsMap.size} blocked apps, ${countdownListeners.size} listeners")
        
        // Check all blocked apps and update their countdowns
        blockedAppsMap.forEach { (packageName, expiryTimestamp) ->
            val remainingTime = maxOf(0, expiryTimestamp - currentTime)
            
            if (remainingTime <= 0) {
                // Block has expired
                expiredPackages.add(packageName)
                android.util.Log.d("NterruptService", "Block expired for $packageName")
            } else {
                // Save remaining time to SharedPreferences on every tick
                saveRemainingTime(this, packageName, remainingTime)
                android.util.Log.d("NterruptService", "Tick save: $packageName = ${remainingTime}ms")
                
                // Broadcast countdown update if anyone is listening
                if (countdownListeners.contains(packageName)) {
                    broadcastCountdownUpdate(packageName, remainingTime)
                } else {
                    // Log that we have a block but no listeners
                    android.util.Log.d("NterruptService", "Block active for $packageName (${remainingTime}ms remaining) but no listeners")
                }
            }
        }
        
        // Remove expired blocks
        expiredPackages.forEach { packageName ->
            broadcastBlockExpired(packageName)
            endAppBlock(packageName)
        }
        
        // Stop countdown timer if no more blocks
        if (blockedAppsMap.isEmpty()) {
            android.util.Log.d("NterruptService", "No more blocked apps, stopping background countdown")
            stopBackgroundCountdown()
        }
    }
    
    private fun getRemainingBlockTime(packageName: String): Long {
        val expiryTimestamp = blockedAppsMap[packageName] ?: return 0
        val currentTime = System.currentTimeMillis()
        return maxOf(0, expiryTimestamp - currentTime)
    }
    
    private fun broadcastCountdownUpdate(packageName: String, remainingTimeMs: Long) {
        val intent = Intent(BROADCAST_COUNTDOWN_UPDATE)
        intent.putExtra("package_name", packageName)
        intent.putExtra("remaining_time_ms", remainingTimeMs)
        sendBroadcast(intent)
        
        val minutes = (remainingTimeMs / 1000) / 60
        val seconds = (remainingTimeMs / 1000) % 60
        android.util.Log.d("NterruptService", "Broadcasting countdown update for $packageName: ${String.format("%02d:%02d", minutes, seconds)} (${remainingTimeMs}ms)")
    }
    
    private fun broadcastBlockExpired(packageName: String) {
        val intent = Intent(BROADCAST_BLOCK_EXPIRED)
        intent.putExtra("package_name", packageName)
        sendBroadcast(intent)
    }
    
    private fun broadcastRemainingTime(packageName: String, remainingTimeMs: Long) {
        val intent = Intent("com.example.nterrupt.REMAINING_TIME_RESPONSE")
        intent.putExtra("package_name", packageName)
        intent.putExtra("remaining_time_ms", remainingTimeMs)
        sendBroadcast(intent)
    }
    
    private fun checkForegroundApp() {
        try {
            // First, clean up any expired blocks
            cleanupExpiredBlocks()
            
            val currentApp = getCurrentForegroundApp()
            if (currentApp != null) {
                checkAndShowOverlayIfNeeded(currentApp)
            }
        } catch (e: Exception) {
            android.util.Log.e("NterruptService", "Error checking foreground app", e)
        }
    }
    
    private fun checkAndShowOverlayIfNeeded(packageName: String) {
        val expiryTimestamp = blockedAppsMap[packageName]
        if (expiryTimestamp != null) {
            val currentTime = System.currentTimeMillis()
            
            if (currentTime < expiryTimestamp) {
                // App is still blocked, show overlay with remaining time
                val blockInfo = blockedAppsInfo[packageName]
                if (blockInfo != null) {
                    // Always show overlay when blocked app becomes foreground
                    // This ensures overlay is shown every time the app is opened during cooldown
                    android.util.Log.d("NterruptService", "Blocked app $packageName is in foreground, showing overlay")
                    showBlockOverlayWithExpiry(blockInfo.appName, packageName, expiryTimestamp)
                    
                    // Ensure persistent countdown is running
                    val remainingTime = expiryTimestamp - currentTime
                    PersistentCountdownService.startCountdown(this, packageName, blockInfo.appName, remainingTime)
                }
            } else {
                // Block time has expired, remove it
                endAppBlock(packageName)
            }
        }
    }
    
    private fun cleanupExpiredBlocks() {
        val currentTime = System.currentTimeMillis()
        val expiredPackages = blockedAppsMap.filter { (_, expiryTimestamp) -> 
            currentTime >= expiryTimestamp 
        }.keys.toList()
        
        expiredPackages.forEach { packageName ->
            endAppBlock(packageName)
        }
    }
    
    private fun getCurrentForegroundApp(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
            val time = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 60,
                time
            )
            
            var mostRecentStats: android.app.usage.UsageStats? = null
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
    
    private fun showBlockOverlayWithExpiry(appName: String, packageName: String, expiryTimestamp: Long) {
        try {
            // Calculate remaining time based on expiry timestamp
            val currentTime = System.currentTimeMillis()
            val remainingTimeMs = maxOf(0, expiryTimestamp - currentTime)
            
            if (remainingTimeMs > 0) {
                // Dismiss any existing overlay for this package first
                val dismissIntent = Intent("com.example.nterrupt.DISMISS_OVERLAY")
                dismissIntent.putExtra("package_name", packageName)
                sendBroadcast(dismissIntent)
                
                // Small delay to ensure previous overlay is dismissed
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    // Show overlay with calculated remaining time
                    FullScreenOverlayActivity.showOverlayWithExpiry(this, appName, packageName, expiryTimestamp)
                    android.util.Log.d("NterruptService", "Showing overlay for $appName with ${remainingTimeMs}ms remaining")
                }, 100) // 100ms delay
            } else {
                // Time has expired, remove block
                endAppBlock(packageName)
            }
        } catch (e: Exception) {
            android.util.Log.e("NterruptService", "Error showing block overlay", e)
        }
    }
    
    private fun updateCountdownNotification(remainingMs: Long) {
        try {
            val minutes = (remainingMs / 1000) / 60
            val seconds = (remainingMs / 1000) % 60
            val countdownText = String.format("Countdown: %02d:%02d", minutes, seconds)
            
            val notification = createNotificationWithText("App blocking active - $countdownText")
            val notificationManager = NotificationManagerCompat.from(this)
            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            android.util.Log.e("NterruptService", "Error updating countdown notification", e)
        }
    }
    
    private fun updateNotificationWithBlocks() {
        // Clean up expired blocks first
        cleanupExpiredBlocks()
        
        val activeBlocks = blockedAppsMap.size
        val notification = if (activeBlocks > 0) {
            val blockedAppNames = blockedAppsInfo.values.joinToString(", ") { it.appName }
            createNotificationWithText("Blocking $activeBlocks app(s): $blockedAppNames")
        } else {
            createNotification()
        }
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    private fun createNotificationWithText(contentText: String): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, pendingIntentFlags
        )
        
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nterrupt Monitoring")
            .setContentText(contentText)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setAutoCancel(false)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setDefaults(0)
            .setSound(null)
            .setVibrate(null)
            .setLights(0, 0, 0)
        
        return builder.build()
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        
        // When the app is closed, check if any apps should still be blocked
        android.util.Log.d("NterruptService", "App task removed - checking for active blocks")
        
        // Clean up expired blocks
        cleanupExpiredBlocks()
        
        // If there are still active blocks, ensure the service continues running
        if (blockedAppsMap.isNotEmpty()) {
            android.util.Log.d("NterruptService", "Keeping service alive for ${blockedAppsMap.size} active blocks")
            
            // Check if we need to show overlay for currently foreground app
            val currentApp = getCurrentForegroundApp()
            if (currentApp != null) {
                checkAndShowOverlayIfNeeded(currentApp)
            }
            
            // Ensure persistent countdown service is running for all active blocks
            blockedAppsMap.forEach { (packageName, expiryTimestamp) ->
                val remainingTime = maxOf(0, expiryTimestamp - System.currentTimeMillis())
                if (remainingTime > 0) {
                    val blockInfo = blockedAppsInfo[packageName]
                    if (blockInfo != null) {
                        // Ensure persistent countdown is running
                        PersistentCountdownService.startCountdown(
                            this, 
                            packageName, 
                            blockInfo.appName, 
                            remainingTime
                        )
                        android.util.Log.d("NterruptService", "Ensured persistent countdown for $packageName")
                        
                        // Recreate overlay if needed
                        FullScreenOverlayActivity.recreateOverlayIfNeeded(this, packageName)
                    }
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopForegroundAppMonitoring()
        
        // Stop background countdown
        stopBackgroundCountdown()
        
        // Clear all overlay states
        FullScreenOverlayActivity.clearAllOverlayStates()
        
        stopForeground(true)
    }
}
