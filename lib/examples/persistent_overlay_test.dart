import 'package:flutter/material.dart';
import '../services/overlay_blocking_service.dart';
import 'background_countdown_test.dart';
import 'countdown_debug_test.dart';
import 'flutter_countdown_test.dart';

/// Test helper for verifying persistent overlay functionality
class PersistentOverlayTest {
  /// Test 1: Block the current app (Nterrupt) for 2 minutes to test persistence
  static Future<void> testSelfBlock() async {
    try {
      print('Starting persistent overlay test...');

      // Check if overlay permission is granted
      final hasPermission = await OverlayBlockingService.hasOverlayPermission();
      if (!hasPermission) {
        print('Requesting overlay permission...');
        final granted = await OverlayBlockingService.requestOverlayPermission();
        if (!granted) {
          print('Overlay permission denied. Cannot test blocking.');
          return;
        }
      }

      // Block the current app for 2 minutes to test persistence
      await OverlayBlockingService.showOverlay(
        appName: 'Nterrupt (Test)',
        packageName: 'com.example.nterrupt',
        duration: const Duration(minutes: 2),
      );

      print('Overlay should now be showing. Try closing and reopening the app to test persistence.');
    } catch (e) {
      print('Error testing persistent overlay: $e');
    }
  }

  /// Test 2: Block a common app (if installed) for testing
  static Future<void> testExternalAppBlock() async {
    try {
      // Try to block Chrome browser for 1 minute
      await OverlayBlockingService.showOverlay(
        appName: 'Chrome',
        packageName: 'com.android.chrome',
        duration: const Duration(minutes: 1),
      );

      print('Chrome blocked for 1 minute. Open Chrome to see the overlay.');
    } catch (e) {
      print('Error blocking Chrome (might not be installed): $e');

      try {
        // Fallback: try blocking Settings app
        await OverlayBlockingService.showOverlay(
          appName: 'Settings',
          packageName: 'com.android.settings',
          duration: const Duration(seconds: 30),
        );

        print('Settings app blocked for 30 seconds. Open Settings to see the overlay.');
      } catch (e2) {
        print('Error blocking Settings app: $e2');
      }
    }
  }

  /// Main widget for testing persistent overlay functionality
  static Widget buildTestWidget(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persistent Overlay Test'),
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Persistent Overlay Testing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              const Text(
                'These tests verify that overlays persist across app closures:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: testSelfBlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Test Self-Block (2 min)\nThis will block Nterrupt app itself',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: testExternalAppBlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Test External App Block\nBlock Chrome/Settings for testing',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 32),

              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Tap "Test Self-Block" to block this app for 2 minutes\n'
                            '2. Wait for the overlay to appear\n'
                            '3. Close the app completely (recent apps → swipe away)\n'
                            '4. Reopen the app from launcher\n'
                            '5. The overlay should appear immediately with correct remaining time\n'
                            '6. Try this multiple times during the 2-minute window',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  try {
                    await OverlayBlockingService.dismissOverlay();
                    print('Dismissed any active overlays');
                  } catch (e) {
                    print('Error dismissing overlay: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Dismiss Active Overlay'),
              ),

              const SizedBox(height: 16),

               ElevatedButton(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => const BackgroundCountdownTest(),
                     ),
                   );
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.purple,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                 ),
                 child: const Text(
                   'Advanced Background Test\nComprehensive countdown monitoring',
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 16),
                 ),
               ),
               
               const SizedBox(height: 16),
               
               ElevatedButton(
                 onPressed: () {
                   showCountdownDebugTest(context);
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.orange,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                 ),
                 child: const Text(
                   '🐛 Debug Countdown Timer\nDetailed countdown behavior testing',
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 16),
                 ),
               ),
               
               const SizedBox(height: 16),
               
               ElevatedButton(
                 onPressed: () {
                   showFlutterCountdownTest(context);
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.teal,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                 ),
                 child: const Text(
                   '🎯 Flutter Countdown Test\nWorking Flutter overlay with timer',
                   textAlign: TextAlign.center,
                   style: TextStyle(fontSize: 16),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to add test button to existing screens
  static Widget addTestButton(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "persistent_overlay_fab",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => buildTestWidget(context),
          ),
        );
      },
      backgroundColor: Colors.deepPurple[600],
      foregroundColor: Colors.white,
      label: const Text('Test Overlay'),
      icon: const Icon(Icons.science),
    );
  }
}
