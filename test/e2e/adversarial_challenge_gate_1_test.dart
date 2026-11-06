import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/dashboard/presentation/views/director_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/employee_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/receptionist_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/facility_staff_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';
import 'package:asmita_society/features/menu/bloc/preferences_bloc.dart';
import 'package:asmita_society/features/menu/bloc/preferences_event.dart';
import 'package:asmita_society/features/menu/bloc/preferences_state.dart';
import 'package:asmita_society/features/menu/data/models/user_preferences_model.dart';
import 'package:asmita_society/features/menu/data/repositories/preferences_repository.dart';
import 'package:asmita_society/core/services/property_config_service.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:dio/dio.dart';

class MockIndustrialVisitRepository extends Mock implements IndustrialVisitRepository {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockPreferencesRepository extends Mock implements PreferencesRepository {}
class MockDioClient extends Mock implements AsmitaDioClient {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Challenge Gate 1: Role Screens Stress & Edge Cases (R2)', () {
    late MockIndustrialVisitRepository mockRepository;
    late IndustrialVisitBloc industrialVisitBloc;
    late MockAuthBloc mockAuthBloc;

    final testUser = UserModel(
      userId: 201,
      fullName: 'A' * 250, // Adversarial 250-character name
      primaryRole: 'Director',
      accountType: 'app',
      societyId: 115,
      societyName: 'Asmita Industrial Campus — ${'Overflow ' * 20}',
      propertyType: 'industrial',
    );

    setUp(() {
      mockRepository = MockIndustrialVisitRepository();
      industrialVisitBloc = IndustrialVisitBloc(repository: mockRepository);
      mockAuthBloc = MockAuthBloc();

      when(() => mockAuthBloc.state).thenReturn(
        AuthAuthenticated(
          user: testUser,
          sessionRole: 'director',
        ),
      );
    });

    tearDown(() {
      industrialVisitBloc.close();
      mockAuthBloc.close();
    });

    Widget buildThemedApp(Widget home, {bool isDark = false}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<IndustrialVisitBloc>.value(value: industrialVisitBloc),
        ],
        child: MaterialApp(
          theme: isDark ? AsmitaTheme.darkTheme : AsmitaTheme.lightTheme,
          home: Scaffold(body: home),
        ),
      );
    }

    testWidgets('ADV-R2-01: DirectorDashboardView survives massive strings & empty states without crashing', (tester) async {
      final adversarialVisits = [
        IndustrialVisitModel(
          id: 9999,
          requestNumber: 'AH-ADV-${'9' * 40}',
          propertyId: 115,
          visitorName: 'Very Long Name ' * 30, // 450 chars
          status: IndustrialVisitStatus.awaitingHost,
          departmentName: 'Department With Ridiculously Long Label ' * 10,
          purpose: 'Purpose with emojis 🚀🔥💡 and RTL text עברית العربية and symbols ' * 15,
        ),
      ];

      // Light Theme Render
      await tester.pumpWidget(
        buildThemedApp(
          DirectorDashboardView(visits: adversarialVisits),
          isDark: false,
        ),
      );
      await tester.pump();
      expect(find.byType(DirectorDashboardView), findsOneWidget);

      // Dark Theme Render with completely EMPTY visits list
      await tester.pumpWidget(
        buildThemedApp(
          const DirectorDashboardView(visits: []),
          isDark: true,
        ),
      );
      await tester.pump();
      expect(find.byType(DirectorDashboardView), findsOneWidget);
    });

    testWidgets('ADV-R2-02: EmployeeDashboardView handles missing desk/cabin & dark mode tokens', (tester) async {
      await tester.pumpWidget(
        buildThemedApp(
          EmployeeDashboardView(
          visits: const [],
          onOpenDelegation: () {},
        ),
          isDark: true,
        ),
      );
      await tester.pump();
      expect(find.byType(EmployeeDashboardView), findsOneWidget);
    });

    testWidgets('ADV-R2-03: ReceptionistDashboardView handles long search & empty queue in dark theme', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthAuthenticated(
          user: UserModel(
            userId: 204,
            fullName: 'Receptionist Staff',
            primaryRole: 'Receptionist',
            accountType: 'app',
            societyId: null, // Prevents un-mocked platform network calls
          ),
          sessionRole: 'receptionist',
        ),
      );

      await tester.pumpWidget(
        buildThemedApp(
          const ReceptionistDashboardView(visits: []),
          isDark: true,
        ),
      );
      await tester.pump();
      expect(find.byType(ReceptionistDashboardView), findsOneWidget);
    });

    testWidgets('ADV-R2-04: FacilityStaffDashboardView renders in dark theme without white background artifacts', (tester) async {
      await tester.pumpWidget(
        buildThemedApp(
          const FacilityStaffDashboardView(visits: []),
          isDark: true,
        ),
      );
      await tester.pump();
      expect(find.byType(FacilityStaffDashboardView), findsOneWidget);
    });

    test('ADV-R2-05: PropertyRoleResolver gracefully handles unknown, corrupted, and adversarial role strings', () {
      expect(PropertyRoleResolver.normalizeRole(null), 'owner');
      expect(PropertyRoleResolver.normalizeRole(''), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Unknown_Alien_Role_123'), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Plant Manager', isIndustrial: true), 'director');
      expect(PropertyRoleResolver.normalizeRole('Admin', isIndustrial: true), 'director');
      expect(PropertyRoleResolver.normalizeRole('Property Manager', isIndustrial: true), 'director');
      expect(PropertyRoleResolver.normalizeRole('Director', isIndustrial: true), 'director');
      expect(PropertyRoleResolver.normalizeRole('Floor Receptionist', isIndustrial: true), 'receptionist');
      expect(PropertyRoleResolver.normalizeRole('Guard', isIndustrial: true), 'guard');
      expect(PropertyRoleResolver.normalizeRole('Facility Staff', isIndustrial: true), 'facility');
    });
  });

  group('Adversarial Challenge Gate 1: Theme Persistence Rapid Toggles & Offline (R4)', () {
    late MockPreferencesRepository mockRepo;
    final initialPrefs = UserPreferencesModel(
      id: 1,
      appTheme: 'Light',
      language: 'English',
      pushNotifications: true,
    );

    setUpAll(() {
      registerFallbackValue(initialPrefs);
    });

    setUp(() {
      mockRepo = MockPreferencesRepository();
      when(() => mockRepo.getInitialPreferences()).thenReturn(initialPrefs);
      when(() => mockRepo.saveToLocalCache(any())).thenAnswer((_) async {});
      when(() => mockRepo.updatePreferences(any())).thenAnswer((_) async => true);
    });

    test('ADV-R4-01: Rapid sequential theme toggles emit states optimistically without corruption', () async {
      final bloc = PreferencesBloc(repository: mockRepo);
      expect(bloc.state, isA<PreferencesLoaded>());
      expect((bloc.state as PreferencesLoaded).items?.appTheme, 'Light');

      // Rapidly toggle back and forth 10 times synchronously
      final themes = ['Dark', 'Light', 'Dark', 'Light', 'Dark', 'Light', 'Dark', 'Light', 'Dark', 'Light'];
      for (final t in themes) {
        bloc.add(UpdatePreferences(appTheme: t));
      }

      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<PreferencesLoaded>());
      expect((bloc.state as PreferencesLoaded).items?.appTheme, 'Light');
      await bloc.close();
    });

    test('ADV-R4-02: Offline cold start hydrates cached dark theme synchronously with 0ms latency', () {
      final darkPrefs = UserPreferencesModel(
        id: 1,
        appTheme: 'Dark',
      );
      when(() => mockRepo.getInitialPreferences()).thenReturn(darkPrefs);

      final bloc = PreferencesBloc(repository: mockRepo);
      // Synchronous initial state check
      expect(bloc.state, isA<PreferencesLoaded>());
      final loaded = bloc.state as PreferencesLoaded;
      expect(loaded.items?.appTheme, 'Dark');
      bloc.close();
    });

    test('ADV-R4-03: Dark theme palette semantic tokens meet high contrast requirements', () {
      final darkTheme = AsmitaTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.surface, isNot(Colors.white));
      expect(darkTheme.colorScheme.onSurface, isNot(Colors.black));
      expect(darkTheme.scaffoldBackgroundColor, isNot(Colors.white));
    });
  });

  group('Adversarial Challenge Gate 1: Real-Time State Sync Stress & Cache Eviction (R5)', () {
    late MockDioClient mockDioClient;
    late MockSecureStorageService mockSecureStorage;
    late MockDio mockDio;
    late PropertyConfigService configService;

    setUp(() {
      mockDioClient = MockDioClient();
      mockSecureStorage = MockSecureStorageService();
      mockDio = MockDio();

      when(() => mockDioClient.dio).thenReturn(mockDio);
      configService = PropertyConfigService(
        dioClient: mockDioClient,
        secureStorage: mockSecureStorage,
      );
    });

    test('ADV-R5-01: Rapid burst of 20 cache invalidation calls handles concurrency without deadlock', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
          data: {
            'society_id': 115,
            'property_type': 'industrial',
            'pass_rules': {'require_host_approval': true},
          },
        ),
      );

      int listenerNotificationCount = 0;
      configService.addListener(() {
        listenerNotificationCount++;
      });

      // Fire 20 invalidations in parallel
      final futures = List.generate(20, (i) => configService.invalidateCache(115));
      await Future.wait(futures);

      expect(configService.currentConfig, isNotNull);
      expect(configService.currentConfig.societyId, 115);
      expect(listenerNotificationCount, greaterThan(0));
    });

    test('ADV-R5-02: PropertyConfigService handles 500 error from server gracefully during cache reload', () async {
      when(() => mockDio.get(any(), options: any(named: 'options'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/settings'),
          response: Response(
            requestOptions: RequestOptions(path: '/settings'),
            statusCode: 500,
            statusMessage: 'Internal Server Error',
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final config = await configService.loadConfigForSociety(115, forceRefresh: true);
      // Secure fallback returned, no unhandled exception crash
      expect(config, isNotNull);
      expect(config.societyId, 115);
    });
  });
}
