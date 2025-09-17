import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/flutter_overlay_service.dart';

/// Lock overlay screen that blocks app access with countdown timer
class LockOverlayScreen extends StatefulWidget {
  final String appName;
  final String packageName;
  final int breakDurationMinutes;
  
  const LockOverlayScreen({
    Key? key,
    required this.appName,
    required this.packageName,
    this.breakDurationMinutes = 10,
  }) : super(key: key);
  
  @override
  State<LockOverlayScreen> createState() => _LockOverlayScreenState();
}

class _LockOverlayScreenState extends State<LockOverlayScreen>
    with TickerProviderStateMixin {
  late Timer _countdownTimer;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  int _remainingSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCountdown();
    
    // Prevent back button and other system gestures
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  void _initializeAnimations() {
    // Pulse animation for the lock icon
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Shake animation for the screen
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  void _startCountdown() {
    // Store countdown in seconds as requested
    _remainingSeconds = widget.breakDurationMinutes * 60;

    print('Starting countdown with $_remainingSeconds seconds');

    // Use Timer.periodic that decreases every 1 second as requested
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        print('Countdown: $_remainingSeconds seconds remaining');
      } else {
        print('Countdown reached 0, ending timer');
        _endCountdown();
      }
    });
  }

  void _endCountdown() {
    _countdownTimer.cancel();
    
    // Ensure we show 00:00 before closing
    setState(() {
      _remainingSeconds = 0;
    });
    
    print('Countdown ended, showing 00:00 and closing overlay');
    
    // Close overlay and allow app access
    FlutterOverlayService.hideLockOverlay();
  }
  
  /// Convert seconds into mm:ss format as requested
  /// Examples: 600 → "10:00", 307 → "05:07", 9 → "00:09"
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  void _onScreenTap() {
    // Shake animation when user tries to interact
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }
  
  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScreenTap,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1A1A),
                      Color(0xFF000000),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lock Icon with pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 60,
                                color: Colors.red,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // App name
                      Text(
                        '${widget.appName} is Blocked',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // Break message
                      const Text(
                        'Take a break from this app',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Countdown timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Break Time Remaining',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Motivational message
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'Use this time to take a walk, stretch, or do something productive!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Bottom message
                      const Text(
                        'This screen cannot be dismissed until the break is complete',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
