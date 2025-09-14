import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/services.dart';
import 'usage_tracker_service.dart';
import 'preferences_service.dart';

/// Background service for continuous app usage monitoring
class BackgroundMonitoringService {
  static const String _channelName = 'nterrupt/background_service';
  static const MethodChannel _channel = MethodChannel(_channelName);
  
  /// Initializes and starts the background service
  static Future<void> initializeService() async {
    try {
      final service = FlutterBackgroundService();
      
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'nterrupt_monitoring',
          initialNotificationTitle: 'Nterrupt Monitoring',
          initialNotificationContent: 'Monitoring app usage and enforcing limits',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
      
      print('Background service configured');
    } catch (e) {
      print('Error configuring background service: $e');
    }
  }
  
  /// Starts the background service
  static Future<void> startService() async {
    try {
      final service = FlutterBackgroundService();
      await service.startService();
      print('Background service started');
    } catch (e) {
      print('Error starting background service: $e');
    }
  }
  
  /// Stops the background service
  static Future<void> stopService() async {
    try {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      print('Background service stopped');
    } catch (e) {
      print('Error stopping background service: $e');
    }
  }
  
  /// Checks if service is running
  static Future<bool> isServiceRunning() async {
    try {
      final service = FlutterBackgroundService();
      return await service.isRunning();
    } catch (e) {
      print('Error checking service status: $e');
      return false;
    }
  }
}

/// Background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print('Background service started');
  
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

  // Start the usage tracking in the background
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      // Update notification
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          final isMonitoring = await PreferencesService.isMonitoringEnabled();
          if (isMonitoring) {
            try {
              service.setForegroundNotificationInfo(
                title: "Nterrupt Monitoring",
                content: "Monitoring app usage and enforcing limits...",
              );
            } catch (e) {
              print('Error setting notification: $e');
            }
          }
        }
      }
      
      // Check if monitoring should continue
      final isEnabled = await PreferencesService.isMonitoringEnabled();
      if (!isEnabled) {
        print('Monitoring disabled, stopping service');
        service.stopSelf();
        timer.cancel();
        return;
      }
      
      // Run usage tracking logic
      if (UsageTrackerService.isTracking) {
        await UsageTrackerService.checkUsageAndEnforceLimits();
      }
      
    } catch (e) {
      print('Error in background service: $e');
    }
  });
}

/// iOS background service entry point
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  print('iOS background service started');
  return true;
}
