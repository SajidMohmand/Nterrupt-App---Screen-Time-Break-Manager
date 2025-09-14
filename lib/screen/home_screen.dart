import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/app_info.dart';
import '../services/app_discovery_service.dart';
import '../services/preferences_service.dart';
import '../services/permission_manager.dart';
import '../services/simple_usage_monitor.dart';
import '../providers/app_list_provider.dart';
import '../widgets/app_list_item.dart';
import '../widgets/permission_request_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isMonitoring = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Disable and stop any background services completely
      try {
        final service = FlutterBackgroundService();
        // First try to stop if running
        if (await service.isRunning()) {
          service.invoke('stopService');
          print('Stopped existing background service');
        }
        
        // Configure the service to prevent auto-start
        await service.configure(
          androidConfiguration: AndroidConfiguration(
            onStart: _disabledServiceOnStart,
            autoStart: false,
            isForegroundMode: false,
            notificationChannelId: 'disabled_service',
            initialNotificationTitle: 'Disabled',
            initialNotificationContent: 'Service disabled',
            foregroundServiceNotificationId: 999,
          ),
          iosConfiguration: IosConfiguration(
            autoStart: false,
            onForeground: _disabledServiceOnStart,
            onBackground: _disabledServiceOnBackground,
          ),
        );
        print('Background service disabled');
      } catch (e) {
        print('Error disabling background service: $e');
      }
      
      // Check permissions first
      final hasPermissions = await PermissionManager.areAllPermissionsGranted();
      if (!hasPermissions) {
        if (mounted) {
          _showPermissionDialog();
        }
      }
      
      // Load app list and configurations
      await context.read<AppListProvider>().loadApps();
      
      // Check monitoring status from preferences and restore if needed
      final isEnabledInPrefs = await PreferencesService.isMonitoringEnabled();
      if (isEnabledInPrefs && !SimpleUsageMonitor.isMonitoring) {
        try {
          // Restore monitoring state only if permissions are granted
          final hasPermissions = await PermissionManager.areAllPermissionsGranted();
          if (hasPermissions) {
            await SimpleUsageMonitor.startMonitoring();
          } else {
            // Disable monitoring in preferences if permissions are not granted
            await PreferencesService.setMonitoringEnabled(false);
          }
        } catch (e) {
          print('Error restoring monitoring state: $e');
          // Disable monitoring in preferences if there's an error
          await PreferencesService.setMonitoringEnabled(false);
        }
      }
      _isMonitoring = SimpleUsageMonitor.isMonitoring;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionRequestDialog(),
    );
  }

  // Disabled service functions to prevent background service from starting
  static void _disabledServiceOnStart(ServiceInstance service) {
    print('Background service disabled - stopping immediately');
    service.stopSelf();
  }

  static Future<bool> _disabledServiceOnBackground(ServiceInstance service) async {
    print('Background service disabled - stopping immediately');
    service.stopSelf();
    return false;
  }
  
  Future<void> _toggleMonitoring() async {
    try {
      if (_isMonitoring) {
        await SimpleUsageMonitor.stopMonitoring();
        await PreferencesService.setMonitoringEnabled(false);
        setState(() {
          _isMonitoring = false;
        });
      } else {
        // Check permissions before starting
        final hasPermissions = await PermissionManager.areAllPermissionsGranted();
        if (!hasPermissions) {
          _showPermissionDialog();
          return;
        }
        
        // Start simple monitoring with error handling
        try {
          await SimpleUsageMonitor.startMonitoring();
          await PreferencesService.setMonitoringEnabled(true);
          setState(() {
            _isMonitoring = true;
          });
        } catch (e) {
          print('Error starting monitoring: $e');
          // Make sure preferences reflect the actual state
          await PreferencesService.setMonitoringEnabled(false);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to start monitoring: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      print('Error toggling monitoring: $e');
      // Update UI to reflect actual state
      setState(() {
        _isMonitoring = SimpleUsageMonitor.isMonitoring;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _refreshApps() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await context.read<AppListProvider>().loadApps();
    } catch (e) {
      print('Error refreshing apps: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Nterrupt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshApps,
          ),
          IconButton(
            icon: Icon(
              _isMonitoring ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _toggleMonitoring,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isMonitoring ? Icons.security : Icons.security_outlined,
                            color: _isMonitoring ? Colors.green : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isMonitoring ? 'Monitoring Active' : 'Monitoring Inactive',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isMonitoring ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMonitoring
                            ? 'Apps are being monitored for usage limits'
                            : 'Tap the play button to start monitoring',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // App List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Installed Apps',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Consumer<AppListProvider>(
                        builder: (context, provider, child) {
                          final selectedCount = provider.appConfigs
                              .where((config) => config.isSelected)
                              .length;
                          return Text(
                            '$selectedCount selected',
                            style: TextStyle(
                              color: Colors.deepPurple[600],
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // App List
                Expanded(
                  child: Consumer<AppListProvider>(
                    builder: (context, provider, child) {
                      if (provider.apps.isEmpty) {
                        return const Center(
                          child: Text(
                            'No apps found\nMake sure usage stats permission is granted',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.apps.length,
                        itemBuilder: (context, index) {
                          final app = provider.apps[index];
                          final config = provider.getAppConfig(app.packageName);
                          
                          return AppListItem(
                            app: app,
                            config: config,
                            onConfigChanged: (newConfig) {
                              provider.updateAppConfig(newConfig);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
