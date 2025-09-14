import 'dart:async';
import 'package:flutter/services.dart';
import '../models/app_info.dart';
import 'preferences_service.dart';
import 'overlay_blocking_service.dart';
import 'app_discovery_service.dart';
import 'foreground_service.dart';

/// Simplified usage monitor that works without background service
class SimpleUsageMonitor {
  static const MethodChannel _channel = MethodChannel('nterrupt/usage_tracker');
  static Timer? _monitorTimer;
  static bool _isMonitoring = false;
  
  // Track usage times for each app
  static final Map<String, int> _dailyUsageTimes = {};
  static final Map<String, DateTime> _lastResetTime = {};
  
  // Track apps that are currently in cooldown
  static final Map<String, DateTime> _cooldownEndTimes = {};
  
  static const int _breakDurationMinutes = 10; // 10-minute break
  
  /// Starts monitoring
  static Future<void> startMonitoring() async {
    if (_isMonitoring) {
      print('Monitoring already running');
      return;
    }
    
    try {
      _isMonitoring = true;
      print('Starting simple usage monitoring...');
      
      // Start foreground service for better reliability
      try {
        await ForegroundService.startService();
      } catch (e) {
        print('Could not start foreground service: $e');
        // Continue without foreground service
      }
      
      // Start timer to check every 10 seconds
      _monitorTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) {
          try {
            _checkUsage();
          } catch (e) {
            print('Error in monitoring timer: $e');
          }
        },
      );
      
      // Initial check with delay to avoid immediate overlay calls
      Future.delayed(const Duration(seconds: 5), () {
        _checkUsage();
      });
      
    } catch (e) {
      print('Error starting monitoring: $e');
      _isMonitoring = false;
    }
  }
  
  /// Stops monitoring
  static Future<void> stopMonitoring() async {
    if (!_isMonitoring) {
      print('Monitoring not running');
      return;
    }
    
    try {
      _isMonitoring = false;
      _monitorTimer?.cancel();
      _monitorTimer = null;
      
      // Stop foreground service
      try {
        await ForegroundService.stopService();
      } catch (e) {
        print('Could not stop foreground service: $e');
      }
      
      print('Monitoring stopped');
    } catch (e) {
      print('Error stopping monitoring: $e');
    }
  }
  
  /// Main check method
  static Future<void> _checkUsage() async {
    try {
      // Get current foreground app
      final currentApp = await _getCurrentForegroundApp();
      if (currentApp == null) {
        return;
      }
      
      print('Monitoring app: $currentApp');
      
      // Check if app is in cooldown
      if (_isAppInCooldown(currentApp)) {
        print('App $currentApp is in cooldown');
        await _showCooldownOverlay(currentApp);
        return;
      }
      
      // Get app configuration
      final config = await PreferencesService.getAppConfig(currentApp);
      if (!config.isSelected) {
        print('App $currentApp not selected for monitoring');
        return;
      }
      
      // Update usage time (add 10 seconds for each check)
      _updateUsageTime(currentApp);
      
      // Check if limit exceeded
      final usageTime = _dailyUsageTimes[currentApp] ?? 0;
      final maxUsageSeconds = config.maxUsageMinutes * 60;
      
      print('App $currentApp usage: ${usageTime}s / ${maxUsageSeconds}s');
      
      if (usageTime >= maxUsageSeconds) {
        print('App $currentApp exceeded limit! Starting cooldown.');
        await _startCooldown(currentApp);
      }
      
    } catch (e) {
      print('Error checking usage: $e');
    }
  }
  
  /// Gets current foreground app
  static Future<String?> _getCurrentForegroundApp() async {
    try {
      final currentApp = await _channel.invokeMethod('getCurrentForegroundApp');
      return currentApp as String?;
    } catch (e) {
      print('Error getting current app: $e');
      // If we can't get foreground app, we can't monitor effectively
      // Return null to gracefully handle the error
      return null;
    }
  }
  
  /// Updates usage time for an app
  static void _updateUsageTime(String packageName) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Reset daily usage if it's a new day
    final lastReset = _lastResetTime[packageName];
    if (lastReset == null || lastReset.isBefore(today)) {
      _dailyUsageTimes[packageName] = 0;
      _lastResetTime[packageName] = today;
      print('Reset daily usage for $packageName');
    }
    
    // Add 10 seconds (check interval) to usage time
    _dailyUsageTimes[packageName] = (_dailyUsageTimes[packageName] ?? 0) + 10;
  }
  
  /// Checks if an app is in cooldown
  static bool _isAppInCooldown(String packageName) {
    final cooldownEnd = _cooldownEndTimes[packageName];
    if (cooldownEnd == null) return false;
    
    final now = DateTime.now();
    if (now.isAfter(cooldownEnd)) {
      _cooldownEndTimes.remove(packageName);
      return false;
    }
    
    return true;
  }
  
  /// Shows full-screen blocking overlay for app in cooldown
  static Future<void> _showCooldownOverlay(String packageName) async {
    try {
      // Get remaining cooldown time
      final remainingMinutes = getRemainingCooldown(packageName);
      if (remainingMinutes <= 0) {
        print('No cooldown remaining for $packageName');
        return;
      }
      
      // Get app name for display
      final apps = await AppDiscoveryService.getInstalledApps();
      final app = apps.firstWhere(
        (a) => a.packageName == packageName,
        orElse: () => AppInfo(packageName: packageName, appName: packageName),
      );
      
      // Check if overlay permission is granted
      final hasPermission = await OverlayBlockingService.hasOverlayPermission();
      if (!hasPermission) {
        print('Overlay permission not granted, requesting permission');
        await OverlayBlockingService.requestOverlayPermission();
        return;
      }
      
      // Show full-screen blocking overlay
      final remainingDuration = Duration(minutes: remainingMinutes);
      await OverlayBlockingService.showOverlay(
        appName: app.appName,
        packageName: packageName,
        duration: remainingDuration,
      );
      
      print('Showing full-screen blocking overlay for $packageName (${remainingMinutes} minutes remaining)');
      
    } catch (e) {
      print('Error showing cooldown overlay: $e');
      // Don't rethrow to prevent crashes
    }
  }

  /// Starts cooldown for an app
  static Future<void> _startCooldown(String packageName) async {
    try {
      print('Starting cooldown for $packageName');
      
      // Start cooldown period
      final cooldownEnd = DateTime.now().add(const Duration(minutes: _breakDurationMinutes));
      _cooldownEndTimes[packageName] = cooldownEnd;
      
      // Reset daily usage
      _dailyUsageTimes[packageName] = 0;
      _lastResetTime[packageName] = DateTime.now();
      
      // Get app name for display
      final apps = await AppDiscoveryService.getInstalledApps();
      final app = apps.firstWhere(
        (a) => a.packageName == packageName,
        orElse: () => AppInfo(packageName: packageName, appName: packageName),
      );
      
      // Show full-screen blocking overlay immediately
      try {
        // Check if overlay permission is granted first
        final hasPermission = await OverlayBlockingService.hasOverlayPermission();
        if (!hasPermission) {
          print('Overlay permission not granted, requesting permission');
          await OverlayBlockingService.requestOverlayPermission();
        }
        
        // Show the full-screen blocking overlay
        await OverlayBlockingService.showOverlay(
          appName: app.appName,
          packageName: packageName,
          duration: const Duration(minutes: _breakDurationMinutes),
        );
        
        print('Full-screen blocking overlay shown for $packageName');
      } catch (overlayError) {
        print('Error showing full-screen overlay for $packageName: $overlayError');
        // Continue without overlay but keep cooldown active
      }
      
      print('App $packageName blocked for $_breakDurationMinutes minutes');
      
    } catch (e) {
      print('Error starting cooldown: $e');
      // Don't rethrow to prevent crashes
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
  
  /// Checks if monitoring is active
  static bool get isMonitoring => _isMonitoring;
  
  /// Resets usage for a specific app
  static void resetUsage(String packageName) {
    _dailyUsageTimes[packageName] = 0;
    _lastResetTime[packageName] = DateTime.now();
    _cooldownEndTimes.remove(packageName);
  }
}

