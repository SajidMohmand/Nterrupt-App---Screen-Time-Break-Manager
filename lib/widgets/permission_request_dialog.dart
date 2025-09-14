import 'package:flutter/material.dart';
import '../services/permission_manager.dart';

/// Dialog for requesting necessary permissions
class PermissionRequestDialog extends StatefulWidget {
  const PermissionRequestDialog({super.key});

  @override
  State<PermissionRequestDialog> createState() => _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  bool _isRequesting = false;
  Map<String, bool> _permissionStatus = {};
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    final status = await PermissionManager.getPermissionStatus();
    setState(() {
      _permissionStatus = status;
    });
  }
  
  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
    });
    
    try {
      await PermissionManager.requestAllPermissions();
      await _checkPermissions();
      
      // Check if all permissions are now granted
      final allGranted = _permissionStatus.values.every((granted) => granted);
      
      if (allGranted) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All permissions granted! You can now use Nterrupt.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Some permissions still need to be granted manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }
  
  Future<void> _openAppSettings() async {
    await PermissionManager.openAppSettings();
  }
  
  Future<void> _openUsageAccessSettings() async {
    await PermissionManager.openUsageAccessSettings();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Permissions Required',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nterrupt needs the following permissions to monitor app usage and show blocking screens:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Usage Stats Permission
            _buildPermissionItem(
              icon: Icons.analytics,
              title: 'Usage Access',
              description: 'Monitor which apps you use and for how long',
              isGranted: _permissionStatus['usageStats'] ?? false,
              onTap: _openUsageAccessSettings,
            ),
            
            const SizedBox(height: 16),
            
            // System Alert Window Permission
            _buildPermissionItem(
              icon: Icons.picture_in_picture,
              title: 'Display over other apps',
              description: 'Show blocking screens when apps exceed limits',
              isGranted: _permissionStatus['overlay'] ?? false,
              onTap: _requestPermissions,
            ),
            
            const SizedBox(height: 16),
            
            // Battery Optimization Permission
            _buildPermissionItem(
              icon: Icons.battery_charging_full,
              title: 'Battery Optimization',
              description: 'Keep monitoring active in the background',
              isGranted: _permissionStatus['batteryOptimization'] ?? false,
              onTap: _requestPermissions,
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some permissions require manual approval in system settings.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRequesting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isRequesting ? null : _openAppSettings,
          child: const Text('Open Settings'),
        ),
        ElevatedButton(
          onPressed: _isRequesting ? null : _requestPermissions,
          child: _isRequesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Grant Permissions'),
        ),
      ],
    );
  }
  
  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isGranted ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isGranted ? Colors.green[200]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isGranted ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green[600] : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isGranted ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isGranted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isGranted ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
