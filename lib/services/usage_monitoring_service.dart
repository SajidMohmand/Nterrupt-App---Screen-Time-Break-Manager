import 'dart:async';
import 'dart:io';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/services.dart';
import '../models/app_info.dart';
import 'preferences_service.dart';
import 'app_discovery_service.dart';

/// Service for monitoring app usage and triggering blocks
class UsageMonitoringService {
  static const MethodChannel _channel = MethodChannel('nterrupt/monitoring');
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;
  static final Map<String, int> _appUsageTimes = {};
  static final Map<String, DateTime> _appStartTimes = {};
  
  /// Starts the usage monitoring service
  static Future<void> startMonitoring() async {
    if (_isMonitoring) {
      print('Monitoring already running');
      return;
    }
    
    try {
      // Check if monitoring is enabled in preferences
      final isEnabled = await PreferencesService.isMonitoringEnabled();
      if (!isEnabled) {
        print('Monitoring is disabled in preferences');
        return;
      }
      
      _isMonitoring = true;
      print('Starting usage monitoring...');
      
      // Initialize background service
      await _initializeBackgroundService();
      
      // Start monitoring timer (check every 30 seconds)
      _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _checkAppUsage();
      });
      
      // Initial check
      _checkAppUsage();
      
    } catch (e) {
      print('Error starting monitoring: $e');
      _isMonitoring = false;
    }
  }
  
  /// Stops the usage monitoring service
  static Future<void> stopMonitoring() async {
    if (!_isMonitoring) {
      print('Monitoring not running');
      return;
    }
    
    try {
      _isMonitoring = false;
      _monitoringTimer?.cancel();
      _monitoringTimer = null;
      
      // Stop background service
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      
      print('Usage monitoring stopped');
    } catch (e) {
      print('Error stopping monitoring: $e');
    }
  }
  
  /// Initializes the background service
  static Future<void> _initializeBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'nterrupt_monitoring',
          initialNotificationTitle: 'Nterrupt Monitoring',
          initialNotificationContent: 'Monitoring app usage',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
      
      await service.startService();
    } catch (e) {
      print('Error initializing background service: $e');
    }
  }
  
  /// Checks current app usage and triggers blocks if needed
  static Future<void> _checkAppUsage() async {
    try {
      // Get current foreground app
      final currentApp = await AppDiscoveryService.getCurrentForegroundApp();
      if (currentApp == null) return;
      
      // Get app configurations
      final configsMap = await PreferencesService.getAppConfigsMap();
      final config = configsMap[currentApp];
      
      // Skip if app is not selected for monitoring
      if (config == null || !config.isSelected) {
        return;
      }
      
      // Update usage time
      await _updateAppUsageTime(currentApp);
      
      // Check if limit is exceeded
      final usageTime = _appUsageTimes[currentApp] ?? 0;
      final maxUsageMinutes = config.maxUsageMinutes;
      final maxUsageSeconds = maxUsageMinutes * 60;
      
      if (usageTime >= maxUsageSeconds) {
        print('App $currentApp exceeded limit: $usageTime seconds / $maxUsageSeconds seconds');
        await _triggerAppBlock(currentApp);
      }
      
    } catch (e) {
      print('Error checking app usage: $e');
    }
  }
  
  /// Updates usage time for an app
  static Future<void> _updateAppUsageTime(String packageName) async {
    try {
      final now = DateTime.now();
      
      // If this is the first time we see this app, record start time
      if (!_appStartTimes.containsKey(packageName)) {
        _appStartTimes[packageName] = now;
        return;
      }
      
      // Calculate elapsed time since last check
      final startTime = _appStartTimes[packageName]!;
      final elapsedSeconds = now.difference(startTime).inSeconds;
      
      // Add to total usage time
      _appUsageTimes[packageName] = (_appUsageTimes[packageName] ?? 0) + elapsedSeconds;
      
      // Update start time for next calculation
      _appStartTimes[packageName] = now;
      
      print('Updated usage for $packageName: ${_appUsageTimes[packageName]} seconds');
      
    } catch (e) {
      print('Error updating app usage time: $e');
    }
  }
  
  /// Triggers app block by showing overlay
  static Future<void> _triggerAppBlock(String packageName) async {
    try {
      print('Triggering block for app: $packageName');
      
      // Get app name for display
      final apps = await AppDiscoveryService.getInstalledApps();
      final app = apps.firstWhere(
        (a) => a.packageName == packageName,
        orElse: () => AppInfo(packageName: packageName, appName: packageName),
      );
      
      // Show overlay with countdown
      await _showBlockOverlay(app.appName, packageName);
      
      // Reset usage time for this app
      _appUsageTimes[packageName] = 0;
      _appStartTimes.remove(packageName);
      
    } catch (e) {
      print('Error triggering app block: $e');
    }
  }
  
  /// Shows the block overlay
  static Future<void> _showBlockOverlay(String appName, String packageName) async {
    try {
      await _channel.invokeMethod('showBlockOverlay', {
        'appName': appName,
        'packageName': packageName,
      });
    } catch (e) {
      print('Error showing block overlay: $e');
    }
  }
  
  /// Resets usage time for a specific app
  static void resetAppUsage(String packageName) {
    _appUsageTimes[packageName] = 0;
    _appStartTimes.remove(packageName);
  }
  
  /// Gets current usage time for an app
  static int getAppUsageTime(String packageName) {
    return _appUsageTimes[packageName] ?? 0;
  }
  
  /// Gets all app usage times
  static Map<String, int> getAllAppUsageTimes() {
    return Map.from(_appUsageTimes);
  }
  
  /// Checks if monitoring is currently active
  static bool get isMonitoring => _isMonitoring;
}

/// Background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Send periodic updates
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Nterrupt Monitoring",
          content: "Monitoring app usage...",
        );
      }
    }
    
    // Check if monitoring should continue
    final isEnabled = await PreferencesService.isMonitoringEnabled();
    if (!isEnabled) {
      service.stopSelf();
      timer.cancel();
    }
  });
}

/// iOS background service entry point
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // iOS background service implementation
  return true;
}
