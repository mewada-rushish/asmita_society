import 'package:get_it/get_it.dart';
import '../security/secure_storage_service.dart';
import '../services/firebase_messaging_service.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/property_repository.dart';
import '../../features/community/data/repositories/community_repository.dart';
import '../../features/community/data/repositories/community_post_repository.dart';
import '../../features/visitor_management/data/repositories/visitor_repository.dart';
import '../../features/services/data/repositories/amenities_repository.dart';
import '../../features/services/data/repositories/daily_help_repository.dart';
import '../../features/dashboard/data/repositories/search_repository.dart';
import '../../features/visitor_management/data/repositories/guard_gate_repository.dart';
import '../../features/menu/data/repositories/family_repository.dart';
import '../../features/menu/data/repositories/pets_repository.dart';
import '../../features/menu/data/repositories/vehicles_repository.dart';
import '../../features/menu/data/repositories/tenant_repository.dart';
import '../../features/menu/data/repositories/preferences_repository.dart';
import '../../features/menu/data/repositories/society_repository.dart';
import '../../features/menu/data/repositories/support_repository.dart';
import '../../features/menu/data/repositories/history_request_repository.dart';

import '../../features/menu/bloc/family_bloc.dart';
import '../../features/menu/bloc/pets_bloc.dart';
import '../../features/menu/bloc/vehicles_bloc.dart';
import '../../features/menu/bloc/tenant_bloc.dart';
import '../../features/menu/bloc/preferences_bloc.dart';
import '../../features/menu/bloc/society_bloc.dart';
import '../../features/menu/bloc/support_bloc.dart';
import '../../features/menu/bloc/historyrequest_bloc.dart';
final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  
  sl.registerLazySingleton<FirebaseMessagingService>(
    () => FirebaseMessagingService(sl<SecureStorageService>(), sl<AuthRepository>()),
  );
  
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

  sl.registerLazySingleton<CommunityPostRepository>(
    () => ApiCommunityPostRepository(
      dio: sl<AsmitaDioClient>().dio,
    ),
  );

  sl.registerLazySingleton<GuardGateRepository>(
    () => GuardGateRepository(sl<AsmitaDioClient>().dio),
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
  
  // Menu Repositories
  sl.registerLazySingleton<FamilyRepository>(() => FamilyRepository(dio: sl<AsmitaDioClient>().dio));
  sl.registerLazySingleton<PetsRepository>(() => PetsRepository(dio: sl<AsmitaDioClient>().dio));
  sl.registerLazySingleton<VehiclesRepository>(() => VehiclesRepository(dio: sl<AsmitaDioClient>().dio));
  sl.registerLazySingleton<TenantRepository>(() => TenantRepository(dio: sl<AsmitaDioClient>().dio));
  sl.registerLazySingleton<PreferencesRepository>(() => PreferencesRepository(dio: sl<AsmitaDioClient>().dio));
  sl.registerLazySingleton<SocietyRepository>(() => SocietyRepository(dio: sl<AsmitaDioClient>().dio));
  sl.registerLazySingleton<SupportRepository>(() => SupportRepository(dio: sl<AsmitaDioClient>().dio));
  sl.registerLazySingleton<HistoryRequestRepository>(() => HistoryRequestRepository(dio: sl<AsmitaDioClient>().dio));

  // Menu Blocs
  sl.registerFactory(() => FamilyBloc(repository: sl()));
  sl.registerFactory(() => PetsBloc(repository: sl()));
  sl.registerFactory(() => VehiclesBloc(repository: sl()));
  sl.registerFactory(() => TenantBloc(repository: sl()));
  sl.registerFactory(() => PreferencesBloc(repository: sl()));
  sl.registerFactory(() => SocietyBloc(repository: sl()));
  sl.registerFactory(() => SupportBloc(repository: sl()));
  sl.registerFactory(() => HistoryRequestBloc(repository: sl()));
}
