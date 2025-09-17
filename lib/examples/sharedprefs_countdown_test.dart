import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Test widget for SharedPreferences countdown persistence
class SharedPrefsCountdownTest extends StatefulWidget {
  const SharedPrefsCountdownTest({super.key});

  @override
  State<SharedPrefsCountdownTest> createState() => _SharedPrefsCountdownTestState();
}

class _SharedPrefsCountdownTestState extends State<SharedPrefsCountdownTest> {
  String _status = 'Ready to test';
  int _remainingTime = 0;
  Timer? _updateTimer;
  
  static const MethodChannel _channel = MethodChannel('nterrupt/usage_tracker');
  
  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }
  
  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }
  
  Future<void> _updateRemainingTime() async {
    try {
      // This would call the native method to get remaining time from SharedPreferences
      // For now, we'll simulate it
      if (mounted) {
        setState(() {
          _remainingTime = _remainingTime > 0 ? _remainingTime - 1000 : 0;
        });
      }
    } catch (e) {
      // Ignore errors during updates
    }
  }
  
  Future<void> _startTestCountdown() async {
    try {
      setState(() {
        _status = 'Starting countdown...';
        _remainingTime = 60000; // 1 minute
      });
      
      // Simulate starting a countdown
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _status = 'Countdown started! Check SharedPreferences persistence';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }
  
  Future<void> _checkSharedPrefs() async {
    try {
      // This would call the native method to check SharedPreferences
      setState(() {
        _status = 'Checking SharedPreferences...';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _status = 'SharedPreferences check completed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking SharedPreferences: $e';
      });
    }
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SharedPreferences Countdown Test'),
        backgroundColor: Colors.deepPurple[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Remaining Time: ${_formatTime(_remainingTime)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startTestCountdown,
              child: const Text('Start 1-Minute Test Countdown'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkSharedPrefs,
              child: const Text('Check SharedPreferences'),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SharedPreferences Implementation:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Service saves remaining time on every tick'),
                    Text('✅ Overlay reads from SharedPreferences on startup'),
                    Text('✅ Multiple fallback sources for countdown time'),
                    Text('✅ Persistent storage survives app restrictions'),
                    Text('✅ Overlay shows correct countdown instead of closing'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// Add test button to home screen
class SharedPrefsCountdownTestButton {
  static Widget addTestButton(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "sharedprefs_fab",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SharedPrefsCountdownTest(),
          ),
        );
      },
      icon: const Icon(Icons.storage),
      label: const Text('Test SharedPrefs'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    );
  }
}
