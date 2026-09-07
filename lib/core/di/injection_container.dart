import 'package:get_it/get_it.dart';
import '../security/secure_storage_service.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/property_repository.dart';
import '../../features/community/data/repositories/community_repository.dart';
import '../../features/visitor_management/data/repositories/visitor_repository.dart';
import '../../features/services/data/repositories/amenities_repository.dart';
import '../../features/services/data/repositories/daily_help_repository.dart';
import '../../features/dashboard/data/repositories/search_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  
  sl.registerLazySingleton<AsmitaDioClient>(
    () => AsmitaDioClient(sl<SecureStorageService>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(dio: sl<AsmitaDioClient>().dio),
  );
  
  sl.registerLazySingleton<PropertyRepository>(
    () => PropertyRepository(dio: sl<AsmitaDioClient>().dio),
  );

  sl.registerLazySingleton<ApiCommunityRepository>(
    () => ApiCommunityRepository(
      dio: sl<AsmitaDioClient>().dio,
      secureStorage: sl<SecureStorageService>(),
    ),
  );

  sl.registerLazySingleton<VisitorRepository>(
    () => VisitorRepository(dio: sl<AsmitaDioClient>().dio),
  );

  sl.registerLazySingleton<AmenitiesRepository>(
    () => AmenitiesRepository(dio: sl<AsmitaDioClient>().dio),
  );

  sl.registerLazySingleton<DailyHelpRepository>(
    () => DailyHelpRepository(dio: sl<AsmitaDioClient>().dio),
  );

  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepository(dio: sl<AsmitaDioClient>().dio),
  );
}
