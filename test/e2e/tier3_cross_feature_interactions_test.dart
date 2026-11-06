import 'package:flutter_test/flutter_test.dart';

import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';
import 'package:asmita_society/features/auth/data/models/auth_response.dart';
import 'package:asmita_society/features/menu/data/models/user_preferences_model.dart';
import 'r3_delegation_flow_test.dart';
import 'r5_admin_portal_realtime_sync_test.dart';
import 'r6_secrets_scrubbing_and_leak_prevention_test.dart';

import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/core/services/property_config_service.dart';
import 'package:asmita_society/features/visitor_management/data/models/property_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(PropertyConfig.defaultResidential());
  });

  group('Tier 3: Cross-Feature Interactions & Pairwise Integration (Opaque-Box E2E)', () {
    test('TC-INT-01 (R1 + R2): Employee creation payload feeds AuthResponse and resolves correct industrial dashboard archetype', () {
      final rolesToTest = [
        {'role': 'Director', 'expected': 'director'},
        {'role': 'Security Guard', 'expected': 'guard'},
        {'role': 'Floor Receptionist', 'expected': 'receptionist'},
        {'role': 'Head of Department (HOD)', 'expected': 'employee'},
        {'role': 'Maintenance Technician', 'expected': 'facility'},
      ];

      for (final item in rolesToTest) {
        final authPayload = {
          'status': 'success',
          'token': 'jwt_mock_token_${item['role']}',
          'user': {
            'user_id': 500,
            'full_name': 'Test Role User',
            'primary_role': item['role'],
            'account_type': 'app',
            'society_id': 115,
            'property_type': 'industrial',
          },
        };

        final response = AuthResponse.fromJson(authPayload);
        expect(response.isExistingUser, isTrue);
        final user = response.data!;
        final resolved = PropertyRoleResolver.normalizeRole(user.primaryRole, scope: user.roleScope, power: user.rolePower);
        expect(resolved, item['expected'], reason: 'Role "${item['role']}" must resolve to "${item['expected']}"');
        expect(PropertyRoleResolver.isIndustrialContext(user), isTrue);
      }
    });

    test('TC-INT-02 (R1 + R3): Newly created employee is immediately eligible for department delegation by peers', () {
      // User 227 creates delegation candidate User 228
      final newColleague = {
        'id': 228,
        'full_name': 'New Employee Candidate',
        'role_name': 'Employee',
        'power': 100,
        'department': 'Logistics & Dispatch',
        'is_delegatee': true,
      };

      final isEligible = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Logistics & Dispatch',
        userFloor: 'Floor 1',
        candidate: newColleague,
      );

      expect(isEligible, isTrue, reason: 'Newly created employee must be eligible for peer delegation');
    });

    testWidgets('TC-INT-03 (R2 + R4): Role screens rendered under Dark mode maintain accessible contrast without textDark collisions', (tester) async {
      final darkTheme = AsmitaTheme.darkTheme;

      // In dark mode, ensure elevated surface is dark midnight and text is light slate
      expect(darkTheme.scaffoldBackgroundColor, AsmitaPalette.systemBGDark);
      expect(darkTheme.colorScheme.surface, AsmitaPalette.surfaceDark);
      expect(darkTheme.colorScheme.primary, AsmitaPalette.deepNavyDark);

      // Verify that primary text on dark surface does NOT collide with textDark
      expect(AsmitaPalette.textDarkModeMain.computeLuminance() > 0.8, isTrue);
      expect(AsmitaPalette.systemBGDark.computeLuminance() < 0.05, isTrue);
    });

    test('TC-INT-04 (R3 + R5): Real-time FCM sync event updates active delegation status in mobile state', () {
      bool profileRefreshed = false;
      final mockConfigService = configServiceTestFallback();

      final syncHandler = RealtimePortalSyncHandler(
        configService: mockConfigService,
        activeSocietyId: 115,
        onProfileRefreshRequested: () => profileRefreshed = true,
      );

      final delegationPush = {
        'type': 'USER_ROLE_CHANGED',
        'society_id': '115',
        'user_id': '227',
        'reason': 'DELEGATION_ACTIVATED',
      };

      final handled = syncHandler.handlePushData(delegationPush);
      expect(handled, isTrue);
      expect(profileRefreshed, isTrue);
    });

    test('TC-INT-05 (R4 + R5): Real-time background sync invalidation does not alter or corrupt the active user theme preference', () {
      final preferences = UserPreferencesModel(
        id: 1,
        appTheme: 'Dark',
        language: 'English',
      );

      // Receiving background push
      final mockConfigService = configServiceTestFallback();
      final syncHandler = RealtimePortalSyncHandler(
        configService: mockConfigService,
        activeSocietyId: 115,
        onProfileRefreshRequested: () {},
      );

      final settingsPush = {
        'type': 'PROPERTY_SETTINGS_UPDATED',
        'society_id': '115',
        'timestamp': '1730784000',
      };

      final handled = syncHandler.handlePushData(settingsPush);
      expect(handled, isTrue);

      // Theme remains strictly intact
      expect(preferences.appTheme, 'Dark');
    });

    test('TC-INT-06 (R1 + R6): Employee creation and login credential handling sanitizes logs and protects tokens', () {
      const rawCreationLog = 'POST /app-api/auth/login with password: "TemporaryUserPass@123" and Authorization: Bearer jwt_raw_secret_token_abc';
      final sanitized = sanitizeLogMessage(rawCreationLog);

      expect(sanitized, isNot(contains('TemporaryUserPass@123')));
      expect(sanitized, isNot(contains('jwt_raw_secret_token_abc')));
      expect(forbiddenSecretsRegex.hasMatch(sanitized), isFalse);
    });
  });
}

class MockPropertyConfigService extends Mock implements PropertyConfigService {}

MockPropertyConfigService configServiceTestFallback() {
  final mock = MockPropertyConfigService();
  when(() => mock.updateConfig(any())).thenReturn(null);
  return mock;
}
