package com.example.nterrupt

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class NterruptForegroundService : Service() {
    
    companion object {
        const val CHANNEL_ID = "nterrupt_monitoring_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START_SERVICE = "START_SERVICE"
        const val ACTION_STOP_SERVICE = "STOP_SERVICE"
        
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
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                try {
                    // Ensure notification channel is created before starting foreground
                    createNotificationChannel()
                    startForegroundService()
                } catch (e: Exception) {
                    // Log error and stop service if we can't start foreground
                    android.util.Log.e("NterruptService", "Failed to start foreground service", e)
                    stopSelf()
                }
            }
            ACTION_STOP_SERVICE -> {
                try {
                    stopForeground(true)
                    stopSelf()
                } catch (e: Exception) {
                    android.util.Log.e("NterruptService", "Error stopping service", e)
                    stopSelf()
                }
            }
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
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
    
    override fun onDestroy() {
        super.onDestroy()
        stopForeground(true)
    }
}
