import 'package:flutter/material.dart';
import '../services/overlay_blocking_service.dart';

/// Example showing how to use the new full-screen blocking overlay system
class BlockingExample {
  
  /// Example 1: Block Facebook for 10 minutes
  static Future<void> blockFacebookExample() async {
    try {
      // Check if overlay permission is granted
      final hasPermission = await OverlayBlockingService.hasOverlayPermission();
      if (!hasPermission) {
        // Request overlay permission first
        final granted = await OverlayBlockingService.requestOverlayPermission();
        if (!granted) {
          print('Overlay permission denied. Cannot block apps.');
          return;
        }
      }
      
      // Block Facebook for 10 minutes
      await OverlayBlockingService.showOverlay(
        appName: 'Facebook',
        packageName: 'com.facebook.katana',
        duration: const Duration(minutes: 10),
      );
      
      print('Facebook blocked for 10 minutes');
    } catch (e) {
      print('Error blocking Facebook: $e');
    }
  }
  
  /// Example 2: Block Instagram for 30 minutes
  static Future<void> blockInstagramExample() async {
    try {
      await OverlayBlockingService.showOverlay(
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        duration: const Duration(minutes: 30),
      );
      
      print('Instagram blocked for 30 minutes');
    } catch (e) {
      print('Error blocking Instagram: $e');
    }
  }
  
  /// Example 3: Block TikTok for 1 hour
  static Future<void> blockTikTokExample() async {
    try {
      await OverlayBlockingService.showOverlay(
        appName: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        duration: const Duration(hours: 1),
      );
      
      print('TikTok blocked for 1 hour');
    } catch (e) {
      print('Error blocking TikTok: $e');
    }
  }
  
  /// Example 4: Unblock an app early
  static Future<void> unblockExample() async {
    try {
      await OverlayBlockingService.dismissOverlay();
      print('Current blocking overlay dismissed');
    } catch (e) {
      print('Error dismissing overlay: $e');
    }
  }
  
  /// Example 5: Check if overlay permission is available
  static Future<bool> checkOverlayPermissionExample() async {
    try {
      final hasPermission = await OverlayBlockingService.hasOverlayPermission();
      print('Overlay permission status: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }
  
  /// Example Widget: UI to test blocking functionality
  static Widget buildTestUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocking Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: blockFacebookExample,
              child: const Text('Block Facebook (10 min)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: blockInstagramExample,
              child: const Text('Block Instagram (30 min)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: blockTikTokExample,
              child: const Text('Block TikTok (1 hour)'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: unblockExample,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Dismiss Current Overlay'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: checkOverlayPermissionExample,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Check Overlay Permission'),
            ),
          ],
        ),
      ),
    );
  }
}

/// How to integrate with your existing usage monitoring:
/// 
/// In your SimpleUsageMonitor or wherever you detect app limit exceeded:
/// 
/// ```dart
/// if (usageTime >= maxUsageSeconds) {
///   print('App $currentApp exceeded limit! Starting full-screen block.');
///   
///   // Instead of showing a bubble overlay, show full-screen block
///   await OverlayBlockingService.showOverlay(
///     appName: appName,
///     packageName: currentApp,
///     duration: Duration(minutes: breakDurationMinutes),
///   );
/// }
/// ```
/// 
/// Benefits of this approach:
/// - True blocking: Users cannot interact with the blocked app
/// - Full-screen coverage: No way to access the app around the overlay
/// - Professional UI: Similar to Digital Wellbeing
/// - Auto-dismiss: Overlay disappears when countdown ends
/// - Permission handling: Graceful permission requests
/// - Android compatibility: Works on Android 11, 12, 13+
