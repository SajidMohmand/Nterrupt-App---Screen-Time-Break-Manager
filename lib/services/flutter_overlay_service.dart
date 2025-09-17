import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/lock_overlay_screen.dart';

/// Service for managing Flutter-based overlay windows with working countdown
class FlutterOverlayService {
  static bool _isOverlayActive = false;
  static OverlayEntry? _overlayEntry;
  static Timer? _autoHideTimer;
  
  /// Shows the Flutter lock overlay for a blocked app with working countdown
  static Future<void> showLockOverlay({
    required String appName,
    required String packageName,
    int breakDurationMinutes = 10,
  }) async {
    try {
      if (_isOverlayActive) {
        print('Flutter overlay already active for $appName');
        return;
      }
      
      // Hide any existing overlay first
      await hideLockOverlay();
      
      // Create the overlay entry
      _overlayEntry = OverlayEntry(
        builder: (context) => LockOverlayScreen(
          appName: appName,
          packageName: packageName,
          breakDurationMinutes: breakDurationMinutes,
        ),
      );
      
      // Insert the overlay
      Overlay.of(NavigationService.navigatorKey.currentContext!)?.insert(_overlayEntry!);
      
      _isOverlayActive = true;
      print('Flutter lock overlay shown for $appName for $breakDurationMinutes minutes');
      
      // Auto-hide overlay after break duration (backup timer)
      _autoHideTimer = Timer(Duration(minutes: breakDurationMinutes), () {
        hideLockOverlay();
      });
      
    } catch (e) {
      print('Error showing Flutter lock overlay: $e');
      _isOverlayActive = false;
    }
  }
  
  /// Hides the Flutter lock overlay
  static Future<void> hideLockOverlay() async {
    try {
      if (!_isOverlayActive || _overlayEntry == null) {
        print('No Flutter overlay to hide');
        return;
      }
      
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOverlayActive = false;
      
      // Cancel auto-hide timer
      _autoHideTimer?.cancel();
      _autoHideTimer = null;
      
      print('Flutter lock overlay hidden');
      
    } catch (e) {
      print('Error hiding Flutter lock overlay: $e');
    }
  }
  
  /// Checks if Flutter overlay is currently active
  static bool get isOverlayActive => _isOverlayActive;
  
  /// Shows a test overlay with countdown
  static Future<void> showTestOverlay({
    required String appName,
    required String packageName,
    int breakDurationMinutes = 1,
  }) async {
    await showLockOverlay(
      appName: appName,
      packageName: packageName,
      breakDurationMinutes: breakDurationMinutes,
    );
  }
}

/// Navigation service to get the navigator key for overlay context
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

