import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:asmita_society/features/menu/bloc/preferences_bloc.dart';
import 'package:asmita_society/features/menu/bloc/preferences_event.dart';
import 'package:asmita_society/features/menu/bloc/preferences_state.dart';
import 'package:asmita_society/features/menu/data/repositories/preferences_repository.dart';
import 'package:asmita_society/features/menu/data/models/user_preferences_model.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockDio;
  late MockSecureStorageService mockSecureStorage;
  late PreferencesRepository repository;
  late PreferencesBloc bloc;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorage = MockSecureStorageService();

    when(() => mockSecureStorage.getAppTheme()).thenAnswer((_) async => null);
    when(() => mockSecureStorage.getLanguage()).thenAnswer((_) async => 'English');
    when(() => mockSecureStorage.getBiometricLogin()).thenAnswer((_) async => false);
    when(() => mockSecureStorage.getApprovalSound()).thenAnswer((_) async => 'asmita_alert_1');
    when(() => mockSecureStorage.getNotificationSound()).thenAnswer((_) async => 'asmita_notification_1');
    when(() => mockSecureStorage.saveAppTheme(any())).thenAnswer((_) async {});
    when(() => mockSecureStorage.saveLanguage(any())).thenAnswer((_) async {});
    when(() => mockSecureStorage.saveBiometricLogin(any())).thenAnswer((_) async {});
    when(() => mockSecureStorage.saveApprovalSound(any())).thenAnswer((_) async {});
    when(() => mockSecureStorage.saveNotificationSound(any())).thenAnswer((_) async {});

    repository = PreferencesRepository(
      dio: mockDio,
      secureStorage: mockSecureStorage,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('PreferencesBloc — Milestone 5 (F9, F10 / R4) Theme Cold-Start & Switching', () {
    test('1. Synchronous Cold-Start Hydration: PreferencesBloc starts in PreferencesLoaded (not empty/unhydrated)', () {
      // Act
      bloc = PreferencesBloc(repository: repository);

      // Assert
      expect(bloc.state, isA<PreferencesLoaded>(),
          reason: 'Bloc MUST synchronously initialize in PreferencesLoaded to prevent cold-start flash/flicker');
      final loaded = bloc.state as PreferencesLoaded;
      expect(loaded.items, isNotNull);
      expect(loaded.items?.appTheme, equals('System Default'));
    });

    test('2. Cold-Start with Previously Cached Theme: Restores saved theme synchronously at construction', () {
      // Arrange - Seed local cache with Dark theme
      final cachedModel = UserPreferencesModel(
        id: 0,
        appTheme: 'Dark',
        language: 'English',
      );
      repository.saveToLocalCache(cachedModel);

      // Act - Instantiate new bloc simulating app cold-start
      bloc = PreferencesBloc(repository: repository);

      // Assert
      expect(bloc.state, isA<PreferencesLoaded>());
      final loaded = bloc.state as PreferencesLoaded;
      expect(loaded.items?.appTheme, equals('Dark'),
          reason: 'Cold-start must immediately render saved theme without network call delay');
    });

    test('3. Immediate Optimistic Theme Switching: Emits PreferencesLoaded instantly on UpdatePreferences before network completes', () async {
      // Arrange
      final completer = Completer<Response>();
      when(() => mockDio.put(any(), data: any(named: 'data')))
          .thenAnswer((_) => completer.future);

      bloc = PreferencesBloc(repository: repository);
      expect((bloc.state as PreferencesLoaded).items?.appTheme, equals('System Default'));

      final states = <PreferencesState>[];
      final subscription = bloc.stream.listen(states.add);

      // Act - Dispatch theme toggle to Dark
      bloc.add(const UpdatePreferences(appTheme: 'Dark'));

      // Wait a microtask for synchronous event dispatch and emission
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Assert - State was emitted immediately, while network call is STILL pending!
      expect(states.length, equals(1));
      expect(states.first, isA<PreferencesLoaded>());
      expect((states.first as PreferencesLoaded).items?.appTheme, equals('Dark'),
          reason: 'Theme state must update optimistically with 0ms UI latency');
      expect(completer.isCompleted, isFalse, reason: 'Network call must not block UI state emission');

      // Verify local storage was updated immediately
      verify(() => mockSecureStorage.saveAppTheme('Dark')).called(1);

      // Cleanup
      completer.complete(Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
      ));
      await subscription.cancel();
    });

    test('4. Restart Simulation: Newly created bloc picks up optimistic theme immediately from cache', () async {
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: ''), statusCode: 200),
      );

      // 1st App Session
      bloc = PreferencesBloc(repository: repository);
      bloc.add(const UpdatePreferences(appTheme: 'Dark'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect((bloc.state as PreferencesLoaded).items?.appTheme, equals('Dark'));

      // Simulate app restart / cold start (new bloc instance with same repository)
      final restartedBloc = PreferencesBloc(repository: repository);
      expect(restartedBloc.state, isA<PreferencesLoaded>());
      expect((restartedBloc.state as PreferencesLoaded).items?.appTheme, equals('Dark'),
          reason: 'App restart must never flash System/Light when Dark was chosen');
      restartedBloc.close();
    });

    test('5. Network Failure Resilience: Optimistic theme is preserved even if network PUT fails', () async {
      // Arrange - Network rejects with 500 error
      when(() => mockDio.put(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(requestOptions: RequestOptions(path: ''), statusCode: 500),
        ),
      );

      bloc = PreferencesBloc(repository: repository);
      bloc.add(const UpdatePreferences(appTheme: 'Dark'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Assert - Local state remains Dark
      expect(bloc.state, isA<PreferencesLoaded>());
      expect((bloc.state as PreferencesLoaded).items?.appTheme, equals('Dark'),
          reason: 'Theme must not roll back or flicker on temporary network failures');
    });
  });
}
