package com.example.nterrupt

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat

class BlockerOverlayActivity : Activity() {
    
    private var countDownTimer: CountDownTimer? = null
    private lateinit var countdownText: TextView
    private lateinit var appNameText: TextView
    private lateinit var messageText: TextView
    private lateinit var closeButton: Button
    
    companion object {
        const val EXTRA_APP_NAME = "app_name"
        const val EXTRA_PACKAGE_NAME = "package_name" 
        const val EXTRA_REMAINING_TIME = "remaining_time"
        const val EXTRA_BLOCK_ID = "block_id"
        
        fun startBlockerOverlay(context: Context, appName: String, packageName: String, remainingTimeMs: Long, blockId: String) {
            val intent = Intent(context, BlockerOverlayActivity::class.java).apply {
                putExtra(EXTRA_APP_NAME, appName)
                putExtra(EXTRA_PACKAGE_NAME, packageName)
                putExtra(EXTRA_REMAINING_TIME, remainingTimeMs)
                putExtra(EXTRA_BLOCK_ID, blockId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                       Intent.FLAG_ACTIVITY_CLEAR_TASK or
                       Intent.FLAG_ACTIVITY_NO_HISTORY or
                       Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
            }
            context.startActivity(intent)
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make this activity full screen and on top of everything
        setupFullScreenOverlay()
        
        // Create the overlay UI
        createOverlayUI()
        
        // Get data from intent
        val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "App"
        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""
        val remainingTime = intent.getLongExtra(EXTRA_REMAINING_TIME, 0)
        val blockId = intent.getStringExtra(EXTRA_BLOCK_ID) ?: ""
        
        // Setup UI with app info
        setupUIContent(appName, packageName, remainingTime, blockId)
        
        // Start countdown
        startCountdown(remainingTime, blockId)
    }
    
    private fun setupFullScreenOverlay() {
        // Make activity fullscreen and on top
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
        
        // Set window flags for overlay behavior
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
        
        // For Android 10+ (API 29+), use different approach
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.attributes.layoutInDisplayCutoutMode = 
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }
    
    private fun createOverlayUI() {
        // Create main container
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(ContextCompat.getColor(this@BlockerOverlayActivity, android.R.color.black))
            setPadding(60, 60, 60, 60)
        }
        
        // App icon (placeholder)
        val iconView = ImageView(this).apply {
            setImageResource(R.drawable.ic_notification)
            layoutParams = LinearLayout.LayoutParams(200, 200).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = 40
            }
        }
        
        // App name text
        appNameText = TextView(this).apply {
            textSize = 28f
            setTextColor(ContextCompat.getColor(this@BlockerOverlayActivity, android.R.color.white))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 20
            }
        }
        
        // Message text
        messageText = TextView(this).apply {
            textSize = 20f
            setTextColor(ContextCompat.getColor(this@BlockerOverlayActivity, android.R.color.white))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 40
            }
        }
        
        // Countdown text
        countdownText = TextView(this).apply {
            textSize = 48f
            setTextColor(ContextCompat.getColor(this@BlockerOverlayActivity, android.R.color.holo_red_light))
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = 60
            }
        }
        
        // Close button (for testing - remove in production)
        closeButton = Button(this).apply {
            text = "I understand"
            textSize = 16f
            setBackgroundColor(ContextCompat.getColor(this@BlockerOverlayActivity, android.R.color.holo_blue_dark))
            setTextColor(ContextCompat.getColor(this@BlockerOverlayActivity, android.R.color.white))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = 40
            }
            setOnClickListener {
                // Don't actually close - this is a blocker!
                // Just show a message
                messageText.text = "Please wait for the timer to finish"
            }
        }
        
        // Add all views to main layout
        mainLayout.addView(iconView)
        mainLayout.addView(appNameText)
        mainLayout.addView(messageText)
        mainLayout.addView(countdownText)
        mainLayout.addView(closeButton)
        
        setContentView(mainLayout)
    }
    
    private fun setupUIContent(appName: String, packageName: String, remainingTime: Long, blockId: String) {
        appNameText.text = "$appName is Blocked"
        messageText.text = "Take a break! This app will be available again in:"
        
        // Format initial time
        val minutes = (remainingTime / 1000) / 60
        val seconds = (remainingTime / 1000) % 60
        countdownText.text = String.format("%02d:%02d", minutes, seconds)
    }
    
    private fun startCountdown(remainingTime: Long, blockId: String) {
        countDownTimer?.cancel()
        
        countDownTimer = object : CountDownTimer(remainingTime, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val minutes = (millisUntilFinished / 1000) / 60
                val seconds = (millisUntilFinished / 1000) % 60
                countdownText.text = String.format("%02d:%02d", minutes, seconds)
                
                // Update message based on time remaining
                when {
                    millisUntilFinished > 60000 -> {
                        messageText.text = "Take a break! This app will be available again in:"
                    }
                    millisUntilFinished > 10000 -> {
                        messageText.text = "Almost there! Just a few more seconds..."
                    }
                    else -> {
                        messageText.text = "Getting ready to unlock..."
                    }
                }
            }
            
            override fun onFinish() {
                // Notify service that block has ended
                val intent = Intent(this@BlockerOverlayActivity, NterruptForegroundService::class.java)
                intent.action = NterruptForegroundService.ACTION_BLOCK_ENDED
                intent.putExtra("block_id", blockId)
                startService(intent)
                
                // Close overlay
                finish()
            }
        }
        
        countDownTimer?.start()
    }
    
    override fun onBackPressed() {
        // Prevent back button from closing the overlay
        messageText.text = "Please wait for the timer to finish"
    }
    
    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }
}
