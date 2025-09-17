import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'screen/home_screen.dart';
import 'providers/app_list_provider.dart';
import './services/dummy_service.dart';
import './services/flutter_overlay_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize and immediately disable background service to prevent auto-start
  try {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: dummyServiceOnStart,
        autoStart: false,
        isForegroundMode: false,
        notificationChannelId: 'disabled_service',
        initialNotificationTitle: 'Disabled',
        initialNotificationContent: 'Service disabled',
        foregroundServiceNotificationId: 999,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: dummyServiceOnStart,
        onBackground: dummyServiceOnBackground,
      ),

    );
    print('Background service configured as disabled');
  } catch (e) {
    print('Error configuring background service: $e');
  }
  
  runApp(const MyApp());
}

// Dummy service functions to prevent background service from running
@pragma('vm:entry-point')
void _dummyServiceOnStart(ServiceInstance service) {
  print('Background service disabled - stopping immediately');
  service.stopSelf();
}

@pragma('vm:entry-point')
Future<bool> _dummyServiceOnBackground(ServiceInstance service) async {
  print('Background service disabled - stopping immediately');
  service.stopSelf();
  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppListProvider()),
      ],
      child: MaterialApp(
        title: 'Nterrupt',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          primaryColor: Colors.deepPurple[600],
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.deepPurple[600],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
