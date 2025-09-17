import 'package:flutter/services.dart';

/// Service for managing persistent countdown timers that work even when app is restricted
class PersistentCountdownService {
  static const MethodChannel _channel = MethodChannel('nterrupt/persistent_countdown');
  
  /// Starts a persistent countdown for an app
  static Future<void> startCountdown({
    required String packageName,
    required String appName,
    required Duration duration,
  }) async {
    try {
      await _channel.invokeMethod('startCountdown', {
        'packageName': packageName,
        'appName': appName,
        'durationMs': duration.inMilliseconds,
      });
      print('Started persistent countdown for $packageName: ${duration.inMinutes} minutes');
    } catch (e) {
      print('Error starting persistent countdown: $e');
      rethrow;
    }
  }
  
  /// Stops a persistent countdown for an app
  static Future<void> stopCountdown(String packageName) async {
    try {
      await _channel.invokeMethod('stopCountdown', {
        'packageName': packageName,
      });
      print('Stopped persistent countdown for $packageName');
    } catch (e) {
      print('Error stopping persistent countdown: $e');
      rethrow;
    }
  }
  
  /// Gets remaining time for a countdown
  static Future<int> getRemainingTime(String packageName) async {
    try {
      final remainingMs = await _channel.invokeMethod('getRemainingTime', {
        'packageName': packageName,
      });
      return remainingMs as int;
    } catch (e) {
      print('Error getting remaining time: $e');
      return 0;
    }
  }
  
  /// Checks if a countdown is active
  static Future<bool> isCountdownActive(String packageName) async {
    try {
      final isActive = await _channel.invokeMethod('isCountdownActive', {
        'packageName': packageName,
      });
      return isActive as bool;
    } catch (e) {
      print('Error checking countdown status: $e');
      return false;
    }
  }
  
  /// Stops all active countdowns
  static Future<void> stopAllCountdowns() async {
    try {
      await _channel.invokeMethod('stopAllCountdowns');
      print('Stopped all persistent countdowns');
    } catch (e) {
      print('Error stopping all countdowns: $e');
      rethrow;
    }
  }
}
