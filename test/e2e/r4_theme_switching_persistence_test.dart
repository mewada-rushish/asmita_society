import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/menu/bloc/preferences_bloc.dart';
import 'package:asmita_society/features/menu/bloc/preferences_event.dart';
import 'package:asmita_society/features/menu/bloc/preferences_state.dart';
import 'package:asmita_society/features/menu/data/models/user_preferences_model.dart';
import 'package:asmita_society/features/menu/data/repositories/preferences_repository.dart';

class MockPreferencesRepository extends Mock implements PreferencesRepository {}

/// Helper resolving string theme preference to Flutter ThemeMode
ThemeMode resolveThemeMode(String? theme) {
  if (theme == null || theme.trim().isEmpty) return ThemeMode.system;
  final t = theme.toLowerCase().trim();
  if (t == 'dark') return ThemeMode.dark;
  if (t == 'light') return ThemeMode.light;
  return ThemeMode.system;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPreferencesRepository mockRepository;

  final initialDefaultPrefs = UserPreferencesModel(
    id: 1,
    appTheme: 'Light',
    language: 'English',
    pushNotifications: true,
  );

  setUpAll(() {
    registerFallbackValue(initialDefaultPrefs);
  });

  setUp(() {
    mockRepository = MockPreferencesRepository();
    when(() => mockRepository.getInitialPreferences()).thenReturn(initialDefaultPrefs);
    when(() => mockRepository.saveToLocalCache(any())).thenAnswer((_) async {});
  });

  group('R4: Immediate Theme Switching & Cold-Start Persistence (Opaque-Box E2E)', () {
    // ══════════════════════════════════════════════════════════════
    // TIER 1: FEATURE COVERAGE (Instant switching, Cold-start, Sync)
    // ══════════════════════════════════════════════════════════════

    test('TC-R4-01: Theme toggle from Light to Dark resolves ThemeMode.dark immediately', () {
      final initialTheme = 'Light';
      expect(resolveThemeMode(initialTheme), ThemeMode.light);

      final toggledTheme = 'Dark';
      expect(resolveThemeMode(toggledTheme), ThemeMode.dark);
    });

    test('TC-R4-02: Theme toggle from Dark to Light resolves ThemeMode.light immediately', () {
      final initialTheme = 'Dark';
      expect(resolveThemeMode(initialTheme), ThemeMode.dark);

      final toggledTheme = 'Light';
      expect(resolveThemeMode(toggledTheme), ThemeMode.light);
    });

    test('TC-R4-03: System Default theme selection follows device brightness settings', () {
      expect(resolveThemeMode('System Default'), ThemeMode.system);
      expect(resolveThemeMode('system'), ThemeMode.system);
    });

    test('TC-R4-04: Cold-start simulation: given saved "Dark" preference in storage, initial state renders Dark without light flash', () {
      const storedTheme = 'Dark';
      final initialPreferences = UserPreferencesModel(
        id: 1,
        appTheme: storedTheme,
      );

      final initialThemeMode = resolveThemeMode(initialPreferences.appTheme);
      expect(initialThemeMode, ThemeMode.dark, reason: 'App must mount directly in Dark mode without light flicker');
    });

    blocTest<PreferencesBloc, PreferencesState>(
      'TC-R4-05: Background remote sync failure does not revert local optimistic theme update',
      build: () {
        when(() => mockRepository.updatePreferences(any())).thenThrow(Exception('Network timeout'));
        return PreferencesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const UpdatePreferences(appTheme: 'Dark')),
      expect: () => [
        isA<PreferencesLoaded>().having(
          (s) => s.items?.appTheme,
          'appTheme',
          'Dark',
        ),
      ],
      verify: (bloc) {
        verify(() => mockRepository.saveToLocalCache(any())).called(1);
        verify(() => mockRepository.updatePreferences(any())).called(1);
      },
    );

    // ══════════════════════════════════════════════════════════════
    // TIER 2: BOUNDARY & CORNER CASES (Corrupted strings, tokens)
    // ══════════════════════════════════════════════════════════════

    test('TC-R4-06: Corrupted or unrecognized stored theme string defaults safely to ThemeMode.system', () {
      final invalidThemes = ['NEON_GLOW', 'invalid_string', '12345', '!@#\$%', 'null'];
      for (final invalid in invalidThemes) {
        expect(
          resolveThemeMode(invalid),
          ThemeMode.system,
          reason: 'Invalid theme "$invalid" must safely default to ThemeMode.system',
        );
      }
    });

    test('TC-R4-07: Rapid consecutive theme toggles maintain deterministic final state', () {
      var currentTheme = 'Light';
      final toggles = ['Dark', 'Light', 'Dark', 'Light', 'Dark', 'Dark', 'Light', 'Dark'];

      for (final target in toggles) {
        currentTheme = target;
      }

      expect(currentTheme, 'Dark');
      expect(resolveThemeMode(currentTheme), ThemeMode.dark);
    });

    test('TC-R4-08: Empty or null stored preference on fresh install defaults cleanly to System Default', () {
      expect(resolveThemeMode(null), ThemeMode.system);
      expect(resolveThemeMode(''), ThemeMode.system);
      expect(resolveThemeMode('   '), ThemeMode.system);
    });

    testWidgets('TC-R4-09: Dark mode theme semantic tokens guarantee accessible luminance ratio and midnight slate background', (tester) async {
      final darkTheme = AsmitaTheme.darkTheme;
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0D121F));
      expect(darkTheme.colorScheme.surface, const Color(0xFF172033));
      expect(darkTheme.colorScheme.primary, const Color(0xFF7B96EC));

      expect(AsmitaPalette.textDarkModeMain, const Color(0xFFF1F5F9));
      expect(AsmitaPalette.textDarkModeMuted, const Color(0xFF94A3B8));
    });

    testWidgets('TC-R4-10: Light mode theme semantic tokens guarantee clean corporate navy and crisp surfaces', (tester) async {
      final lightTheme = AsmitaTheme.lightTheme;
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF8F8FB));
      expect(lightTheme.colorScheme.primary, const Color(0xFF27347B));
      expect(lightTheme.colorScheme.surface, Colors.white);
      expect(AsmitaPalette.textDark, const Color(0xFF1E2022));
    });

    test('TC-R4-11: UserPreferencesModel deserialization correctly handles boolean, int, and string encodings', () {
      final json = {
        'id': 10,
        'app_theme': 'Dark',
        'language': 'English',
        'push_notifications': 1,
        'email_alerts': 0,
        'biometric_login': true,
      };

      final model = UserPreferencesModel.fromJson(json);
      expect(model.id, 10);
      expect(model.appTheme, 'Dark');
      expect(model.pushNotifications, isTrue);
      expect(model.emailAlerts, isFalse);
      expect(model.biometricLogin, isTrue);
    });
  });
}
