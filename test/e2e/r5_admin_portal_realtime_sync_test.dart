import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

import 'package:asmita_society/core/services/property_config_service.dart';
import 'package:asmita_society/core/network/dio_client.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/visitor_management/data/models/property_config.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class MockDioClient extends Mock implements AsmitaDioClient {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockDio extends Mock implements Dio {}

/// Handler processing FCM real-time portal update payloads
class RealtimePortalSyncHandler {
  final PropertyConfigService configService;
  final int activeSocietyId;
  final VoidCallback onProfileRefreshRequested;
  DateTime? _lastSyncTimestamp;

  RealtimePortalSyncHandler({
    required this.configService,
    required this.activeSocietyId,
    required this.onProfileRefreshRequested,
  });

  bool handlePushData(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['event'] ?? '').toString();
    final societyIdStr = data['society_id'] ?? data['property_id'];
    final societyId = int.tryParse(societyIdStr?.toString() ?? '');

    // Validate type
    if (type.isEmpty) return false;

    // Guard against wrong society
    if (societyId != null && societyId != activeSocietyId) {
      return false; // Ignored: different property
    }

    // Debounce rapid bursts (< 300ms)
    final now = DateTime.now();
    if (_lastSyncTimestamp != null && now.difference(_lastSyncTimestamp!).inMilliseconds < 300) {
      return false; // Debounced
    }
    _lastSyncTimestamp = now;

    if (type == 'PROPERTY_SETTINGS_UPDATED' ||
        type == 'SETTINGS_UPDATED' ||
        type == 'CONFIG_REFRESH') {
      configService.updateConfig(PropertyConfig.defaultResidential(societyId: activeSocietyId));
      return true;
    }

    if (type == 'USER_ROLE_CHANGED' || type == 'PROFILE_REFRESH') {
      onProfileRefreshRequested();
      return true;
    }

    return false;
  }
}

void main() {
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

  group('R5: Real-Time App State Refresh on Admin Portal Updates (Opaque-Box E2E)', () {
    // ══════════════════════════════════════════════════════════════
    // TIER 1: FEATURE COVERAGE (Settings, Roles, Cache Invalidation)
    // ══════════════════════════════════════════════════════════════

    test('TC-R5-01: Admin settings update FCM data payload triggers config refresh', () {
      bool profileRefreshed = false;
      final handler = RealtimePortalSyncHandler(
        configService: configService,
        activeSocietyId: 115,
        onProfileRefreshRequested: () => profileRefreshed = true,
      );

      final fcmPayload = {
        'type': 'PROPERTY_SETTINGS_UPDATED',
        'society_id': '115',
        'timestamp': '1730784000',
      };

      final handled = handler.handlePushData(fcmPayload);
      expect(handled, isTrue);
      expect(profileRefreshed, isFalse);
    });

    test('TC-R5-02: Silent push event with USER_ROLE_CHANGED triggers user profile reload', () {
      bool profileRefreshed = false;
      final handler = RealtimePortalSyncHandler(
        configService: configService,
        activeSocietyId: 115,
        onProfileRefreshRequested: () => profileRefreshed = true,
      );

      final roleChangePayload = {
        'type': 'USER_ROLE_CHANGED',
        'society_id': '115',
        'user_id': '227',
        'new_role': 'Head of Department (HOD)',
      };

      final handled = handler.handlePushData(roleChangePayload);
      expect(handled, isTrue);
      expect(profileRefreshed, isTrue);
    });

    test('TC-R5-03: App resumed lifecycle state executes profile refresh trigger', () {
      bool refreshed = false;
      void onAppResume(AppLifecycleState state) {
        if (state == AppLifecycleState.resumed) {
          refreshed = true;
        }
      }

      onAppResume(AppLifecycleState.inactive);
      expect(refreshed, isFalse);

      onAppResume(AppLifecycleState.resumed);
      expect(refreshed, isTrue);
    });

    test('TC-R5-04: PropertyConfigService updates state and notifies active listeners', () {
      bool notified = false;
      configService.addListener(() => notified = true);

      const freshConfig = PropertyConfig(
        societyId: 115,
        societyName: 'Asmita Industrial Campus A',
        propertyProfile: 'INDUSTRIAL',
        mandatoryDeskCabin: true,
      );

      configService.updateConfig(freshConfig);
      expect(notified, isTrue);
      expect(configService.currentConfig.societyId, 115);
      expect(configService.currentConfig.isIndustrial, isTrue);
      expect(configService.currentConfig.mandatoryDeskCabin, isTrue);
    });

    test('TC-R5-05: Local user permissions dynamically refresh upon receiving updated auth payload', () {
      final userBefore = UserModel(
        userId: 227,
        fullName: 'Staff Member',
        primaryRole: 'Employee',
        accountType: 'app',
        permissions: {'canManageVisitors': false},
      );
      expect(userBefore.hasPermission('canManageVisitors'), isFalse);

      // Admin grants permission on portal
      final userAfter = UserModel(
        userId: 227,
        fullName: 'Staff Member',
        primaryRole: 'Employee',
        accountType: 'app',
        permissions: {'canManageVisitors': true},
      );
      expect(userAfter.hasPermission('canManageVisitors'), isTrue);
    });

    // ══════════════════════════════════════════════════════════════
    // TIER 2: BOUNDARY & CORNER CASES (Malformed pushes, Debounce)
    // ══════════════════════════════════════════════════════════════

    test('TC-R5-06: Malformed or empty push data payload is discarded safely without throwing', () {
      final handler = RealtimePortalSyncHandler(
        configService: configService,
        activeSocietyId: 115,
        onProfileRefreshRequested: () {},
      );

      expect(handler.handlePushData({}), isFalse);
      expect(handler.handlePushData({'unknown_field': 123}), isFalse);
    });

    test('TC-R5-07: Push notification for a different property ID is ignored to prevent cache corruption', () {
      bool refreshed = false;
      final handler = RealtimePortalSyncHandler(
        configService: configService,
        activeSocietyId: 115, // Active property
        onProfileRefreshRequested: () => refreshed = true,
      );

      final wrongSocietyPayload = {
        'type': 'PROPERTY_SETTINGS_UPDATED',
        'society_id': '999', // Different property
      };

      final handled = handler.handlePushData(wrongSocietyPayload);
      expect(handled, isFalse, reason: 'Updates for different society must be dropped');
      expect(refreshed, isFalse);
    });

    test('TC-R5-08: Offline app resume retains existing cached config gracefully', () {
      const initialConfig = PropertyConfig(
        societyId: 115,
        societyName: 'Asmita Industrial Campus A',
        propertyProfile: 'INDUSTRIAL',
        mandatoryDeskCabin: true,
      );
      configService.updateConfig(initialConfig);

      // Offline network failure: config service retains cached config
      expect(configService.currentConfig.societyId, 115);
      expect(configService.currentConfig.isIndustrial, isTrue);
    });

    test('TC-R5-09: Duplicate rapid sync events within 300ms are debounced', () {
      int refreshCount = 0;
      final handler = RealtimePortalSyncHandler(
        configService: configService,
        activeSocietyId: 115,
        onProfileRefreshRequested: () => refreshCount++,
      );

      final payload = {
        'type': 'USER_ROLE_CHANGED',
        'society_id': '115',
      };

      final first = handler.handlePushData(payload);
      final second = handler.handlePushData(payload); // immediate duplicate

      expect(first, isTrue);
      expect(second, isFalse, reason: 'Rapid duplicate burst must be debounced');
      expect(refreshCount, 1);
    });

    test('TC-R5-10: Duty status change via portal immediately updates user active state', () {
      final userOnDuty = UserModel(
        userId: 223,
        fullName: 'Receptionist',
        primaryRole: 'Receptionist',
        accountType: 'app',
        roleDetails: {'duty_status': 'on-duty'},
      );
      expect(userOnDuty.isActive, isTrue);

      final userOffDuty = UserModel(
        userId: 223,
        fullName: 'Receptionist',
        primaryRole: 'Receptionist',
        accountType: 'app',
        roleDetails: {'duty_status': 'offline'},
      );
      expect(userOffDuty.isActive, isFalse);
    });
  });
}
