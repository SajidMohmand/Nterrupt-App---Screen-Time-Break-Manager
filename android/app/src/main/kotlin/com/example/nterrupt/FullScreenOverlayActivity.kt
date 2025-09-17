package com.example.nterrupt

import android.app.Activity
import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class FullScreenOverlayActivity : Activity() {
    
    private lateinit var countdownText: TextView
    private lateinit var appNameText: TextView
    private lateinit var messageText: TextView
    private lateinit var appIconView: ImageView
    private var packageName: String = ""
    
    // Broadcast receiver for countdown updates from persistent service
    private val countdownReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            android.util.Log.d("OverlayActivity", "Received broadcast: ${intent?.action}")
            
            when (intent?.action) {
                PersistentCountdownService.BROADCAST_COUNTDOWN_UPDATE -> {
                    val receivedPackageName = intent.getStringExtra("package_name") ?: ""
                    val remainingTimeMs = intent.getLongExtra("remaining_time_ms", 0)
                    
                    android.util.Log.d("OverlayActivity", "Persistent countdown update for $receivedPackageName: ${remainingTimeMs}ms (our package: $packageName)")
                    
                    if (receivedPackageName == packageName) {
                        updateCountdownDisplay(remainingTimeMs)
                    } else {
                        android.util.Log.d("OverlayActivity", "Package name mismatch, ignoring update")
                    }
                }
                PersistentCountdownService.BROADCAST_COUNTDOWN_EXPIRED -> {
                    val receivedPackageName = intent.getStringExtra("package_name") ?: ""
                    android.util.Log.d("OverlayActivity", "Persistent countdown expired for $receivedPackageName (our package: $packageName)")
                    
                    if (receivedPackageName == packageName) {
                        onBlockExpired()
                    }
                }
                // Fallback to old service for backward compatibility
                NterruptForegroundService.BROADCAST_COUNTDOWN_UPDATE -> {
                    val receivedPackageName = intent.getStringExtra("package_name") ?: ""
                    val remainingTimeMs = intent.getLongExtra("remaining_time_ms", 0)
                    
                    android.util.Log.d("OverlayActivity", "Legacy countdown update for $receivedPackageName: ${remainingTimeMs}ms (our package: $packageName)")
                    
                    if (receivedPackageName == packageName) {
                        updateCountdownDisplay(remainingTimeMs)
                    }
                }
                NterruptForegroundService.BROADCAST_BLOCK_EXPIRED -> {
                    val receivedPackageName = intent.getStringExtra("package_name") ?: ""
                    android.util.Log.d("OverlayActivity", "Legacy block expired for $receivedPackageName (our package: $packageName)")
                    
                    if (receivedPackageName == packageName) {
                        onBlockExpired()
                    }
                }
            }
        }
    }
    
    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.nterrupt.DISMISS_OVERLAY") {
                val targetPackage = intent?.getStringExtra("package_name")
                // If no specific package is targeted, or if this overlay is for the targeted package, dismiss it
                if (targetPackage == null || targetPackage == packageName) {
                    android.util.Log.d("OverlayActivity", "Dismissing overlay for $packageName")
                    finish()
                }
            }
        }
    }
    
    companion object {
        const val EXTRA_APP_NAME = "app_name"
        const val EXTRA_PACKAGE_NAME = "package_name"
        const val EXTRA_EXPIRY_TIMESTAMP = "expiry_timestamp"
        
        // Static variables to track overlay state per package
        private val packageOverlayStates = mutableMapOf<String, Long>() // packageName → expiryTimestamp
        
        fun showOverlay(context: Context, appName: String, packageName: String, durationMs: Long) {
            val currentTime = System.currentTimeMillis()
            val expiryTimestamp = currentTime + durationMs
            showOverlayWithExpiry(context, appName, packageName, expiryTimestamp)
        }
        
        fun showOverlayWithExpiry(context: Context, appName: String, packageName: String, expiryTimestamp: Long) {
            val currentTime = System.currentTimeMillis()
            
            // Check if overlay is already active for this package
            val existingExpiry = packageOverlayStates[packageName]
            if (existingExpiry != null && currentTime < existingExpiry) {
                // Overlay is still active, just bring to front
                startOverlayActivity(context, appName, packageName, expiryTimestamp)
                return
            }
            
            // Update state and start new overlay
            packageOverlayStates[packageName] = expiryTimestamp
            startOverlayActivity(context, appName, packageName, expiryTimestamp)
        }
        
        private fun startOverlayActivity(context: Context, appName: String, packageName: String, expiryTimestamp: Long) {
            val intent = Intent(context, FullScreenOverlayActivity::class.java).apply {
                putExtra(EXTRA_APP_NAME, appName)
                putExtra(EXTRA_PACKAGE_NAME, packageName)
                putExtra(EXTRA_EXPIRY_TIMESTAMP, expiryTimestamp)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_SINGLE_TOP or
                       Intent.FLAG_ACTIVITY_NO_HISTORY or
                       Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                       Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT or
                       Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            context.startActivity(intent)
        }
        
        fun clearOverlayStateForPackage(packageName: String) {
            packageOverlayStates.remove(packageName)
        }
        
        fun clearAllOverlayStates() {
            packageOverlayStates.clear()
        }
        
        fun isOverlayActive(packageName: String): Boolean {
            val expiryTimestamp = packageOverlayStates[packageName] ?: return false
            return System.currentTimeMillis() < expiryTimestamp
        }
        
        fun getRemainingTime(packageName: String): Long {
            val expiryTimestamp = packageOverlayStates[packageName] ?: return 0
            val currentTime = System.currentTimeMillis()
            return maxOf(0, expiryTimestamp - currentTime)
        }
        
        fun recreateOverlayIfNeeded(context: Context, packageName: String) {
            // Check SharedPreferences first
            val prefsRemainingTime = NterruptForegroundService.getRemainingTimeFromPrefs(context, packageName)
            val persistentRemainingTime = PersistentCountdownService.getRemainingTime(packageName)
            val remainingTime = maxOf(prefsRemainingTime, persistentRemainingTime)
            
            if (remainingTime > 0) {
                // Get block info from the static method
                val blockInfo = NterruptForegroundService.getBlockInfoStatic(packageName)
                if (blockInfo != null) {
                    android.util.Log.d("OverlayActivity", "Recreating overlay for $packageName with ${remainingTime}ms remaining")
                    showOverlayWithExpiry(context, blockInfo.appName, packageName, System.currentTimeMillis() + remainingTime)
                } else {
                    // Fallback: use package name as app name
                    val appName = packageName.split('.').lastOrNull() ?: packageName
                    android.util.Log.d("OverlayActivity", "Recreating overlay for $packageName with ${remainingTime}ms remaining (fallback)")
                    showOverlayWithExpiry(context, appName, packageName, System.currentTimeMillis() + remainingTime)
                }
            } else {
                android.util.Log.d("OverlayActivity", "No remaining time found for $packageName, not recreating overlay")
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Register dismiss receiver
        registerReceiver(dismissReceiver, IntentFilter("com.example.nterrupt.DISMISS_OVERLAY"))
        
        // Setup full screen overlay BEFORE setting content
        setupFullScreenMode()
        setupWindowFlags()
        
        // Create UI
        createBlockingUI()
        
        // Get intent data
        val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "App"
        packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
        
        // Register broadcast receivers for both persistent and legacy services
        val countdownFilter = IntentFilter().apply {
            addAction(PersistentCountdownService.BROADCAST_COUNTDOWN_UPDATE)
            addAction(PersistentCountdownService.BROADCAST_COUNTDOWN_EXPIRED)
            addAction(NterruptForegroundService.BROADCAST_COUNTDOWN_UPDATE)
            addAction(NterruptForegroundService.BROADCAST_BLOCK_EXPIRED)
        }
        registerReceiver(countdownReceiver, countdownFilter)
        
        // Setup content with loading state initially
        setupContent(appName, packageName, 0)
        
        // Subscribe to countdown updates from service (this will trigger immediate update)
        NterruptForegroundService.subscribeToCountdown(this, packageName)
        
        android.util.Log.d("OverlayActivity", "Overlay created for package: $packageName")
        
        // Get initial countdown time from SharedPreferences
        val initialRemainingTime = NterruptForegroundService.getRemainingTimeFromPrefs(this, packageName)
        if (initialRemainingTime > 0) {
            android.util.Log.d("OverlayActivity", "Initial remaining time from SharedPreferences: ${initialRemainingTime}ms")
            updateCountdownDisplay(initialRemainingTime)
        } else {
            android.util.Log.d("OverlayActivity", "No remaining time in SharedPreferences, checking persistent service")
            // Fallback to persistent service
            val persistentRemainingTime = PersistentCountdownService.getRemainingTime(packageName)
            if (persistentRemainingTime > 0) {
                android.util.Log.d("OverlayActivity", "Found remaining time from persistent service: ${persistentRemainingTime}ms")
                updateCountdownDisplay(persistentRemainingTime)
            } else {
                android.util.Log.d("OverlayActivity", "No remaining time found, finishing activity")
                finish()
                return
            }
        }
        
        // Initial check - service will send updates via broadcast
        
        // Ensure we stay on top
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        } catch (e: Exception) {
            // Ignore if we can't move to front
        }
    }
    
    private fun setupFullScreenMode() {
        // Hide navigation and status bars completely
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ approach
            WindowCompat.setDecorFitsSystemWindows(window, false)
            val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
            windowInsetsController?.let { controller ->
                controller.hide(WindowInsetsCompat.Type.systemBars())
                controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            // Pre-Android 11 approach
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
    }

    private fun setupWindowFlags() {
        // Critical flags for overlay behavior
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv() or // Allow focus to capture input
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv(), // Allow touch to prevent passthrough
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        // Handle display cutout for modern devices
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        
        // Set window type for overlay (don't set TYPE_APPLICATION_OVERLAY as it's for system overlays)
        // Use regular activity but with overlay-like flags
    }

    private fun createBlockingUI() {
        // Main container with exact center gravity
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(ContextCompat.getColor(this@FullScreenOverlayActivity, android.R.color.black))
            setPadding(80, 120, 80, 120)
            gravity = android.view.Gravity.CENTER
        }
        
        // App icon
        appIconView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(240, 240).apply {
                gravity = android.view.Gravity.CENTER_HORIZONTAL
                bottomMargin = 60
            }
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        
        // App blocked title
        appNameText = TextView(this).apply {
            textSize = 32f
            setTextColor(ContextCompat.getColor(this@FullScreenOverlayActivity, android.R.color.white))
            gravity = android.view.Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 30
            }
        }
        
        // Message text
        messageText = TextView(this).apply {
            textSize = 20f
            setTextColor(ContextCompat.getColor(this@FullScreenOverlayActivity, android.R.color.white))
            gravity = android.view.Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 50
            }
        }
        
        // Countdown display
        countdownText = TextView(this).apply {
            textSize = 64f
            setTextColor(ContextCompat.getColor(this@FullScreenOverlayActivity, android.R.color.holo_red_light))
            gravity = android.view.Gravity.CENTER
            typeface = android.graphics.Typeface.MONOSPACE
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 40
            }
        }
        
        // Additional message
        val additionalMessage = TextView(this).apply {
            text = "Take a break and come back later!"
            textSize = 18f
            setTextColor(ContextCompat.getColor(this@FullScreenOverlayActivity, android.R.color.darker_gray))
            gravity = android.view.Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = 60
            }
        }
        
        // Add all views
        mainLayout.addView(appIconView)
        mainLayout.addView(appNameText)
        mainLayout.addView(messageText)
        mainLayout.addView(countdownText)
        mainLayout.addView(additionalMessage)
        
        setContentView(mainLayout)
    }
    
    private fun setupContent(appName: String, packageName: String, remainingMs: Long) {
        // Set app name
        appNameText.text = "$appName is Blocked"
        
        // Set initial message
        messageText.text = "This app will be available again in:"
        
        // Load app icon
        loadAppIcon(packageName)
        
        // Format initial countdown based on remaining time
        val minutes = (remainingMs / 1000) / 60
        val seconds = (remainingMs / 1000) % 60
        countdownText.text = String.format("%02d:%02d", minutes, seconds)
    }
    
    private fun loadAppIcon(packageName: String) {
        try {
            val packageManager = this.packageManager
            val appIcon: Drawable = packageManager.getApplicationIcon(packageName)
            appIconView.setImageDrawable(appIcon)
        } catch (e: PackageManager.NameNotFoundException) {
            // Fallback to default icon
            appIconView.setImageResource(R.drawable.ic_notification)
        }
    }
    
    private fun updateCountdownDisplay(remainingTimeMs: Long) {
        val minutes = (remainingTimeMs / 1000) / 60
        val seconds = (remainingTimeMs / 1000) % 60
        val formattedTime = String.format("%02d:%02d", minutes, seconds)
        
        android.util.Log.d("OverlayActivity", "Updating countdown display: $formattedTime (${remainingTimeMs}ms)")
        
        if (remainingTimeMs <= 0) {
            android.util.Log.d("OverlayActivity", "Time expired, closing overlay")
            onBlockExpired()
            return
        }
        
        countdownText.text = formattedTime
        
        // Update message based on time remaining
        when {
            remainingTimeMs > 300000 -> { // > 5 minutes
                messageText.text = "This app will be available again in:"
            }
            remainingTimeMs > 60000 -> { // > 1 minute
                messageText.text = "Almost there! Just a little longer..."
            }
            remainingTimeMs > 10000 -> { // > 10 seconds
                messageText.text = "Getting ready to unlock..."
            }
            else -> {
                messageText.text = "Unlocking now..."
            }
        }
    }
    
    private fun onBlockExpired() {
        // Block has expired, clean up and close
        if (packageName.isNotEmpty()) {
            clearOverlayStateForPackage(packageName)
        }
        finish()
    }
    
    // No longer needed - service manages countdown independently
    
    // Prevent all bypass methods
    override fun onBackPressed() {
        // Completely prevent back button from closing overlay
        // Do nothing - user must wait for countdown to finish
    }
    
    override fun onUserLeaveHint() {
        // Prevent minimizing with home button by bringing back to front
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        } catch (e: Exception) {
            // Ignore if we can't move to front
        }
    }
    
    override fun onPause() {
        super.onPause()
        // If user tries to switch away, immediately bring overlay back to front
        if (!isFinishing) {
            try {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
                android.util.Log.d("OverlayActivity", "Brought overlay back to front on pause")
            } catch (e: Exception) {
                android.util.Log.e("OverlayActivity", "Error bringing overlay to front on pause", e)
            }
        }
    }
    
    override fun onStop() {
        super.onStop()
        // Even if stopped, bring back to front
        if (!isFinishing) {
            try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        } catch (e: Exception) {
            // Ignore if we can't move to front
        }
        }
    }
    
    override fun onRestart() {
        super.onRestart()
        // Ensure we're still on top when restarted
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        } catch (e: Exception) {
            // Ignore if we can't move to front
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Reapply fullscreen mode in case it was lost
        setupFullScreenMode()
        
        // Check if countdown is still active and update display
        if (packageName.isNotEmpty()) {
            // First check SharedPreferences
            val prefsRemainingTime = NterruptForegroundService.getRemainingTimeFromPrefs(this, packageName)
            if (prefsRemainingTime > 0) {
                updateCountdownDisplay(prefsRemainingTime)
                android.util.Log.d("OverlayActivity", "Resumed with remaining time from SharedPreferences: ${prefsRemainingTime}ms")
            } else {
                // Fallback to persistent service
                val persistentRemainingTime = PersistentCountdownService.getRemainingTime(packageName)
                if (persistentRemainingTime > 0) {
                    android.util.Log.d("OverlayActivity", "Found remaining time from persistent service: ${persistentRemainingTime}ms")
                    updateCountdownDisplay(persistentRemainingTime)
                } else {
                    // Final fallback to service
                    val serviceRemainingTime = NterruptForegroundService.getRemainingBlockTime(packageName)
                    if (serviceRemainingTime > 0) {
                        android.util.Log.d("OverlayActivity", "Service has remaining time: ${serviceRemainingTime}ms, updating display")
                        updateCountdownDisplay(serviceRemainingTime)
                    } else {
                        android.util.Log.d("OverlayActivity", "No remaining time found anywhere, finishing activity")
                        finish()
                        return
                    }
                }
            }
        }
        
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        } catch (e: Exception) {
            android.util.Log.e("OverlayActivity", "Error bringing overlay to front on resume", e)
        }
    }
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus && !isFinishing) {
            // If we lose focus, bring back to front
            try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        } catch (e: Exception) {
            // Ignore if we can't move to front
        }
        }
        // Reapply immersive mode
        setupFullScreenMode()
    }
    
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Block all key events including home, recent apps, etc.
        return when (keyCode) {
            KeyEvent.KEYCODE_HOME,
            KeyEvent.KEYCODE_BACK,
            KeyEvent.KEYCODE_MENU,
            KeyEvent.KEYCODE_APP_SWITCH -> true // Block these keys
            else -> super.onKeyDown(keyCode, event)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Only unsubscribe if the countdown has actually expired
        if (packageName.isNotEmpty()) {
            // Check SharedPreferences first
            val prefsRemainingTime = NterruptForegroundService.getRemainingTimeFromPrefs(this, packageName)
            val persistentRemainingTime = PersistentCountdownService.getRemainingTime(packageName)
            val remainingTime = maxOf(prefsRemainingTime, persistentRemainingTime)
            
            if (remainingTime <= 0) {
                NterruptForegroundService.unsubscribeFromCountdown(this, packageName)
                android.util.Log.d("OverlayActivity", "Countdown expired, unsubscribing from updates")
            } else {
                android.util.Log.d("OverlayActivity", "Countdown still active ($remainingTime ms), keeping subscription")
            }
        }
        
        // Unregister receivers
        try {
            unregisterReceiver(dismissReceiver)
            unregisterReceiver(countdownReceiver)
        } catch (e: Exception) {
            // Receivers might not be registered
        }
    }
}