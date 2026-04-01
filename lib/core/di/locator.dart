// lib/core/di/locator.dart
import 'package:get_it/get_it.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../services/location/location_service_interface.dart';
import '../services/location/mock_location_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<AuthProvider>(() => AuthProvider());
  locator.registerLazySingleton<ILocationService>(() => MockLocationService());
}