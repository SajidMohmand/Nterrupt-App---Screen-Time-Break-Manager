import 'dart:async';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter/services.dart';
import '../models/app_info.dart';
import 'preferences_service.dart';
import 'overlay_service.dart';

/// Service for tracking app usage and enforcing limits
class UsageTrackerService {
  static const MethodChannel _channel = MethodChannel('nterrupt/usage_tracker');
  static Timer? _trackingTimer;
  static bool _isTracking = false;
  
  // Track usage times for each app
  static final Map<String, int> _dailyUsageTimes = {};
  static final Map<String, DateTime> _lastResetTime = {};
  
  // Track apps that are currently in cooldown
  static final Map<String, DateTime> _cooldownEndTimes = {};
  
  static const int _trackingIntervalSeconds = 10; // Check every 10 seconds
  static const int _breakDurationMinutes = 10; // 10-minute break
  
  /// Starts the usage tracking service
  static Future<void> startTracking() async {
    if (_isTracking) {
      print('Usage tracking already running');
      return;
    }
    
    try {
      _isTracking = true;
      print('Starting usage tracking service...');
      
      // Initialize tracking timer with longer interval to avoid crashes
      _trackingTimer = Timer.periodic(
        const Duration(seconds: 30), // Check every 30 seconds
        (_) {
          try {
            checkUsageAndEnforceLimits();
          } catch (e) {
            print('Error in tracking timer: $e');
          }
        },
      );
      
      // Initial check
      await checkUsageAndEnforceLimits();
      
    } catch (e) {
      print('Error starting usage tracking: $e');
      _isTracking = false;
    }
  }
  
  /// Stops the usage tracking service
  static Future<void> stopTracking() async {
    if (!_isTracking) {
      print('Usage tracking not running');
      return;
    }
    
    try {
      _isTracking = false;
      _trackingTimer?.cancel();
      _trackingTimer = null;
      print('Usage tracking stopped');
    } catch (e) {
      print('Error stopping usage tracking: $e');
    }
  }
  
  /// Main method to check usage and enforce limits
  static Future<void> checkUsageAndEnforceLimits() async {
    try {
      // Get current foreground app
      final currentApp = await _getCurrentForegroundApp();
      if (currentApp == null) {
        print('No current foreground app detected');
        return;
      }
      
      print('Current foreground app: $currentApp');
      
      // Check if app is in cooldown
      if (_isAppInCooldown(currentApp)) {
        print('App $currentApp is in cooldown period');
        await _enforceCooldown(currentApp);
        return;
      }
      
      // Get app configuration
      final config = await PreferencesService.getAppConfig(currentApp);
      if (!config.isSelected) {
        print('App $currentApp is not selected for monitoring');
        return;
      }
      
      // Update usage time
      await _updateUsageTime(currentApp);
      
      // Check if limit exceeded
      final usageTime = _dailyUsageTimes[currentApp] ?? 0;
      final maxUsageSeconds = config.maxUsageMinutes * 60;
      
      print('App $currentApp usage: ${usageTime}s / ${maxUsageSeconds}s');
      
      if (usageTime >= maxUsageSeconds) {
        print('App $currentApp exceeded limit! Triggering block and cooldown.');
        await _triggerAppBlockAndCooldown(currentApp);
      }
      
    } catch (e) {
      print('Error checking usage and enforcing limits: $e');
    }
  }
  
  /// Gets the current foreground app using UsageStats
  static Future<String?> _getCurrentForegroundApp() async {
    try {
      // Use platform channel to get current app
      final currentApp = await _channel.invokeMethod('getCurrentForegroundApp');
      return currentApp as String?;
    } catch (e) {
      print('Error getting current foreground app: $e');
      return null;
    }
  }
  
  /// Updates usage time for the current app
  static Future<void> _updateUsageTime(String packageName) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Reset daily usage if it's a new day
      final lastReset = _lastResetTime[packageName];
      if (lastReset == null || lastReset.isBefore(today)) {
        _dailyUsageTimes[packageName] = 0;
        _lastResetTime[packageName] = today;
        print('Reset daily usage for $packageName');
      }
      
      // Add tracking interval to usage time
      _dailyUsageTimes[packageName] = (_dailyUsageTimes[packageName] ?? 0) + _trackingIntervalSeconds;
      
    } catch (e) {
      print('Error updating usage time: $e');
    }
  }
  
  /// Checks if an app is currently in cooldown
  static bool _isAppInCooldown(String packageName) {
    final cooldownEnd = _cooldownEndTimes[packageName];
    if (cooldownEnd == null) return false;
    
    final now = DateTime.now();
    if (now.isAfter(cooldownEnd)) {
      // Cooldown period has ended
      _cooldownEndTimes.remove(packageName);
      return false;
    }
    
    return true;
  }
  
  /// Triggers app block and starts cooldown period
  static Future<void> _triggerAppBlockAndCooldown(String packageName) async {
    try {
      print('Triggering block and cooldown for $packageName');
      
      // Get app name for display
      final apps = await _getInstalledApps();
      final app = apps.firstWhere(
        (a) => a.packageName == packageName,
        orElse: () => AppInfo(packageName: packageName, appName: packageName),
      );
      
      // Start cooldown period
      final cooldownEnd = DateTime.now().add(const Duration(minutes: _breakDurationMinutes));
      _cooldownEndTimes[packageName] = cooldownEnd;
      
      // Reset daily usage
      _dailyUsageTimes[packageName] = 0;
      _lastResetTime[packageName] = DateTime.now();
      
      // Show blocking overlay
      await OverlayService.showLockOverlay(
        appName: app.appName,
        packageName: packageName,
        breakDurationMinutes: _breakDurationMinutes,
      );
      
      print('App $packageName blocked for $_breakDurationMinutes minutes');
      
    } catch (e) {
      print('Error triggering app block and cooldown: $e');
    }
  }
  
  /// Enforces cooldown by showing overlay if app is accessed during cooldown
  static Future<void> _enforceCooldown(String packageName) async {
    try {
      // Check if overlay is already showing for this app
      if (OverlayService.isOverlayActive) {
        return;
      }
      
      // Get remaining cooldown time
      final cooldownEnd = _cooldownEndTimes[packageName]!;
      final now = DateTime.now();
      final remainingMinutes = cooldownEnd.difference(now).inMinutes;
      
      if (remainingMinutes > 0) {
        // Show overlay with remaining time
        final apps = await _getInstalledApps();
        final app = apps.firstWhere(
          (a) => a.packageName == packageName,
          orElse: () => AppInfo(packageName: packageName, appName: packageName),
        );
        
        await OverlayService.showLockOverlay(
          appName: app.appName,
          packageName: packageName,
          breakDurationMinutes: remainingMinutes,
        );
        
        print('Enforcing cooldown for $packageName: $remainingMinutes minutes remaining');
      }
      
    } catch (e) {
      print('Error enforcing cooldown: $e');
    }
  }
  
  /// Gets installed apps (simplified version)
  static Future<List<AppInfo>> _getInstalledApps() async {
    try {
      final apps = await _channel.invokeMethod('getInstalledApps');
      return (apps as List).map((app) => AppInfo(
        packageName: app['packageName'],
        appName: app['appName'],
        isSystemApp: app['isSystemApp'] ?? false,
      )).toList();
    } catch (e) {
      print('Error getting installed apps: $e');
      return [];
    }
  }
  
  /// Gets current usage time for an app
  static int getUsageTime(String packageName) {
    return _dailyUsageTimes[packageName] ?? 0;
  }
  
  /// Gets remaining cooldown time for an app (in minutes)
  static int getRemainingCooldown(String packageName) {
    final cooldownEnd = _cooldownEndTimes[packageName];
    if (cooldownEnd == null) return 0;
    
    final now = DateTime.now();
    if (now.isAfter(cooldownEnd)) return 0;
    
    return cooldownEnd.difference(now).inMinutes;
  }
  
  /// Checks if tracking is active
  static bool get isTracking => _isTracking;
  
  /// Gets all usage times
  static Map<String, int> getAllUsageTimes() {
    return Map.from(_dailyUsageTimes);
  }
  
  /// Gets all cooldown times
  static Map<String, DateTime> getAllCooldownTimes() {
    return Map.from(_cooldownEndTimes);
  }
  
  /// Resets usage for a specific app
  static void resetUsage(String packageName) {
    _dailyUsageTimes[packageName] = 0;
    _lastResetTime[packageName] = DateTime.now();
    _cooldownEndTimes.remove(packageName);
  }
  
  /// Resets all usage data
  static void resetAllUsage() {
    _dailyUsageTimes.clear();
    _lastResetTime.clear();
    _cooldownEndTimes.clear();
  }
}
