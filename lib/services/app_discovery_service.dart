import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart' as installed_apps;
import 'package:installed_apps/app_info.dart' as installed_apps;

import '../models/app_info.dart';

/// Service for discovering and managing installed apps
class AppDiscoveryService {
  static const MethodChannel _channel = MethodChannel('nterrupt/app_discovery');

  /// Fetches all installed apps on the device
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      // Use platform channel method to get all launchable apps
      final List<AppInfo> installedApps = await _getInstalledAppsFromPlatform();

      // Only filter out excluded apps, but keep system apps that are launchable
      List<AppInfo> appList = installedApps
          .where((app) => !_shouldExcludeApp(app.packageName))
          .toList();

      // Sort by app name for better UX
      appList.sort((a, b) => a.appName.compareTo(b.appName));

      return appList;
    } catch (e) {
      print('Error getting installed apps: $e');
      // Fallback to installed_apps package method
      return await _getAppsWithInstalledApps();
    }
  }

  /// Helper method to get apps using installed_apps package
  static Future<List<AppInfo>> _getAppsWithInstalledApps() async {
    try {
      final List<AppInfo> apps = [];

      // Get all apps (system + non-system)
      List<installed_apps.AppInfo> installed =
      await installed_apps.InstalledApps.getInstalledApps(true, true);

      // Convert package.AppInfo -> our AppInfo
      apps.addAll(installed.map((app) => AppInfo(
        packageName: app.packageName,
        appName: app.name,
        iconPath: null, // installed_apps doesn't provide icon path
        isSystemApp: false, // We'll let the platform method handle system app detection
      )));

      return apps;
    } catch (e) {
      print('Error using installed_apps package: $e');
      return [];
    }
  }

  /// Primary method using platform channel
  static Future<List<AppInfo>> _getInstalledAppsFromPlatform() async {
    try {
      final List<dynamic> apps =
      await _channel.invokeMethod('getInstalledApps');

      return apps
          .map((app) {
        return AppInfo(
          packageName: app['packageName'],
          appName: app['appName'],
          iconPath: app['iconBase64'], // Now using base64 icon data
          isSystemApp: app['isSystemApp'] ?? false,
        );
      })
          .toList(); // Don't filter here, let the main method handle filtering
    } catch (e) {
      print('Error getting apps from platform: $e');
      return [];
    }
  }

  /// Checks if an app should be excluded from monitoring
  static bool _shouldExcludeApp(String packageName) {
    const excludedApps = [
      'com.example.nterrupt', // Our own app
      'com.android.systemui',
      'com.android.providers',
      'com.android.launcher',
      'com.android.launcher3',
      'com.google.android.launcher',
      'com.samsung.android.launcher',
      'com.miui.home',
      'com.oppo.launcher',
      'com.vivo.launcher',
      'com.oneplus.launcher',
      'com.huawei.android.launcher',
      'com.android.phone',
      'com.android.incallui',
      'com.android.dialer',
    ];

    return excludedApps.any((excluded) => packageName.contains(excluded));
  }


  /// Gets app icon as bytes (for caching)
  static Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      return await _channel
          .invokeMethod('getAppIcon', {'packageName': packageName});
    } catch (e) {
      print('Error getting app icon for $packageName: $e');
      return null;
    }
  }

  /// Checks if an app is currently running
  static Future<bool> isAppRunning(String packageName) async {
    try {
      return await _channel
          .invokeMethod('isAppRunning', {'packageName': packageName});
    } catch (e) {
      print('Error checking if app is running: $e');
      return false;
    }
  }

  /// Gets the current foreground app package name
  static Future<String?> getCurrentForegroundApp() async {
    try {
      return await _channel.invokeMethod('getCurrentForegroundApp');
    } catch (e) {
      print('Error getting current foreground app: $e');
      return null;
    }
  }
}
