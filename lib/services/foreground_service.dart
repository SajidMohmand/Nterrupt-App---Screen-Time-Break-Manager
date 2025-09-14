import 'package:flutter/services.dart';

/// Service for managing the native Android foreground service
class ForegroundService {
  static const MethodChannel _channel = MethodChannel('nterrupt/foreground_service');
  
  static bool _isRunning = false;
  
  /// Starts the foreground service
  static Future<void> startService() async {
    try {
      if (_isRunning) {
        print('Foreground service already running');
        return;
      }
      
      await _channel.invokeMethod('startForegroundService');
      _isRunning = true;
      print('Foreground service started');
    } catch (e) {
      print('Error starting foreground service: $e');
      _isRunning = false;
      rethrow;
    }
  }
  
  /// Stops the foreground service
  static Future<void> stopService() async {
    try {
      if (!_isRunning) {
        print('Foreground service not running');
        return;
      }
      
      await _channel.invokeMethod('stopForegroundService');
      _isRunning = false;
      print('Foreground service stopped');
    } catch (e) {
      print('Error stopping foreground service: $e');
      rethrow;
    }
  }
  
  /// Checks if the service is currently running
  static bool get isRunning => _isRunning;
  
  /// Forces the service state to be updated (useful for app restarts)
  static void updateState(bool running) {
    _isRunning = running;
  }
}
