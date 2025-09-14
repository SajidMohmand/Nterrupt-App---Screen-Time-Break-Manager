import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';
import '../screens/lock_overlay_screen.dart';

/// Service for managing overlay windows
class OverlayService {
  static bool _isOverlayActive = false;
  
  /// Shows the lock overlay for a blocked app
  static Future<void> showLockOverlay({
    required String appName,
    required String packageName,
    int breakDurationMinutes = 10,
  }) async {
    try {
      if (_isOverlayActive) {
        print('Overlay already active for $appName');
        return;
      }
      
      // Check overlay permission before proceeding
      bool hasPermission = false;
      try {
        hasPermission = await SystemAlertWindow.checkPermissions() ?? false;
      } catch (e) {
        print('Error checking overlay permission: $e');
        return;
      }
      
      if (!hasPermission) {
        print('Overlay permission not granted for $appName');
        // Try to request permission but don't block if it fails
        try {
          await SystemAlertWindow.requestPermissions();
          hasPermission = await SystemAlertWindow.checkPermissions() ?? false;
        } catch (e) {
          print('Error requesting overlay permission: $e');
        }
        
        if (!hasPermission) {
          print('Still no overlay permission, skipping overlay for $appName');
          return;
        }
      }

      // Show overlay with additional error handling
      try {
        await SystemAlertWindow.showSystemWindow(
          height: 600,
          width: 400,
          gravity: SystemWindowGravity.CENTER,
          notificationTitle: "App Blocked",
          notificationBody: "$appName is blocked for $breakDurationMinutes minutes",
        );
        
        _isOverlayActive = true;
        print('Lock overlay shown for $appName');
        
        // Auto-hide overlay after break duration
        Future.delayed(Duration(minutes: breakDurationMinutes), () {
          hideLockOverlay();
        });
        
      } catch (overlayError) {
        print('Error showing system window: $overlayError');
        _isOverlayActive = false;
        throw overlayError; // Re-throw to let caller handle
      }
      
    } catch (e) {
      print('Error showing lock overlay: $e');
      _isOverlayActive = false;
    }
  }
  
  /// Hides the lock overlay
  static Future<void> hideLockOverlay() async {
    try {
      if (!_isOverlayActive) {
        print('No overlay to hide');
        return;
      }
      
      await SystemAlertWindow.closeSystemWindow();
      _isOverlayActive = false;
      
      print('Lock overlay hidden');
      
    } catch (e) {
      print('Error hiding lock overlay: $e');
    }
  }
  
  /// Checks if overlay is currently active
  static bool get isOverlayActive => _isOverlayActive;
  
  /// Checks if overlay permission is granted
  /// Checks if overlay permission is granted
  static Future<bool> hasPermission() async {
    try {
      return await SystemAlertWindow.checkPermissions() ?? false;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }


  /// Requests overlay permission
  /// Requests overlay permission
  static Future<bool> requestPermission() async {
    try {
      await SystemAlertWindow.requestPermissions();
      return await SystemAlertWindow.checkPermissions() ?? false;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

}
