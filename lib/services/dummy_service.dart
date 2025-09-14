import 'package:flutter_background_service/flutter_background_service.dart';

@pragma('vm:entry-point')
void dummyServiceOnStart(ServiceInstance service) {
  print('Background service disabled - stopping immediately');
  service.stopSelf();
}

@pragma('vm:entry-point')
Future<bool> dummyServiceOnBackground(ServiceInstance service) async {
  print('Background service disabled - stopping immediately');
  service.stopSelf();
  return false;
}
