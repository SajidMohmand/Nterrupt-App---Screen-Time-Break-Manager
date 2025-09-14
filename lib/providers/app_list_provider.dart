import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/app_discovery_service.dart';
import '../services/preferences_service.dart';

/// Provider for managing app list and configurations
class AppListProvider with ChangeNotifier {
  List<AppInfo> _apps = [];
  List<AppUsageConfig> _appConfigs = [];
  bool _isLoading = false;
  
  List<AppInfo> get apps => _apps;
  List<AppUsageConfig> get appConfigs => _appConfigs;
  bool get isLoading => _isLoading;
  
  /// Loads all installed apps and their configurations
  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load installed apps
      _apps = await AppDiscoveryService.getInstalledApps();
      
      // Load saved configurations
      _appConfigs = await PreferencesService.loadSelectedApps();
      
      // Ensure all apps have configurations
      for (final app in _apps) {
        if (!_appConfigs.any((config) => config.packageName == app.packageName)) {
          _appConfigs.add(AppUsageConfig(packageName: app.packageName));
        }
      }
      
    } catch (e) {
      print('Error loading apps: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Gets configuration for a specific app
  AppUsageConfig getAppConfig(String packageName) {
    return _appConfigs.firstWhere(
      (config) => config.packageName == packageName,
      orElse: () => AppUsageConfig(packageName: packageName),
    );
  }
  
  /// Updates app configuration
  Future<void> updateAppConfig(AppUsageConfig config) async {
    try {
      // Update in memory
      final index = _appConfigs.indexWhere(
        (c) => c.packageName == config.packageName,
      );
      
      if (index != -1) {
        _appConfigs[index] = config;
      } else {
        _appConfigs.add(config);
      }
      
      // Save to preferences
      await PreferencesService.updateAppConfig(config);
      
      notifyListeners();
    } catch (e) {
      print('Error updating app config: $e');
    }
  }
  
  /// Toggles app selection
  Future<void> toggleAppSelection(String packageName) async {
    final config = getAppConfig(packageName);
    final updatedConfig = config.copyWith(isSelected: !config.isSelected);
    await updateAppConfig(updatedConfig);
  }
  
  /// Updates usage limit for an app
  Future<void> updateUsageLimit(String packageName, int minutes) async {
    final config = getAppConfig(packageName);
    final updatedConfig = config.copyWith(maxUsageMinutes: minutes);
    await updateAppConfig(updatedConfig);
  }
  
  /// Gets selected apps count
  int get selectedAppsCount {
    return _appConfigs.where((config) => config.isSelected).length;
  }
  
  /// Gets all selected apps
  List<AppUsageConfig> get selectedApps {
    return _appConfigs.where((config) => config.isSelected).toList();
  }
  
  /// Selects all apps
  Future<void> selectAllApps() async {
    for (final app in _apps) {
      final config = getAppConfig(app.packageName);
      if (!config.isSelected) {
        await updateAppConfig(config.copyWith(isSelected: true));
      }
    }
  }
  
  /// Deselects all apps
  Future<void> deselectAllApps() async {
    for (final app in _apps) {
      final config = getAppConfig(app.packageName);
      if (config.isSelected) {
        await updateAppConfig(config.copyWith(isSelected: false));
      }
    }
  }
  
  /// Filters apps by name
  List<AppInfo> filterApps(String query) {
    if (query.isEmpty) return _apps;
    
    return _apps.where((app) {
      return app.appName.toLowerCase().contains(query.toLowerCase()) ||
          app.packageName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
  
  /// Refreshes the app list
  Future<void> refresh() async {
    await loadApps();
  }
}
