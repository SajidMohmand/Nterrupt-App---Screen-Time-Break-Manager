package com.example.nterrupt

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import java.util.concurrent.ConcurrentHashMap
import android.content.BroadcastReceiver


/**
 * Persistent countdown service that uses AlarmManager to ensure countdown continues
 * even when the app is restricted or in background
 */
class PersistentCountdownService : Service() {
    
    companion object {
        const val CHANNEL_ID = "persistent_countdown_channel"
        const val NOTIFICATION_ID = 2001
        const val ACTION_START_COUNTDOWN = "START_COUNTDOWN"
        const val ACTION_STOP_COUNTDOWN = "STOP_COUNTDOWN"
        const val ACTION_UPDATE_COUNTDOWN = "UPDATE_COUNTDOWN"
        const val ACTION_COUNTDOWN_EXPIRED = "COUNTDOWN_EXPIRED"
        
        // Broadcast actions
        const val BROADCAST_COUNTDOWN_UPDATE = "com.example.nterrupt.PERSISTENT_COUNTDOWN_UPDATE"
        const val BROADCAST_COUNTDOWN_EXPIRED = "com.example.nterrupt.PERSISTENT_COUNTDOWN_EXPIRED"
        
        private val activeCountdowns = ConcurrentHashMap<String, CountdownInfo>()
        
        data class CountdownInfo(
            val packageName: String,
            val appName: String,
            val expiryTimestamp: Long,
            val durationMs: Long
        )
        
        fun startCountdown(context: Context, packageName: String, appName: String, durationMs: Long) {
            val intent = Intent(context, PersistentCountdownService::class.java)
            intent.action = ACTION_START_COUNTDOWN
            intent.putExtra("package_name", packageName)
            intent.putExtra("app_name", appName)
            intent.putExtra("duration_ms", durationMs)
            context.startService(intent)
        }
        
        fun stopCountdown(context: Context, packageName: String) {
            val intent = Intent(context, PersistentCountdownService::class.java)
            intent.action = ACTION_STOP_COUNTDOWN
            intent.putExtra("package_name", packageName)
            context.startService(intent)
        }
        
        fun getRemainingTime(packageName: String): Long {
            val countdownInfo = activeCountdowns[packageName] ?: return 0
            val currentTime = System.currentTimeMillis()
            return maxOf(0, countdownInfo.expiryTimestamp - currentTime)
        }
        
        fun isCountdownActive(packageName: String): Boolean {
            val countdownInfo = activeCountdowns[packageName] ?: return false
            val currentTime = System.currentTimeMillis()
            return currentTime < countdownInfo.expiryTimestamp
        }
    }
    
    private lateinit var alarmManager: AlarmManager
    private lateinit var notificationManager: NotificationManager
    
    override fun onCreate() {
        super.onCreate()
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_COUNTDOWN -> {
                val packageName = intent.getStringExtra("package_name") ?: return START_STICKY
                val appName = intent.getStringExtra("app_name") ?: "App"
                val durationMs = intent.getLongExtra("duration_ms", 0)
                
                if (durationMs > 0) {
                    startCountdown(packageName, appName, durationMs)
                }
            }
            ACTION_STOP_COUNTDOWN -> {
                val packageName = intent.getStringExtra("package_name") ?: return START_STICKY
                stopCountdown(packageName)
            }
            ACTION_UPDATE_COUNTDOWN -> {
                updateAllCountdowns()
            }
            ACTION_COUNTDOWN_EXPIRED -> {
                val packageName = intent.getStringExtra("package_name") ?: return START_STICKY
                handleCountdownExpired(packageName)
            }
        }
        
        return START_STICKY
    }
    
    private fun startCountdown(packageName: String, appName: String, durationMs: Long) {
        val currentTime = System.currentTimeMillis()
        val expiryTimestamp = currentTime + durationMs
        
        val countdownInfo = CountdownInfo(packageName, appName, expiryTimestamp, durationMs)
        activeCountdowns[packageName] = countdownInfo
        
        android.util.Log.d("PersistentCountdown", "Started countdown for $packageName: ${durationMs}ms")
        
        // Set up AlarmManager for the expiry time
        setupExpiryAlarm(packageName, expiryTimestamp)
        
        // Start foreground service to keep countdown running
        startForegroundService()
        
        // Start periodic updates
        startPeriodicUpdates()
        
        // Broadcast initial countdown start
        broadcastCountdownUpdate(packageName, durationMs)
    }
    
    private fun stopCountdown(packageName: String) {
        activeCountdowns.remove(packageName)
        cancelExpiryAlarm(packageName)
        
        android.util.Log.d("PersistentCountdown", "Stopped countdown for $packageName")
        
        // If no more countdowns, stop service
        if (activeCountdowns.isEmpty()) {
            stopForeground(true)
            stopSelf()
        }
    }
    
    private fun setupExpiryAlarm(packageName: String, expiryTimestamp: Long) {
        val intent = Intent(this, CountdownExpiredReceiver::class.java)
        intent.action = ACTION_COUNTDOWN_EXPIRED
        intent.putExtra("package_name", packageName)
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            packageName.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Use setExactAndAllowWhileIdle for better reliability
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                expiryTimestamp,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                expiryTimestamp,
                pendingIntent
            )
        }
        
        android.util.Log.d("PersistentCountdown", "Set expiry alarm for $packageName at $expiryTimestamp")
    }
    
    private fun cancelExpiryAlarm(packageName: String) {
        val intent = Intent(this, CountdownExpiredReceiver::class.java)
        intent.action = ACTION_COUNTDOWN_EXPIRED
        intent.putExtra("package_name", packageName)
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            packageName.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager.cancel(pendingIntent)
    }
    
    private fun startPeriodicUpdates() {
        // Use AlarmManager for periodic updates instead of Timer
        val intent = Intent(this, CountdownUpdateReceiver::class.java)
        intent.action = ACTION_UPDATE_COUNTDOWN
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Set up repeating alarm every 5 seconds
        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + 5000,
            5000, // 5 seconds
            pendingIntent
        )
    }
    
    private fun updateAllCountdowns() {
        val currentTime = System.currentTimeMillis()
        val expiredPackages = mutableListOf<String>()
        
        activeCountdowns.forEach { (packageName, countdownInfo) ->
            val remainingTime = maxOf(0, countdownInfo.expiryTimestamp - currentTime)
            
            if (remainingTime <= 0) {
                expiredPackages.add(packageName)
            } else {
                // Broadcast countdown update
                broadcastCountdownUpdate(packageName, remainingTime)
            }
        }
        
        // Handle expired countdowns
        expiredPackages.forEach { packageName ->
            handleCountdownExpired(packageName)
        }
    }
    
    private fun handleCountdownExpired(packageName: String) {
        val countdownInfo = activeCountdowns.remove(packageName)
        if (countdownInfo != null) {
            android.util.Log.d("PersistentCountdown", "Countdown expired for $packageName")
            
            // Broadcast expiry
            broadcastCountdownExpired(packageName)
            
            // Cancel alarm
            cancelExpiryAlarm(packageName)
            
            // Stop service if no more countdowns
            if (activeCountdowns.isEmpty()) {
                stopForeground(true)
                stopSelf()
            }
        }
    }
    
    private fun broadcastCountdownUpdate(packageName: String, remainingTimeMs: Long) {
        val intent = Intent(BROADCAST_COUNTDOWN_UPDATE)
        intent.putExtra("package_name", packageName)
        intent.putExtra("remaining_time_ms", remainingTimeMs)
        sendBroadcast(intent)
    }
    
    private fun broadcastCountdownExpired(packageName: String) {
        val intent = Intent(BROADCAST_COUNTDOWN_EXPIRED)
        intent.putExtra("package_name", packageName)
        sendBroadcast(intent)
    }
    
    private fun startForegroundService() {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
    }
    
    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nterrupt Countdown")
            .setContentText("${activeCountdowns.size} app(s) in cooldown")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Persistent Countdown",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent countdown service for app blocking"
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
            }
            
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
}

/**
 * Broadcast receiver for countdown updates
 */
class CountdownUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == PersistentCountdownService.ACTION_UPDATE_COUNTDOWN) {
            val serviceIntent = Intent(context, PersistentCountdownService::class.java)
            serviceIntent.action = PersistentCountdownService.ACTION_UPDATE_COUNTDOWN
            context?.startService(serviceIntent)
        }
    }
}

/**
 * Broadcast receiver for countdown expiry
 */
class CountdownExpiredReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == PersistentCountdownService.ACTION_COUNTDOWN_EXPIRED) {
            val packageName = intent.getStringExtra("package_name")
            if (packageName != null) {
                val serviceIntent = Intent(context, PersistentCountdownService::class.java)
                serviceIntent.action = PersistentCountdownService.ACTION_COUNTDOWN_EXPIRED
                serviceIntent.putExtra("package_name", packageName)
                context?.startService(serviceIntent)
            }
        }
    }
}
