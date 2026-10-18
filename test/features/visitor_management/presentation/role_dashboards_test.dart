import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/views/director_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/employee_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/receptionist_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/facility_staff_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_pass_check_in_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_vehicle_draft_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_delivery_entry_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/department_delegation_screen.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';

class MockIndustrialVisitRepository extends Mock implements IndustrialVisitRepository {}

void main() {
  late MockIndustrialVisitRepository mockRepository;
  late IndustrialVisitBloc bloc;

  setUp(() {
    mockRepository = MockIndustrialVisitRepository();
    bloc = IndustrialVisitBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('Phase 8: Role Dashboards & Specialized Screens Widget Tests', () {
    testWidgets('DirectorDashboardView renders executive KPIs and quick receptionist action', (tester) async {
      bool contacted = false;
      final testVisits = [
        const IndustrialVisitModel(
          id: 1,
          requestNumber: 'AH-2026-DIR-1',
          propertyId: 114,
          visitorName: 'VIP Client Rajesh',
          status: IndustrialVisitStatus.awaitingHost,
          departmentName: 'Executive Office',
          purpose: 'Quarterly Board Review',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: DirectorDashboardView(
            visits: testVisits,
            onContactReceptionist: () => contacted = true,
          ),
        ),
      );

      expect(find.text('Executive Office'), findsOneWidget);
      expect(find.text('VIP Client Rajesh'), findsOneWidget);
      expect(find.text('Receptionist'), findsOneWidget);

      await tester.tap(find.text('Receptionist'));
      expect(contacted, isTrue);
    });

    testWidgets('EmployeeDashboardView renders cabin/desk badges and pending approvals feed', (tester) async {
      bool openedDelegation = false;
      final testVisits = [
        const IndustrialVisitModel(
          id: 2,
          requestNumber: 'AH-2026-EMP-1',
          propertyId: 114,
          visitorName: 'Vendor Sunil',
          status: IndustrialVisitStatus.awaitingHost,
          purpose: 'Invoicing & Bills',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: EmployeeDashboardView(
            employeeName: 'Aditi Sharma',
            departmentName: 'Accounts',
            cabinNumber: '104',
            deskNumber: '2',
            visits: testVisits,
            onOpenDelegation: () => openedDelegation = true,
          ),
        ),
      );

      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('Accounts Department'), findsOneWidget);
      expect(find.text('Cabin 104'), findsOneWidget);
      expect(find.text('Desk 2'), findsOneWidget);
      expect(find.text('Vendor Sunil'), findsOneWidget);

      await tester.tap(find.text('Delegation'));
      expect(openedDelegation, isTrue);
    });

    testWidgets('ReceptionistDashboardView renders dual tabs and on-duty toggle switch', (tester) async {
      bool dutyToggled = false;
      final testVisits = [
        const IndustrialVisitModel(
          id: 3,
          requestNumber: 'AH-2026-REC-1',
          propertyId: 114,
          visitorName: 'Walk-in Guest Amit',
          status: IndustrialVisitStatus.awaitingHost,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ReceptionistDashboardView(
            visits: testVisits,
            initialIsOnDuty: true,
            onToggleDuty: (val) => dutyToggled = true,
          ),
        ),
      );

      expect(find.text('Reception Desk Operations'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Waiting List (1)'), findsOneWidget);
      expect(find.text('Floor Alerts (1)'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(dutyToggled, isTrue);
    });

    testWidgets('FacilityStaffDashboardView renders operations work queue and building occupancy', (tester) async {
      final testVisits = [
        const IndustrialVisitModel(
          id: 4,
          requestNumber: 'AH-2026-FAC-1',
          propertyId: 114,
          visitorName: 'Contractor Farhan',
          status: IndustrialVisitStatus.checkedIn,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: FacilityStaffDashboardView(visits: testVisits),
        ),
      );

      expect(find.text('Facility & Operations HQ'), findsOneWidget);
      expect(find.text('Building Occupancy Tracker'), findsOneWidget);
      expect(find.text('1 Visitors Currently Checked-In'), findsOneWidget);
      expect(find.text('Operations Work Queue'), findsOneWidget);
    });

    testWidgets('GuardPassCheckInScreen renders pass verification input and gate terminal banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const GuardPassCheckInScreen(gateId: 1),
          ),
        ),
      );

      expect(find.text('Gate 1 Pedestrian Pass Verification'), findsOneWidget);
      expect(find.text('Active Terminal: Gate 1 (Pedestrians & Walk-ins Only)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
    });

    testWidgets('GuardVehicleDraftScreen renders vehicle plate field and QR generator button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const GuardVehicleDraftScreen(gateId: 2),
          ),
        ),
      );

      expect(find.text('Gate 2 Vehicle Slip Generator'), findsOneWidget);
      expect(find.text('Vehicle Registration Plate'), findsOneWidget);
      expect(find.text('Visitor / Driver Full Name'), findsOneWidget);
      expect(find.text('Generate Vehicle Draft Slip'), findsOneWidget);
    });

    testWidgets('GuardDeliveryEntryScreen renders courier dropdown and recipient input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const GuardDeliveryEntryScreen(gateId: 1),
          ),
        ),
      );

      expect(find.text('Guard Delivery Intake'), findsOneWidget);
      expect(find.text('Amazon'), findsOneWidget);
      expect(find.text('Recipient Full Name'), findsOneWidget);
      expect(find.text('Log Delivery & Alert Recipient'), findsOneWidget);
    });

    testWidgets('DepartmentDelegationScreen renders delegation options and save button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DepartmentDelegationScreen(
            departmentId: 1,
            departmentName: 'Accounts',
          ),
        ),
      );

      expect(find.text('Accounts Delegation'), findsOneWidget);
      expect(find.text('Select Delegate Staff Member:'), findsOneWidget);
      expect(find.text('Active Delegation Window:'), findsOneWidget);
      expect(find.text('Save & Activate Delegation'), findsOneWidget);
    });
  });
}
