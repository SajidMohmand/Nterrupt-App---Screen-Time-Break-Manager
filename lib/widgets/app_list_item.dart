import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/simple_usage_monitor.dart';

/// Widget for displaying individual app in the list
class AppListItem extends StatelessWidget {
  final AppInfo app;
  final AppUsageConfig config;
  final Function(AppUsageConfig) onConfigChanged;
  
  const AppListItem({
    Key? key,
    required this.app,
    required this.config,
    required this.onConfigChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAppIcon(),
        title: Text(
          app.appName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.packageName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (config.isSelected) ...[
              const SizedBox(height: 4),
              _buildUsageInfo(),
            ],
          ],
        ),
        trailing: _buildTrailingWidget(),
        onTap: () => _showUsageLimitDialog(context),
      ),
    );
  }
  
  Widget _buildAppIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: app.iconPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                app.iconPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
              ),
            )
          : _buildDefaultIcon(),
    );
  }
  
  Widget _buildDefaultIcon() {
    return Icon(
      Icons.android,
      color: Colors.grey[600],
      size: 24,
    );
  }
  
  Widget _buildUsageInfo() {
    final usageTime = SimpleUsageMonitor.getUsageTime(app.packageName);
    final cooldownTime = SimpleUsageMonitor.getRemainingCooldown(app.packageName);
    final maxUsageSeconds = config.maxUsageMinutes * 60;
    final usagePercentage = maxUsageSeconds > 0 ? (usageTime / maxUsageSeconds * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Usage progress bar
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: usagePercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  usagePercentage >= 100 ? Colors.red : Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${usageTime ~/ 60}:${(usageTime % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: usagePercentage >= 100 ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (cooldownTime > 0) ...[
          const SizedBox(height: 2),
          Text(
            'Cooldown: ${cooldownTime}m',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildTrailingWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Usage limit display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: config.isSelected 
                ? Colors.deepPurple[100] 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${config.maxUsageMinutes}m',
            style: TextStyle(
              color: config.isSelected 
                  ? Colors.deepPurple[700] 
                  : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Selection checkbox
        Checkbox(
          value: config.isSelected,
          onChanged: (value) {
            onConfigChanged(config.copyWith(isSelected: value ?? false));
          },
          activeColor: Colors.deepPurple[600],
        ),
      ],
    );
  }
  
  void _showUsageLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Usage Limit for ${app.appName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select the maximum usage duration before the app gets blocked:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _buildUsageLimitOptions(context),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUsageLimitOptions(BuildContext context) {
    const limits = [5, 10, 15];
    
    return Column(
      children: limits.map((limit) {
        final isSelected = config.maxUsageMinutes == limit;
        
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              onConfigChanged(config.copyWith(maxUsageMinutes: limit));
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple[50] : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.deepPurple[300]! : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: isSelected ? Colors.deepPurple[600] : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$limit minutes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.deepPurple[700] : Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Colors.deepPurple[600],
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
