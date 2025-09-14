import 'package:flutter/services.dart';

/// Service for managing full-screen blocking overlays
class OverlayBlockingService {
  static const MethodChannel _channel = MethodChannel('nterrupt/overlay_blocking');
  
  /// Shows a full-screen blocking overlay for the specified app
  static Future<void> showOverlay({
    required String appName,
    required String packageName,
    required Duration duration,
  }) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'appName': appName,
        'packageName': packageName,
        'durationMs': duration.inMilliseconds,
      });
      print('Showing blocking overlay for $appName (${duration.inMinutes} minutes)');
    } catch (e) {
      print('Error showing blocking overlay: $e');
      rethrow;
    }
  }
  
  /// Dismisses the current blocking overlay
  static Future<void> dismissOverlay() async {
    try {
      await _channel.invokeMethod('dismissOverlay');
      print('Dismissing blocking overlay');
    } catch (e) {
      print('Error dismissing overlay: $e');
      rethrow;
    }
  }
  
  /// Checks if overlay permissions are granted
  static Future<bool> hasOverlayPermission() async {
    try {
      final hasPermission = await _channel.invokeMethod('hasOverlayPermission');
      return hasPermission as bool;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }
  
  /// Requests overlay permission
  static Future<bool> requestOverlayPermission() async {
    try {
      final granted = await _channel.invokeMethod('requestOverlayPermission');
      return granted as bool;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }
  
  /// Updates the countdown time for an active overlay
  static Future<void> updateCountdown(Duration remainingTime) async {
    try {
      await _channel.invokeMethod('updateCountdown', {
        'remainingMs': remainingTime.inMilliseconds,
      });
    } catch (e) {
      print('Error updating countdown: $e');
    }
  }
}
