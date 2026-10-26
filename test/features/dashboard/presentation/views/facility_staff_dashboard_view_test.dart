import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/views/facility_staff_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}

void main() {
  late MockIndustrialVisitBloc mockVisitBloc;
  late StreamController<IndustrialVisitState> visitStateController;

  setUpAll(() {
    registerFallbackValue(const LoadIndustrialVisits());
  });

  setUp(() {
    mockVisitBloc = MockIndustrialVisitBloc();
    visitStateController = StreamController<IndustrialVisitState>.broadcast();
    when(() => mockVisitBloc.stream).thenAnswer((_) => visitStateController.stream);
    when(() => mockVisitBloc.state).thenReturn(const IndustrialVisitState());
    when(() => mockVisitBloc.close()).thenAnswer((_) async {});
    when(() => mockVisitBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await visitStateController.close();
  });

  Widget buildTestableWidget({
    List<IndustrialVisitModel>? visits,
    VoidCallback? onRefresh,
    ValueChanged<FacilityTaskItem>? onTaskToggled,
  }) {
    return BlocProvider<IndustrialVisitBloc>.value(
      value: mockVisitBloc,
      child: MaterialApp(
        home: FacilityStaffDashboardView(
          visits: visits,
          onRefresh: onRefresh,
          onTaskToggled: onTaskToggled,
        ),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('FacilityStaffDashboardView Production Widget Tests', () {
    testWidgets('renders header, Building Occupancy Tracker, and Operations Work Queue', (tester) async {
      setMobileScreen(tester);
      final testVisits = [
        const IndustrialVisitModel(
          id: 1,
          requestNumber: 'AH-FAC-01',
          propertyId: 114,
          visitorName: 'Contractor Farhan',
          status: IndustrialVisitStatus.checkedIn,
          cabinNumber: '104',
          arrivalMode: 'FOUR_WHEELER',
        ),
        const IndustrialVisitModel(
          id: 2,
          requestNumber: 'AH-FAC-02',
          propertyId: 114,
          visitorName: 'Technician Ravi',
          status: IndustrialVisitStatus.checkedIn,
          departmentName: 'HVAC Plant',
          arrivalMode: 'PEDESTRIAN',
        ),
        const IndustrialVisitModel(
          id: 3,
          requestNumber: 'AH-FAC-03',
          propertyId: 114,
          visitorName: 'Guest Amit',
          status: IndustrialVisitStatus.approved,
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(visits: testVisits));
      await tester.pump();

      expect(find.text('Facility & Operations HQ'), findsOneWidget);
      expect(find.text('Building Occupancy Tracker'), findsOneWidget);
      expect(find.text('2 Visitors Currently Checked-In'), findsOneWidget);
      expect(find.text('Operations Work Queue'), findsOneWidget);

      // Tasks
      expect(find.text('HVAC Airflow Check - Floor 2 Executive Cabins'), findsOneWidget);
      expect(find.text('Lobby Visitor Badge Dispenser Maintenance'), findsOneWidget);
      expect(find.text('3 Pending'), findsOneWidget);
    });

    testWidgets('expands and collapses checked-in visitors roster when occupancy banner tapped', (tester) async {
      setMobileScreen(tester);
      final testVisits = [
        const IndustrialVisitModel(
          id: 10,
          requestNumber: 'AH-FAC-10',
          propertyId: 114,
          visitorName: 'Inspector Sharma',
          status: IndustrialVisitStatus.checkedIn,
          cabinNumber: '202',
          arrivalMode: 'PEDESTRIAN',
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(visits: testVisits));
      await tester.pump();

      // Initially roster is hidden
      expect(find.text('On-Premises Visitor Roster'), findsNothing);

      // Tap banner to expand
      await tester.tap(find.text('Building Occupancy Tracker'));
      await tester.pump();

      expect(find.text('On-Premises Visitor Roster'), findsOneWidget);
      expect(find.text('Inspector Sharma'), findsOneWidget);
      expect(find.text('Cabin 202 • PEDESTRIAN'), findsOneWidget);
      expect(find.text('Inside'), findsOneWidget);

      // Tap banner again to collapse
      await tester.tap(find.text('Building Occupancy Tracker'));
      await tester.pump();

      expect(find.text('On-Premises Visitor Roster'), findsNothing);
    });

    testWidgets('toggles task completion and invokes callback', (tester) async {
      setMobileScreen(tester);
      FacilityTaskItem? toggledTask;

      await tester.pumpWidget(
        buildTestableWidget(
          visits: const [],
          onTaskToggled: (task) => toggledTask = task,
        ),
      );
      await tester.pump();

      expect(find.text('3 Pending'), findsOneWidget);

      // Tap incomplete task
      await tester.tap(find.text('HVAC Airflow Check - Floor 2 Executive Cabins'));
      await tester.pump();

      expect(toggledTask, isNotNull);
      expect(toggledTask!.id, equals('TASK-1'));
      expect(toggledTask!.isCompleted, isTrue);
      expect(find.text('2 Pending'), findsOneWidget);
    });

    testWidgets('adds new work order via dialog', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(visits: const []));
      await tester.pump();

      // Tap New Task FAB
      await tester.tap(find.text('New Task'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Facility Work Order'), findsOneWidget);

      // Enter task description
      await tester.enterText(find.byType(TextField), 'Generator Oil Replacement');
      await tester.pump();

      // Tap Add Task
      await tester.tap(find.text('Add Task'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('New Facility Work Order'), findsNothing);
      expect(find.text('Generator Oil Replacement'), findsOneWidget);
      expect(find.text('Work order added to queue'), findsOneWidget);
    });

    testWidgets('calls onRefresh when app bar refresh button is tapped', (tester) async {
      setMobileScreen(tester);
      bool refreshed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          visits: const [],
          onRefresh: () => refreshed = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(refreshed, isTrue);
    });

    testWidgets('shows loading indicator and toasts on state changes', (tester) async {
      setMobileScreen(tester);
      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.loading,
          visits: [],
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);

      // Success toast
      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          successMessage: 'Work Order Dispatched to Technicians',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          successMessage: 'Work Order Dispatched to Technicians',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Work Order Dispatched to Technicians'), findsOneWidget);

      // Error toast
      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'HVAC telemetry sensor offline',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'HVAC telemetry sensor offline',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('HVAC telemetry sensor offline'), findsOneWidget);
    });
  });
}
