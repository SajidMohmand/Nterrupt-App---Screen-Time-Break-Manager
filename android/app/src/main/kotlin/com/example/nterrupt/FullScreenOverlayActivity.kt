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
    
    private var countDownTimer: CountDownTimer? = null
    private lateinit var countdownText: TextView
    private lateinit var appNameText: TextView
    private lateinit var messageText: TextView
    private lateinit var appIconView: ImageView
    private var expiryTimestamp: Long = 0
    
    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.nterrupt.DISMISS_OVERLAY") {
                finish()
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
        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
        expiryTimestamp = intent.getLongExtra(EXTRA_EXPIRY_TIMESTAMP, System.currentTimeMillis() + 600000) // Default 10 minutes from now
        
        // Calculate remaining time based on expiry timestamp
        val currentTime = System.currentTimeMillis()
        val remainingMs = maxOf(0, expiryTimestamp - currentTime)
        
        if (remainingMs <= 0) {
            // Time already expired, close overlay
            clearOverlayStateForPackage(packageName)
            finish()
            return
        }
        
        // Setup content
        setupContent(appName, packageName, remainingMs)
        
        // Start countdown with remaining time
        startCountdown(remainingMs)
        
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
    
    private fun startCountdown(initialRemainingMs: Long) {
        countDownTimer?.cancel()
        
        // Use a repeating timer that recalculates remaining time based on expiry timestamp
        countDownTimer = object : CountDownTimer(initialRemainingMs + 1000, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                // Recalculate remaining time based on expiry timestamp (not countdown)
                val currentTime = System.currentTimeMillis()
                val actualRemainingMs = maxOf(0, expiryTimestamp - currentTime)
                
                if (actualRemainingMs <= 0) {
                    // Time has expired
                    onFinish()
                    return
                }
                
                val minutes = (actualRemainingMs / 1000) / 60
                val seconds = (actualRemainingMs / 1000) % 60
                countdownText.text = String.format("%02d:%02d", minutes, seconds)
                
                // Update message based on time remaining
                when {
                    actualRemainingMs > 300000 -> { // > 5 minutes
                        messageText.text = "This app will be available again in:"
                    }
                    actualRemainingMs > 60000 -> { // > 1 minute
                        messageText.text = "Almost there! Just a little longer..."
                    }
                    actualRemainingMs > 10000 -> { // > 10 seconds
                        messageText.text = "Getting ready to unlock..."
                    }
                    else -> {
                        messageText.text = "Unlocking now..."
                    }
                }
                
                // Notify service that we're still active
                notifyServiceCountdown(actualRemainingMs)
            }
            
            override fun onFinish() {
                // Countdown finished, clear state and close overlay
                val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
                if (packageName.isNotEmpty()) {
                    clearOverlayStateForPackage(packageName)
                }
                finish()
            }
        }
        
        countDownTimer?.start()
    }
    
    private fun notifyServiceCountdown(remainingMs: Long) {
        try {
            val intent = Intent(this, NterruptForegroundService::class.java)
            intent.action = "UPDATE_COUNTDOWN"
            intent.putExtra("remaining_ms", remainingMs)
            startService(intent)
        } catch (e: Exception) {
            // Service might not be running, ignore
        }
    }
    
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
        } catch (e: Exception) {
            // Ignore if we can't move to front
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
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            activityManager.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
        } catch (e: Exception) {
            // Ignore if we can't move to front
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
        countDownTimer?.cancel()
        try {
            unregisterReceiver(dismissReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
    }
}