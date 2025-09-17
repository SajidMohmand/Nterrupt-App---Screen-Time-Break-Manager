import 'package:flutter/material.dart';
import '../services/flutter_overlay_service.dart';

/// Simple demo showing the working Flutter countdown timer
class SimpleCountdownDemo extends StatelessWidget {
  const SimpleCountdownDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Countdown Demo'),
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer,
              size: 80,
              color: Colors.deepPurple,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Flutter Countdown Timer Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'This demonstrates a working countdown timer\nusing StatefulWidget and Timer.periodic',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () async {
                await FlutterOverlayService.showTestOverlay(
                  appName: 'Demo App',
                  packageName: 'com.example.demo',
                  breakDurationMinutes: 1, // 1 minute = 60 seconds
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Show 1-Minute Countdown',
                style: TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () async {
                await FlutterOverlayService.showTestOverlay(
                  appName: 'Demo App',
                  packageName: 'com.example.demo',
                  breakDurationMinutes: 0, // 0 minutes = 0 seconds, but we'll use 1 minute for testing
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Show 1-Minute Countdown (Alternative)',
                style: TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✅ StatefulWidget with Timer.periodic\n'
                      '✅ Countdown stored in seconds\n'
                      '✅ Updates every 1 second with setState\n'
                      '✅ Converts seconds to mm:ss format\n'
                      '✅ Shows 00:00 when countdown ends\n'
                      '✅ Auto-dismisses when timer reaches 0',
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

/// Helper function to show the simple demo
void showSimpleCountdownDemo(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SimpleCountdownDemo(),
    ),
  );
}

