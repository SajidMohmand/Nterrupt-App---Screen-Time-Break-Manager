import 'package:flutter/services.dart';

/// Service for managing background countdown functionality
/// Communicates with Kotlin service to get real-time countdown updates
class BackgroundCountdownService {
  static const MethodChannel _channel = MethodChannel('nterrupt/background_countdown');
  
  /// Gets remaining time for a blocked app from the background service
  /// Returns the remaining time in milliseconds, or 0 if not blocked
  static Future<int> getRemainingTime(String packageName) async {
    try {
      // Request remaining time from service
      await _channel.invokeMethod('getRemainingTime', {
        'packageName': packageName,
      });
      
      // The actual result comes via broadcast in Android
      // For Flutter integration, we could implement a stream listener
      // For now, return 0 as the real value comes from service broadcasts
      return 0;
      
    } catch (e) {
      print('Error getting remaining time for $packageName: $e');
      return 0;
    }
  }
  
  /// Checks if an app is currently blocked
  static Future<bool> isAppBlocked(String packageName) async {
    try {
      final isBlocked = await _channel.invokeMethod('isAppBlocked', {
        'packageName': packageName,
      });
      return isBlocked as bool;
    } catch (e) {
      print('Error checking if $packageName is blocked: $e');
      return false;
    }
  }
  
  /// Gets all currently blocked apps with their remaining times
  static Future<List<BlockedAppInfo>> getAllBlockedApps() async {
    try {
      final result = await _channel.invokeMethod('getAllBlockedApps');
      final List<dynamic> blockedApps = result as List<dynamic>;
      
      return blockedApps.map((app) {
        final Map<String, dynamic> appMap = Map<String, dynamic>.from(app);
        return BlockedAppInfo(
          packageName: appMap['packageName'] ?? '',
          appName: appMap['appName'] ?? '',
          remainingTimeMs: appMap['remainingTimeMs'] ?? 0,
        );
      }).toList();
      
    } catch (e) {
      print('Error getting blocked apps: $e');
      return [];
    }
  }
  
  /// Formats remaining time in a human-readable format
  static String formatRemainingTime(int remainingTimeMs) {
    if (remainingTimeMs <= 0) return "Unblocked";
    
    final minutes = (remainingTimeMs / 1000 / 60).floor();
    final seconds = ((remainingTimeMs / 1000) % 60).floor();
    
    if (minutes > 60) {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return "${hours}h ${remainingMinutes}m";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }
  
  /// Creates a duration from milliseconds
  static Duration durationFromMs(int milliseconds) {
    return Duration(milliseconds: milliseconds);
  }
  
  /// Example usage for monitoring multiple apps
  static Future<void> monitorBlockedApps() async {
    try {
      final blockedApps = await getAllBlockedApps();
      
      if (blockedApps.isEmpty) {
        print('No apps currently blocked');
        return;
      }
      
      print('Currently blocked apps:');
      for (final app in blockedApps) {
        final timeRemaining = formatRemainingTime(app.remainingTimeMs);
        print('${app.appName} (${app.packageName}): $timeRemaining');
      }
      
    } catch (e) {
      print('Error monitoring blocked apps: $e');
    }
  }
}

/// Data class for blocked app information
class BlockedAppInfo {
  final String packageName;
  final String appName;
  final int remainingTimeMs;
  
  const BlockedAppInfo({
    required this.packageName,
    required this.appName,
    required this.remainingTimeMs,
  });
  
  /// Checks if this app block has expired
  bool get isExpired => remainingTimeMs <= 0;
  
  /// Gets remaining time as Duration
  Duration get remainingDuration => Duration(milliseconds: remainingTimeMs);
  
  /// Gets formatted remaining time
  String get formattedRemainingTime => BackgroundCountdownService.formatRemainingTime(remainingTimeMs);
  
  @override
  String toString() {
    return 'BlockedAppInfo{packageName: $packageName, appName: $appName, remainingTimeMs: $remainingTimeMs}';
  }
}

/// Example widget integration
/// 
/// ```dart
/// class CountdownWidget extends StatefulWidget {
///   final String packageName;
///   
///   const CountdownWidget({Key? key, required this.packageName}) : super(key: key);
///   
///   @override
///   _CountdownWidgetState createState() => _CountdownWidgetState();
/// }
/// 
/// class _CountdownWidgetState extends State<CountdownWidget> {
///   int remainingTimeMs = 0;
///   Timer? timer;
///   
///   @override
///   void initState() {
///     super.initState();
///     _startMonitoring();
///   }
///   
///   void _startMonitoring() {
///     timer = Timer.periodic(Duration(seconds: 1), (timer) async {
///       final remaining = await BackgroundCountdownService.getRemainingTime(widget.packageName);
///       if (mounted) {
///         setState(() {
///           remainingTimeMs = remaining;
///         });
///       }
///       
///       if (remaining <= 0) {
///         timer.cancel();
///       }
///     });
///   }
///   
///   @override
///   void dispose() {
///     timer?.cancel();
///     super.dispose();
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     return Text(
///       BackgroundCountdownService.formatRemainingTime(remainingTimeMs),
///       style: TextStyle(
///         fontSize: 18,
///         fontWeight: FontWeight.bold,
///         color: remainingTimeMs > 0 ? Colors.red : Colors.green,
///       ),
///     );
///   }
/// }
/// ```

