import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/foreground_service.dart';
import '../services/permission_manager.dart';
import '../services/app_discovery_service.dart';

class AppBlockerScreen extends StatefulWidget {
  const AppBlockerScreen({super.key});

  @override
  State<AppBlockerScreen> createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends State<AppBlockerScreen> {
  List<AppInfo> _apps = [];
  bool _isLoading = true;
  String? _selectedAppPackage;
  String? _selectedAppName;
  int _blockDurationMinutes = 10;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await AppDiscoveryService.getInstalledApps();
      // Filter out system apps for better UX
      final userApps = apps.where((app) => !app.isSystemApp).toList();
      
      setState(() {
        _apps = userApps;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading apps: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissionsAndStartService() async {
    // Check if all permissions are granted
    final hasPermissions = await PermissionManager.areAllPermissionsGranted();
    
    if (!hasPermissions) {
      _showPermissionDialog();
      return;
    }

    // Start foreground service if not running
    if (!ForegroundService.isRunning) {
      try {
        await ForegroundService.startService();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start monitoring service: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs the following permissions:\n\n'
          '• Usage Access - to monitor which apps are running\n'
          '• Display over other apps - to show blocking overlays\n'
          '• Notification access - to run in background\n\n'
          'Please grant these permissions in the settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await PermissionManager.requestAllPermissions();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockSelectedApp() async {
    if (_selectedAppPackage == null || _selectedAppName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app to block')),
      );
      return;
    }

    await _checkPermissionsAndStartService();

    try {
      await ForegroundService.blockApp(
        appName: _selectedAppName!,
        packageName: _selectedAppPackage!,
        duration: Duration(minutes: _blockDurationMinutes),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedAppName blocked for $_blockDurationMinutes minutes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unblockSelectedApp() async {
    if (_selectedAppPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app to unblock')),
      );
      return;
    }

    try {
      await ForegroundService.unblockApp(_selectedAppPackage!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedAppName unblocked'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unblock app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Blocker'),
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            ForegroundService.isRunning
                                ? Icons.check_circle
                                : Icons.error,
                            color: ForegroundService.isRunning
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ForegroundService.isRunning
                                ? 'Monitoring Service: Active'
                                : 'Monitoring Service: Inactive',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // App selection
                  const Text(
                    'Select App to Block:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAppPackage,
                        hint: const Text('Choose an app...'),
                        isExpanded: true,
                        items: _apps.map((app) {
                          return DropdownMenuItem<String>(
                            value: app.packageName,
                            child: Row(
                              children: [
                                const Icon(Icons.apps, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(app.appName)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAppPackage = value;
                            _selectedAppName = _apps
                                .firstWhere((app) => app.packageName == value)
                                .appName;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Duration selection
                  const Text(
                    'Block Duration:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _blockDurationMinutes.toDouble(),
                          min: 1,
                          max: 120,
                          divisions: 119,
                          label: '$_blockDurationMinutes minutes',
                          onChanged: (value) {
                            setState(() {
                              _blockDurationMinutes = value.round();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '$_blockDurationMinutes min',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedAppPackage != null
                              ? _blockSelectedApp
                              : null,
                          icon: const Icon(Icons.block),
                          label: const Text('Block App'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedAppPackage != null
                              ? _unblockSelectedApp
                              : null,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Unblock App'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Instructions
                  Card(
                    color: Colors.blue[50],
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How it works:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Select the app you want to block\n'
                            '2. Choose how long to block it\n'
                            '3. Tap "Block App"\n'
                            '4. If you try to open the blocked app, you\'ll see a countdown overlay\n'
                            '5. The app will be automatically unblocked when the timer ends',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
