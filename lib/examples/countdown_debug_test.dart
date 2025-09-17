import 'package:flutter/material.dart';
import '../services/overlay_blocking_service.dart';

/// Debug test for countdown timer functionality
class CountdownDebugTest extends StatefulWidget {
  const CountdownDebugTest({Key? key}) : super(key: key);

  @override
  State<CountdownDebugTest> createState() => _CountdownDebugTestState();
}

class _CountdownDebugTestState extends State<CountdownDebugTest> {
  String _debugStatus = "Ready to test";

  Future<void> _testQuickCountdown() async {
    try {
      setState(() {
        _debugStatus = "Starting 30-second countdown test...";
      });

      // Block current app for 30 seconds
      await OverlayBlockingService.showOverlay(
        appName: 'Debug Test',
        packageName: 'com.example.nterrupt',
        duration: const Duration(seconds: 30),
      );

      setState(() {
        _debugStatus = "Overlay should now be showing with 30-second countdown.\n\nWatch the timer carefully:\n- It should start at 00:30\n- It should count down every second\n- It should NOT show 00:00";
      });

    } catch (e) {
      setState(() {
        _debugStatus = "Error: $e";
      });
    }
  }

  Future<void> _testVeryQuickCountdown() async {
    try {
      setState(() {
        _debugStatus = "Starting 10-second countdown test...";
      });

      // Block current app for 10 seconds
      await OverlayBlockingService.showOverlay(
        appName: 'Quick Debug',
        packageName: 'com.example.nterrupt',
        duration: const Duration(seconds: 10),
      );

      setState(() {
        _debugStatus = "Overlay should show 10-second countdown.\n\nExpected behavior:\n- Start at 00:10\n- Count down to 00:00\n- Auto-dismiss at 00:00";
      });

    } catch (e) {
      setState(() {
        _debugStatus = "Error: $e";
      });
    }
  }

  Future<void> _clearBlocks() async {
    try {
      await OverlayBlockingService.dismissOverlay();
      setState(() {
        _debugStatus = "Attempted to clear all blocks";
      });
    } catch (e) {
      setState(() {
        _debugStatus = "Error clearing blocks: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Countdown Debug Test'),
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐛 Debug Mode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _debugStatus,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _testQuickCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test 30-Second Countdown\nWatch timer behavior carefully',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _testVeryQuickCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test 10-Second Countdown\nQuick test for debugging',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _clearBlocks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Clear All Blocks'),
            ),

            const SizedBox(height: 32),

            const Card(
              color: Colors.red,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔍 What to Check:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Does the overlay appear immediately?\n'
                      '2. Does the countdown start with correct time?\n'
                      '3. Does the timer count down every second?\n'
                      '4. Does it auto-close when reaching 00:00?\n'
                      '5. Check Android logs for debug messages:\n'
                      '   - NterruptService broadcasts\n'
                      '   - OverlayActivity receives',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Check Android Logs:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'adb logcat | grep -E "(NterruptService|OverlayActivity)"\n\n'
                      'Look for:\n'
                      '- "Broadcasting countdown update"\n'
                      '- "Received broadcast"\n'
                      '- "Updating countdown display"',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
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

/// Helper function to show the debug test screen
void showCountdownDebugTest(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const CountdownDebugTest(),
    ),
  );
}

