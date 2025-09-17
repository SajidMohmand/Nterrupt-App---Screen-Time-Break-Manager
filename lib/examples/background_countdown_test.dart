import 'dart:async';
import 'package:flutter/material.dart';
import '../services/overlay_blocking_service.dart';
import '../services/background_countdown_service.dart';

/// Test widget for verifying background countdown functionality
class BackgroundCountdownTest extends StatefulWidget {
  const BackgroundCountdownTest({Key? key}) : super(key: key);

  @override
  State<BackgroundCountdownTest> createState() => _BackgroundCountdownTestState();
}

class _BackgroundCountdownTestState extends State<BackgroundCountdownTest> {
  Timer? _monitoringTimer;
  List<BlockedAppInfo> _blockedApps = [];
  bool _isMonitoring = false;
  String _testStatus = "Ready to test";

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }

  void _startMonitoring() {
    if (_isMonitoring) return;
    
    setState(() {
      _isMonitoring = true;
      _testStatus = "Monitoring background countdown...";
    });

    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final blockedApps = await BackgroundCountdownService.getAllBlockedApps();
        if (mounted) {
          setState(() {
            _blockedApps = blockedApps;
          });
        }
      } catch (e) {
        print('Error monitoring: $e');
      }
    });
  }

  void _stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    setState(() {
      _isMonitoring = false;
      _testStatus = "Monitoring stopped";
    });
  }

  Future<void> _testSelfBlock() async {
    try {
      setState(() {
        _testStatus = "Starting self-block test...";
      });

      // Check overlay permission
      final hasPermission = await OverlayBlockingService.hasOverlayPermission();
      if (!hasPermission) {
        await OverlayBlockingService.requestOverlayPermission();
      }

      // Block current app for 3 minutes
      await OverlayBlockingService.showOverlay(
        appName: 'Nterrupt (Background Test)',
        packageName: 'com.example.nterrupt',
        duration: const Duration(minutes: 3),
      );

      setState(() {
        _testStatus = "Self-block started for 3 minutes. Test closing and reopening the app!";
      });

    } catch (e) {
      setState(() {
        _testStatus = "Error: $e";
      });
    }
  }

  Future<void> _testQuickBlock() async {
    try {
      setState(() {
        _testStatus = "Starting quick test...";
      });

      // Block for 30 seconds for quick testing
      await OverlayBlockingService.showOverlay(
        appName: 'Nterrupt (Quick Test)',
        packageName: 'com.example.nterrupt',
        duration: const Duration(seconds: 30),
      );

      setState(() {
        _testStatus = "Quick block started for 30 seconds";
      });

    } catch (e) {
      setState(() {
        _testStatus = "Error: $e";
      });
    }
  }

  Future<void> _clearAllBlocks() async {
    try {
      await OverlayBlockingService.dismissOverlay();
      setState(() {
        _testStatus = "Attempted to clear all blocks";
        _blockedApps.clear();
      });
    } catch (e) {
      setState(() {
        _testStatus = "Error clearing blocks: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Countdown Test'),
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isMonitoring ? Colors.green[50] : Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isMonitoring ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _isMonitoring ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Background Monitoring',
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
                      _testStatus,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            ElevatedButton(
              onPressed: _testSelfBlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test Background Countdown (3 min)\nBlocks this app - test closing/reopening',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _testQuickBlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Quick Test (30 sec)\nFor rapid testing',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _clearAllBlocks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Clear All Blocks'),
            ),

            const SizedBox(height: 24),

            // Currently Blocked Apps
            Text(
              'Currently Blocked Apps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _blockedApps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No apps currently blocked',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _blockedApps.length,
                      itemBuilder: (context, index) {
                        final app = _blockedApps[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.block,
                              color: app.isExpired ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              app.appName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(app.packageName),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  app.formattedRemainingTime,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: app.isExpired ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  app.isExpired ? 'Unblocked' : 'Blocked',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: app.isExpired ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Instructions
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Tap "Test Background Countdown" to block this app\n'
                      '2. Wait for overlay to appear\n'
                      '3. Close app completely (Home → Recent Apps → Swipe away)\n'
                      '4. Wait 10-20 seconds\n'
                      '5. Reopen app from launcher\n'
                      '6. Overlay should appear immediately with CORRECT remaining time\n'
                      '7. Repeat steps 3-6 multiple times to verify persistence',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
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

/// Helper function to show the test screen
void showBackgroundCountdownTest(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const BackgroundCountdownTest(),
    ),
  );
}

