/// Model class representing an installed app
class AppInfo {
  final String packageName;
  final String appName;
  final String? iconPath;
  final bool isSystemApp;
  
  AppInfo({
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.isSystemApp = false,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;
  
  @override
  int get hashCode => packageName.hashCode;
  
  @override
  String toString() {
    return 'AppInfo{packageName: $packageName, appName: $appName, isSystemApp: $isSystemApp}';
  }
}

/// Model class for app usage configuration
class AppUsageConfig {
  final String packageName;
  final bool isSelected;
  final int maxUsageMinutes; // 5, 10, or 15 minutes
  
  AppUsageConfig({
    required this.packageName,
    this.isSelected = false,
    this.maxUsageMinutes = 10,
  });
  
  AppUsageConfig copyWith({
    bool? isSelected,
    int? maxUsageMinutes,
  }) {
    return AppUsageConfig(
      packageName: packageName,
      isSelected: isSelected ?? this.isSelected,
      maxUsageMinutes: maxUsageMinutes ?? this.maxUsageMinutes,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUsageConfig &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          isSelected == other.isSelected &&
          maxUsageMinutes == other.maxUsageMinutes;
  
  @override
  int get hashCode =>
      packageName.hashCode ^ isSelected.hashCode ^ maxUsageMinutes.hashCode;
  
  @override
  String toString() {
    return 'AppUsageConfig{packageName: $packageName, isSelected: $isSelected, maxUsageMinutes: $maxUsageMinutes}';
  }
}
