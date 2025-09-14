import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';

/// Service for managing local storage of app preferences
class PreferencesService {
  static const String _selectedAppsKey = 'selected_apps';
  static const String _appUsageLimitsKey = 'app_usage_limits';
  static const String _isMonitoringEnabledKey = 'is_monitoring_enabled';
  static const String _breakDurationKey = 'break_duration';
  
  /// Gets SharedPreferences instance
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();
  
  /// Saves selected apps configuration
  static Future<void> saveSelectedApps(List<AppUsageConfig> configs) async {
    try {
      final prefs = await _prefs;
      final configsJson = configs.map((config) => {
        'packageName': config.packageName,
        'isSelected': config.isSelected,
        'maxUsageMinutes': config.maxUsageMinutes,
      }).toList();
      
      await prefs.setString(_selectedAppsKey, jsonEncode(configsJson));
    } catch (e) {
      print('Error saving selected apps: $e');
    }
  }
  
  /// Loads selected apps configuration
  static Future<List<AppUsageConfig>> loadSelectedApps() async {
    try {
      final prefs = await _prefs;
      final configsJson = prefs.getString(_selectedAppsKey);
      
      if (configsJson == null) {
        return [];
      }
      
      final List<dynamic> configsList = jsonDecode(configsJson);
      return configsList.map((config) => AppUsageConfig(
        packageName: config['packageName'],
        isSelected: config['isSelected'] ?? false,
        maxUsageMinutes: config['maxUsageMinutes'] ?? 10,
      )).toList();
    } catch (e) {
      print('Error loading selected apps: $e');
      return [];
    }
  }
  
  /// Updates a specific app configuration
  static Future<void> updateAppConfig(AppUsageConfig config) async {
    try {
      final configs = await loadSelectedApps();
      final index = configs.indexWhere((c) => c.packageName == config.packageName);
      
      if (index != -1) {
        configs[index] = config;
      } else {
        configs.add(config);
      }
      
      await saveSelectedApps(configs);
    } catch (e) {
      print('Error updating app config: $e');
    }
  }
  
  /// Gets configuration for a specific app
  static Future<AppUsageConfig> getAppConfig(String packageName) async {
    try {
      final configs = await loadSelectedApps();
      final config = configs.firstWhere(
        (c) => c.packageName == packageName,
        orElse: () => AppUsageConfig(packageName: packageName),
      );
      return config;
    } catch (e) {
      print('Error getting app config: $e');
      return AppUsageConfig(packageName: packageName);
    }
  }
  
  /// Removes configuration for a specific app
  static Future<void> removeAppConfig(String packageName) async {
    try {
      final configs = await loadSelectedApps();
      configs.removeWhere((c) => c.packageName == packageName);
      await saveSelectedApps(configs);
    } catch (e) {
      print('Error removing app config: $e');
    }
  }
  
  /// Saves monitoring enabled state
  static Future<void> setMonitoringEnabled(bool enabled) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(_isMonitoringEnabledKey, enabled);
    } catch (e) {
      print('Error saving monitoring state: $e');
    }
  }
  
  /// Gets monitoring enabled state
  static Future<bool> isMonitoringEnabled() async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(_isMonitoringEnabledKey) ?? false;
    } catch (e) {
      print('Error loading monitoring state: $e');
      return false;
    }
  }
  
  /// Saves break duration (default 10 minutes)
  static Future<void> setBreakDuration(int minutes) async {
    try {
      final prefs = await _prefs;
      await prefs.setInt(_breakDurationKey, minutes);
    } catch (e) {
      print('Error saving break duration: $e');
    }
  }
  
  /// Gets break duration
  static Future<int> getBreakDuration() async {
    try {
      final prefs = await _prefs;
      return prefs.getInt(_breakDurationKey) ?? 10;
    } catch (e) {
      print('Error loading break duration: $e');
      return 10;
    }
  }
  
  /// Clears all stored preferences
  static Future<void> clearAll() async {
    try {
      final prefs = await _prefs;
      await prefs.clear();
    } catch (e) {
      print('Error clearing preferences: $e');
    }
  }
  
  /// Gets all stored app configurations as a map for easy lookup
  static Future<Map<String, AppUsageConfig>> getAppConfigsMap() async {
    try {
      final configs = await loadSelectedApps();
      final Map<String, AppUsageConfig> configsMap = {};
      
      for (final config in configs) {
        configsMap[config.packageName] = config;
      }
      
      return configsMap;
    } catch (e) {
      print('Error getting app configs map: $e');
      return {};
    }
  }
}
