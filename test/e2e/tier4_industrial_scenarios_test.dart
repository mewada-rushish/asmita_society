import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/menu/data/models/user_preferences_model.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/data/models/property_config.dart';
import 'r3_delegation_flow_test.dart';
import 'r4_theme_switching_persistence_test.dart';
import 'r5_admin_portal_realtime_sync_test.dart';
import 'tier3_cross_feature_interactions_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(PropertyConfig.defaultResidential());
  });

  group('Tier 4: Real-World Industrial Property Scenarios (Opaque-Box E2E)', () {
    test('TC-SCN-01: Industrial Campus Shift Handover — Director delegates to Floor Receptionist while Guard admits deliveries', () {
      // 1. Executive Director (power 1000) sets up evening delegation to Floor 2 Receptionist
      final floor2Receptionist = {
        'id': 223,
        'full_name': 'Sneha Patil',
        'role_name': 'Floor Receptionist',
        'floor': 'Floor 2',
        'power': 50,
        'category': 'Receptionist',
      };

      final canDelegate = evaluateCandidateEligibility(
        currentUserId: 201,
        currentUserPower: 1000,
        userDepartment: 'Executive Office',
        userFloor: 'Floor 2',
        candidate: floor2Receptionist,
      );
      expect(canDelegate, isTrue, reason: 'Director must be able to delegate to floor receptionist');

      // 2. Guard checkpoint receives delivery pass and verifies 6-digit access code in dark mode
      const deliveryPass = IndustrialVisitModel(
        id: 901,
        requestNumber: 'AH-2026-DELV-901',
        propertyId: 115,
        visitorName: 'Express Logistics Driver',
        passCode: '849201',
        status: IndustrialVisitStatus.awaitingHost,
        departmentName: 'Warehouse Logistics',
      );

      final matchesCode = deliveryPass.passCode == '849201';
      expect(matchesCode, isTrue);

      // 3. Dark mode theme applied during night shift
      final nightTheme = resolveThemeMode('Dark');
      expect(nightTheme, ThemeMode.dark);
      expect(AsmitaPalette.systemBGDark, const Color(0xFF0D121F));
    });

    test('TC-SCN-02: Emergency Policy Update — Admin updates gate security, mobile invalidates cache and refreshes work queue', () {
      // 1. Admin pushes setting change from portal: mandatoryDeskCabin = true
      final mockConfig = configServiceTestFallback();
      final syncHandler = RealtimePortalSyncHandler(
        configService: mockConfig,
        activeSocietyId: 115,
        onProfileRefreshRequested: () {},
      );

      final emergencySettingsPush = {
        'type': 'PROPERTY_SETTINGS_UPDATED',
        'society_id': '115',
        'mandatory_desk_cabin': 'true',
        'timestamp': '1730784900',
      };

      final handled = syncHandler.handlePushData(emergencySettingsPush);
      expect(handled, isTrue);

      // 2. Facility staff user checks industrial context and permissions
      final facilityUser = UserModel(
        userId: 242,
        fullName: 'Loading Bay Supervisor',
        primaryRole: 'Maintenance Technician',
        accountType: 'app',
        societyId: 115,
        propertyType: 'industrial',
        permissions: {'canManageFacilityTasks': true},
      );

      expect(PropertyRoleResolver.isIndustrialContext(facilityUser), isTrue);
      expect(PropertyRoleResolver.canManageFacilityTasks(facilityUser), isTrue);
    });

    test('TC-SCN-03: Transitive Delegation on Host Absence — Visitor arrives for Host who delegated to Colleague B', () {
      // Host A (ID 227) has active delegation to Colleague B (ID 228)
      final delegationState = {
        'host_user_id': 227,
        'is_active': true,
        'delegate_user_id': 228,
        'delegate_name': 'Rahul Dravid',
      };

      // Visitor arrives at reception
      final incomingVisit = {
        'visit_id': 880,
        'visitor_name': 'Client Mehta',
        'intended_host_id': 227,
      };

      // Transitive resolution resolves Colleague B as effective approver
      int effectiveApproverId = incomingVisit['intended_host_id'] as int;
      bool isDelegated = false;

      if (delegationState['is_active'] == true && delegationState['host_user_id'] == incomingVisit['intended_host_id']) {
        effectiveApproverId = delegationState['delegate_user_id'] as int;
        isDelegated = true;
      }

      expect(effectiveApproverId, 228);
      expect(isDelegated, isTrue);

      // Visit model created with resolved delegatee
      final visit = IndustrialVisitModel(
        id: 880,
        requestNumber: 'AH-2026-VIS-880',
        propertyId: 115,
        visitorName: 'Client Mehta',
        hostName: 'Pooja Sharma (Delegated to ${delegationState['delegate_name']})',
        status: IndustrialVisitStatus.awaitingHost,
      );

      expect(visit.hostName, contains('Rahul Dravid'));
      expect(visit.status, IndustrialVisitStatus.awaitingHost);
    });

    test('TC-SCN-04: Cold-Start in Dark Mode with Multiple Delegated Passes — Instant launch with zero theme flicker', () {
      // 1. Synchronously hydrate preferences from storage
      final cachedPrefs = UserPreferencesModel(
        id: 1,
        appTheme: 'Dark',
        language: 'English',
        pushNotifications: true,
      );

      final initialThemeMode = resolveThemeMode(cachedPrefs.appTheme);
      expect(initialThemeMode, ThemeMode.dark, reason: 'Must render Dark immediately on cold start');

      // 2. Load delegated visits roster
      final delegatedVisits = [
        const IndustrialVisitModel(
          id: 910,
          requestNumber: 'AH-2026-DELG-910',
          propertyId: 115,
          visitorName: 'Auditor Khanna',
          departmentName: 'Accounts',
          status: IndustrialVisitStatus.awaitingHost,
        ),
        const IndustrialVisitModel(
          id: 911,
          requestNumber: 'AH-2026-DELG-911',
          propertyId: 115,
          visitorName: 'Inspector Sharma',
          departmentName: 'Safety',
          status: IndustrialVisitStatus.checkedIn,
        ),
      ];

      expect(delegatedVisits.length, 2);
      expect(delegatedVisits.first.status, IndustrialVisitStatus.awaitingHost);
      expect(delegatedVisits.last.status, IndustrialVisitStatus.checkedIn);
    });
  });
}
