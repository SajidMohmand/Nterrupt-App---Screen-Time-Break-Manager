import 'dart:async';
import 'package:flutter/material.dart';
import '../services/persistent_countdown_service.dart';

/// Test widget for persistent countdown service
class PersistentCountdownTest extends StatefulWidget {
  const PersistentCountdownTest({super.key});

  @override
  State<PersistentCountdownTest> createState() => _PersistentCountdownTestState();
}

class _PersistentCountdownTestState extends State<PersistentCountdownTest> {
  String _status = 'Ready to test';
  int _remainingTime = 0;
  Timer? _updateTimer;
  
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
      final remaining = await PersistentCountdownService.getRemainingTime('com.example.test');
      if (mounted) {
        setState(() {
          _remainingTime = remaining;
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
      });
      
      await PersistentCountdownService.startCountdown(
        packageName: 'com.example.test',
        appName: 'Test App',
        duration: const Duration(minutes: 1), // 1 minute test
      );
      
      setState(() {
        _status = 'Countdown started!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }
  
  Future<void> _stopTestCountdown() async {
    try {
      await PersistentCountdownService.stopCountdown('com.example.test');
      setState(() {
        _status = 'Countdown stopped';
        _remainingTime = 0;
      });
    } catch (e) {
      setState(() {
        _status = 'Error stopping: $e';
      });
    }
  }
  
  Future<void> _checkStatus() async {
    try {
      final isActive = await PersistentCountdownService.isCountdownActive('com.example.test');
      setState(() {
        _status = isActive ? 'Countdown is active' : 'No active countdown';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking status: $e';
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
        title: const Text('Persistent Countdown Test'),
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
              onPressed: _stopTestCountdown,
              child: const Text('Stop Countdown'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkStatus,
              child: const Text('Check Status'),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Start a countdown'),
                    Text('2. Put the app in background or restrict it'),
                    Text('3. Check if countdown continues updating'),
                    Text('4. The countdown should work even when app is restricted'),
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
class PersistentCountdownTestButton {
  static Widget addTestButton(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "persistent_countdown_fab",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PersistentCountdownTest(),
          ),
        );
      },
      icon: const Icon(Icons.timer),
      label: const Text('Test Countdown'),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    );
  }
}
