import 'dart:async';
import 'package:flutter/material.dart';
import '../services/flutter_overlay_service.dart';

/// Test screen for Flutter countdown overlay functionality
class FlutterCountdownTest extends StatefulWidget {
  const FlutterCountdownTest({Key? key}) : super(key: key);

  @override
  State<FlutterCountdownTest> createState() => _FlutterCountdownTestState();
}

class _FlutterCountdownTestState extends State<FlutterCountdownTest> {
  String _testStatus = "Ready to test Flutter countdown overlay";
  bool _isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    _checkOverlayStatus();
  }

  void _checkOverlayStatus() {
    setState(() {
      _isOverlayActive = FlutterOverlayService.isOverlayActive;
    });
  }

  Future<void> _test10SecondCountdown() async {
    try {
      setState(() {
        _testStatus = "Starting 10-second countdown test...";
      });

      await FlutterOverlayService.showTestOverlay(
        appName: 'Test App',
        packageName: 'com.example.test',
        breakDurationMinutes: 0, // 0 minutes = 0 seconds, but we'll use 1 minute for testing
      );

      setState(() {
        _testStatus = "Flutter overlay should now be showing with countdown.\n\nWatch the timer:\n- Should start at 01:00\n- Should count down every second\n- Should show 00:00 when done";
        _isOverlayActive = true;
      });

    } catch (e) {
      setState(() {
        _testStatus = "Error: $e";
      });
    }
  }

  Future<void> _test30SecondCountdown() async {
    try {
      setState(() {
        _testStatus = "Starting 30-second countdown test...";
      });

      await FlutterOverlayService.showTestOverlay(
        appName: 'Test App',
        packageName: 'com.example.test',
        breakDurationMinutes: 1, // 1 minute = 60 seconds
      );

      setState(() {
        _testStatus = "Flutter overlay should now be showing with countdown.\n\nExpected behavior:\n- Start at 01:00\n- Count down: 00:59, 00:58, 00:57...\n- End at 00:00 and auto-dismiss";
        _isOverlayActive = true;
      });

    } catch (e) {
      setState(() {
        _testStatus = "Error: $e";
      });
    }
  }

  Future<void> _test2MinuteCountdown() async {
    try {
      setState(() {
        _testStatus = "Starting 2-minute countdown test...";
      });

      await FlutterOverlayService.showTestOverlay(
        appName: 'Test App',
        packageName: 'com.example.test',
        breakDurationMinutes: 2,
      );

      setState(() {
        _testStatus = "Flutter overlay should now be showing with countdown.\n\nExpected behavior:\n- Start at 02:00\n- Count down every second\n- Auto-dismiss at 00:00";
        _isOverlayActive = true;
      });

    } catch (e) {
      setState(() {
        _testStatus = "Error: $e";
      });
    }
  }

  Future<void> _hideOverlay() async {
    try {
      await FlutterOverlayService.hideLockOverlay();
      setState(() {
        _testStatus = "Overlay hidden manually";
        _isOverlayActive = false;
      });
    } catch (e) {
      setState(() {
        _testStatus = "Error hiding overlay: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Countdown Test'),
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
              color: _isOverlayActive ? Colors.red[50] : Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isOverlayActive ? Icons.block : Icons.check_circle,
                          color: _isOverlayActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isOverlayActive ? 'Overlay Active' : 'No Overlay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isOverlayActive ? Colors.red : Colors.green,
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

            const SizedBox(height: 24),

            // Test Buttons
            ElevatedButton(
              onPressed: _test10SecondCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test 1-Minute Countdown\nQuick test to verify timer works',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _test30SecondCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test 1-Minute Countdown\nStandard test duration',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _test2MinuteCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Test 2-Minute Countdown\nLonger test to verify persistence',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _hideOverlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Hide Overlay Manually'),
            ),

            const SizedBox(height: 32),

            // Instructions
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Test Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Tap any test button to show overlay\n'
                      '2. Watch the countdown timer carefully\n'
                      '3. Verify it counts down every second\n'
                      '4. Check that it starts with correct time\n'
                      '5. Verify it auto-dismisses at 00:00\n'
                      '6. Try tapping the overlay (should shake)\n'
                      '7. Test multiple durations',
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

            // Expected Behavior
            const Card(
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Expected Behavior:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Timer starts with correct time (e.g., 01:00)\n'
                      '• Updates every second (01:00 → 00:59 → 00:58...)\n'
                      '• Shows 00:00 when countdown ends\n'
                      '• Overlay auto-dismisses at 00:00\n'
                      '• Screen shakes when tapped\n'
                      '• Lock icon pulses during countdown',
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

/// Helper function to show the Flutter countdown test screen
void showFlutterCountdownTest(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FlutterCountdownTest(),
    ),
  );
}

