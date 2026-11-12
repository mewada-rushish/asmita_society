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
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_pass_check_in_screen.dart';

class MockIndustrialVisitRepository extends Mock implements IndustrialVisitRepository {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockIndustrialVisitRepository mockRepository;
  late IndustrialVisitBloc industrialVisitBloc;
  late MockAuthBloc mockAuthBloc;

  final testUser = UserModel(
    userId: 201,
    fullName: 'Test Executive User',
    primaryRole: 'Director',
    accountType: 'app',
    societyId: 115,
    societyName: 'Asmita Industrial Campus',
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
        home: home,
      ),
    );
  }

  group('R2: Industrial Role Screens, Feature Functionality & UI Theme (Opaque-Box E2E)', () {
    // ══════════════════════════════════════════════════════════════
    // TIER 1: FEATURE COVERAGE (All 5 Industrial Roles)
    // ══════════════════════════════════════════════════════════════

    testWidgets('TC-R2-01: DirectorDashboardView renders executive KPIs and quick actions', (tester) async {
      final visits = [
        IndustrialVisitModel(
          id: 101,
          requestNumber: 'AH-2026-DIR-101',
          propertyId: 115,
          visitorName: 'Mr. Arvind Gupta',
          status: IndustrialVisitStatus.awaitingHost,
          departmentName: 'Executive Suite',
          purpose: 'Quarterly Strategic Audit',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        buildThemedApp(
          DirectorDashboardView(visits: visits),
          isDark: false,
        ),
      );
      await tester.pump();

      expect(find.text('Mr. Arvind Gupta'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Inside'), findsOneWidget);
      expect(find.text('Pre-Approve'), findsOneWidget);
      expect(find.text('Meetings'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Pay Bills'), findsOneWidget);
    });

    testWidgets('TC-R2-02: EmployeeDashboardView renders hero card and pending approvals feed', (tester) async {
      final visits = [
        IndustrialVisitModel(
          id: 102,
          requestNumber: 'AH-2026-EMP-102',
          propertyId: 115,
          visitorName: 'Vendor Neha Verma',
          status: IndustrialVisitStatus.awaitingHost,
          purpose: 'Supply Chain Invoicing',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        buildThemedApp(
          EmployeeDashboardView(
            employeeName: 'Kunal Joshi',
            departmentName: 'Engineering',
            cabinNumber: 'CAB-204',
            deskNumber: 'DESK-15',
            visits: visits,
            onOpenDelegation: () {},
          ),
          isDark: false,
        ),
      );
      await tester.pump();

      expect(find.text('Kunal Joshi'), findsOneWidget);
      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('CAB-204'), findsOneWidget);
      expect(find.text('DESK-15'), findsOneWidget);
      expect(find.text('Vendor Neha Verma'), findsOneWidget);
      expect(find.text('Pre-Approve'), findsOneWidget);
      expect(find.text('Meetings'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Pay Bills'), findsOneWidget);
    });

    testWidgets('TC-R2-03: GuardPassCheckInScreen renders gate checkpoint verification and terminal banner', (tester) async {
      await tester.pumpWidget(
        buildThemedApp(
          const GuardPassCheckInScreen(gateId: 1),
          isDark: false,
        ),
      );
      await tester.pump();

      expect(find.text('Gate 1 Pedestrian Pass Verification'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('TC-R2-04: ReceptionistDashboardView renders duty toggle switch and waiting list', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthAuthenticated(
          user: UserModel(
            userId: 204,
            fullName: 'Receptionist Staff',
            primaryRole: 'Receptionist',
            accountType: 'app',
            societyId: null, // Prevents background static prefetch in tests
          ),
          sessionRole: 'receptionist',
        ),
      );

      bool dutyToggled = false;
      final visits = [
        const IndustrialVisitModel(
          id: 104,
          requestNumber: 'AH-2026-REC-104',
          propertyId: 115,
          visitorName: 'Delivery Driver Farhan',
          status: IndustrialVisitStatus.awaitingHost,
        ),
      ];

      await tester.pumpWidget(
        buildThemedApp(
          ReceptionistDashboardView(
            visits: visits,
            initialIsOnDuty: true,
            onToggleDuty: (val) => dutyToggled = true,
          ),
          isDark: false,
        ),
      );
      await tester.pump();

      expect(find.text('Reception Open'), findsOneWidget);
      expect(find.text('On Duty'), findsOneWidget);

      await tester.tap(find.text('On Duty'));
      await tester.pump();
      expect(dutyToggled, isTrue);
    });

    testWidgets('TC-R2-05: FacilityStaffDashboardView renders building occupancy tracker and operations work queue', (tester) async {
      final visits = [
        const IndustrialVisitModel(
          id: 105,
          requestNumber: 'AH-2026-FAC-105',
          propertyId: 115,
          visitorName: 'HVAC Technician Rakesh',
          status: IndustrialVisitStatus.checkedIn,
        ),
      ];

      await tester.pumpWidget(
        buildThemedApp(
          FacilityStaffDashboardView(visits: visits),
          isDark: false,
        ),
      );
      await tester.pump();

      expect(find.text('Facility & Operations HQ'), findsOneWidget);
      expect(find.text('Building Occupancy Tracker'), findsOneWidget);
      expect(find.text('1 Visitors Currently Checked-In'), findsOneWidget);
      expect(find.text('Operations Work Queue'), findsOneWidget);
    });

    test('TC-R2-06: Admin / Manager in Industrial context resolves to executive dashboard archetype', () {
      final adminUser = UserModel(
        userId: 250,
        fullName: 'Campus General Manager',
        primaryRole: 'Admin',
        accountType: 'app',
        societyId: 115,
        societyName: 'Industrial Park Alpha',
        propertyType: 'industrial',
        roleScope: 'corporate',
        rolePower: 90,
      );

      expect(PropertyRoleResolver.isIndustrialContext(adminUser), isTrue);
      expect(PropertyRoleResolver.canApproveVisits(adminUser), isTrue);
      expect(PropertyRoleResolver.canDelegate(adminUser), isTrue);
      expect(PropertyRoleResolver.canManageMembers(adminUser), isTrue);
      expect(PropertyRoleResolver.canManageNotices(adminUser), isTrue);
    });

    // ══════════════════════════════════════════════════════════════
    // TIER 2: BOUNDARY & CORNER CASES (Empty lists, long text)
    // ══════════════════════════════════════════════════════════════

    testWidgets('TC-R2-07: Dashboards render gracefully when visits list is empty without crashing', (tester) async {
      await tester.pumpWidget(
        buildThemedApp(
          const DirectorDashboardView(visits: []),
        ),
      );
      await tester.pump();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Inside'), findsOneWidget);

      await tester.pumpWidget(
        buildThemedApp(
          EmployeeDashboardView(
            employeeName: 'New Employee',
            departmentName: 'HR',
            cabinNumber: '1',
            deskNumber: '1',
            visits: const [],
            onOpenDelegation: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('New Employee'), findsOneWidget);
    });

    testWidgets('TC-R2-08: Extremely long visitor name and department wrap cleanly without unhandled exception', (tester) async {
      final visits = [
        const IndustrialVisitModel(
          id: 108,
          requestNumber: 'AH-2026-LONG-108',
          propertyId: 115,
          visitorName: 'Dr. Jean-Pierre Alexander Maximillian von Lichtenstein III',
          departmentName: 'Department of Advanced Molecular Logistics',
          status: IndustrialVisitStatus.awaitingHost,
        ),
      ];

      await tester.pumpWidget(
        buildThemedApp(
          DirectorDashboardView(visits: visits),
        ),
      );
      await tester.pump();

      expect(find.text('Dr. Jean-Pierre Alexander Maximillian von Lichtenstein III'), findsOneWidget);
    });

    testWidgets('TC-R2-09: Missing cabin and desk number renders graceful fallback', (tester) async {
      await tester.pumpWidget(
        buildThemedApp(
          EmployeeDashboardView(
            employeeName: 'Staff Without Cabin',
            departmentName: 'General Logistics',
            cabinNumber: '',
            deskNumber: '',
            visits: const [],
            onOpenDelegation: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Staff Without Cabin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-R2-10: Dark mode theme uses accessible dark surfaces and readable color schemes', (tester) async {
      final darkTheme = AsmitaTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AsmitaPalette.systemBGDark);
      expect(darkTheme.colorScheme.surface, AsmitaPalette.surfaceDark);
      expect(darkTheme.colorScheme.primary, AsmitaPalette.deepNavyDark);
      expect(darkTheme.colorScheme.onSecondaryContainer, Colors.white);
    });

    testWidgets('TC-R2-11: Light mode theme uses standard high-contrast palette', (tester) async {
      final lightTheme = AsmitaTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AsmitaPalette.systemBG);
      expect(lightTheme.colorScheme.primary, AsmitaPalette.deepNavy);
      expect(lightTheme.colorScheme.surface, AsmitaPalette.surfaceLight);
      expect(lightTheme.colorScheme.error, AsmitaPalette.actionRed);
    });
  });
}
