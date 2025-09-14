import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter/services.dart';

/// Manages all permissions required for the Nterrupt app
class PermissionManager {
  static const MethodChannel _channel = MethodChannel('nterrupt/permissions');
  
  /// Checks if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    try {
      // Check system alert window permission
      final overlayPermission = await Permission.systemAlertWindow.isGranted;
      
      // Check usage stats permission
      final usageStatsPermission = await _checkUsageStatsPermission();
      
      return overlayPermission && usageStatsPermission;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }
  
  /// Requests all required permissions
  static Future<bool> requestAllPermissions() async {
    try {
      bool allGranted = true;
      
      // Request system alert window permission
      final overlayStatus = await Permission.systemAlertWindow.request();
      if (!overlayStatus.isGranted) {
        print('System alert window permission denied');
        allGranted = false;
      }
      
      // Request usage stats permission (this opens system settings)
      if (!await _checkUsageStatsPermission()) {
        await _requestUsageStatsPermission();
        // Note: User needs to manually enable this in settings
        allGranted = false;
      }
      
      // Request battery optimization exemption
      await _requestBatteryOptimizationExemption();
      
      return allGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }
  
  /// Checks if usage stats permission is granted
  static Future<bool> _checkUsageStatsPermission() async {
    try {
      final List<UsageInfo> usageList = await UsageStats.queryUsageStats(
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now(),
      );
      return usageList.isNotEmpty;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }
  
  /// Opens system settings for usage stats permission
  static Future<void> _requestUsageStatsPermission() async {
    try {
      // UsageStats doesn't have a direct permission request method
      // This will be handled by the platform channel
    } catch (e) {
      print('Error requesting usage stats permission: $e');
    }
  }
  
  /// Requests battery optimization exemption
  static Future<void> _requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (!status.isGranted) {
        print('Battery optimization exemption not granted');
      }
    } catch (e) {
      print('Error requesting battery optimization exemption: $e');
    }
  }
  
  /// Gets permission status details for UI display
  static Future<Map<String, bool>> getPermissionStatus() async {
    return {
      'overlay': await Permission.systemAlertWindow.isGranted,
      'usageStats': await _checkUsageStatsPermission(),
      'batteryOptimization': await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }
  
  /// Opens app settings for manual permission configuration
  static Future<void> openAppSettings() async {
    await _channel.invokeMethod('openAppSettings');
  }
  
  /// Opens usage access settings specifically
  static Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      print('Error opening usage access settings: $e');
    }
  }

}
