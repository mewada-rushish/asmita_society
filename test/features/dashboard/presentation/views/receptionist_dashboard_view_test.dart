import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/views/receptionist_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/receptionist_reassign_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}

void main() {
  late MockIndustrialVisitBloc mockVisitBloc;
  late StreamController<IndustrialVisitState> visitStateController;

  setUpAll(() {
    registerFallbackValue(const LoadIndustrialVisits());
    registerFallbackValue(const DecideVisitEvent(visitId: 1, action: 'APPROVE'));
    registerFallbackValue(const ClockInDutyEvent(1));
    registerFallbackValue(const ClockOutDutyEvent());
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
    bool initialIsOnDuty = true,
    ValueChanged<bool>? onToggleDuty,
    Function(int, String)? onDecideVisit,
    Function(int, int?, int?, int?)? onReassignVisit,
  }) {
    return BlocProvider<IndustrialVisitBloc>.value(
      value: mockVisitBloc,
      child: MaterialApp(
        home: ReceptionistDashboardView(
          visits: visits,
          initialIsOnDuty: initialIsOnDuty,
          onToggleDuty: onToggleDuty,
          onDecideVisit: onDecideVisit,
          onReassignVisit: onReassignVisit,
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

  group('ReceptionistDashboardView Production Widget Tests', () {
    testWidgets('renders title, duty switch, dual tabs, and switches between tabs', (tester) async {
      setMobileScreen(tester);
      final testVisits = [
        const IndustrialVisitModel(
          id: 1,
          requestNumber: 'AH-WAIT-1',
          propertyId: 114,
          visitorName: 'Walk-in Guest Amit',
          status: IndustrialVisitStatus.awaitingHost,
        ),
        const IndustrialVisitModel(
          id: 2,
          requestNumber: 'AH-EXEC-2',
          propertyId: 114,
          visitorName: 'Director Guest Rajiv',
          departmentName: 'Executive Office',
          status: IndustrialVisitStatus.approved,
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(visits: testVisits));
      await tester.pump();

      expect(find.text('Reception Desk Operations'), findsOneWidget);
      expect(find.text('Ground & Floor Visitor Coordination'), findsOneWidget);
      expect(find.text('On Duty'), findsOneWidget);

      // Verify tabs
      expect(find.text('Waiting List (1)'), findsOneWidget);
      expect(find.text('Floor Alerts (2)'), findsOneWidget);

      // In Tab 0: Waiting List shows Walk-in Guest Amit
      expect(find.text('Walk-in Guest Amit'), findsOneWidget);
      expect(find.text('Director Guest Rajiv'), findsNothing);

      // Tap Tab 1: Floor Alerts
      await tester.tap(find.text('Floor Alerts (2)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In Tab 1: Floor Alerts shows Director Guest Rajiv
      expect(find.text('Director Guest Rajiv'), findsOneWidget);
    });

    testWidgets('toggles on duty switch and updates status label and callback', (tester) async {
      setMobileScreen(tester);
      bool? dutyValue;

      await tester.pumpWidget(
        buildTestableWidget(
          visits: const [],
          initialIsOnDuty: true,
          onToggleDuty: (val) => dutyValue = val,
        ),
      );
      await tester.pump();

      expect(find.text('On Duty'), findsOneWidget);

      // Toggle switch to off
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('Away'), findsOneWidget);
      expect(dutyValue, isFalse);

      // Toggle switch back on
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('On Duty'), findsOneWidget);
      expect(dutyValue, isTrue);
    });

    testWidgets('triggers approve decision and opens reassign sheet with reallocation', (tester) async {
      setMobileScreen(tester);
      int? decidedVisitId;
      String? decidedAction;

      int? reassignVisitId;
      int? reassignUserId;
      int? reassignCabinId;
      int? reassignDeskId;

      final testVisits = [
        const IndustrialVisitModel(
          id: 10,
          requestNumber: 'AH-VISIT-10',
          propertyId: 114,
          visitorName: 'Tarun Mehra',
          status: IndustrialVisitStatus.awaitingHost,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          visits: testVisits,
          onDecideVisit: (id, action) {
            decidedVisitId = id;
            decidedAction = action;
          },
          onReassignVisit: (id, userId, cabin, desk) {
            reassignVisitId = id;
            reassignUserId = userId;
            reassignCabinId = cabin;
            reassignDeskId = desk;
          },
        ),
      );
      await tester.pump();

      // Tap Approve
      await tester.tap(find.text('Approve'));
      await tester.pump();

      expect(decidedVisitId, equals(10));
      expect(decidedAction, equals('APPROVE'));

      // Tap Reassign / Allocate
      await tester.tap(find.text('Reassign / Allocate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ReceptionistReassignSheet), findsOneWidget);
      expect(find.text('Receptionist Allocation'), findsOneWidget);

      // Enter Cabin & Desk
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '104');
      await tester.enterText(textFields.at(1), '3');
      await tester.pump();

      // Tap Confirm Allocation
      await tester.tap(find.text('Confirm Allocation & Notify'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ReceptionistReassignSheet), findsNothing);
      expect(reassignVisitId, equals(10));
      expect(reassignUserId, isNull);
      expect(reassignCabinId, equals(104));
      expect(reassignDeskId, equals(3));
    });

    testWidgets('shows empty states for both tabs when visits list is empty', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(visits: const []));
      await tester.pump();

      // Tab 0 empty state
      expect(find.text('No visitors currently waiting in lobby.'), findsOneWidget);

      // Switch to Tab 1
      await tester.tap(find.text('Floor Alerts (0)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tab 1 empty state
      expect(find.text('No escalated floor alerts at this time.'), findsOneWidget);
    });

    testWidgets('dispatches bloc events directly when live and callbacks are omitted', (tester) async {
      setMobileScreen(tester);
      final testVisits = [
        const IndustrialVisitModel(
          id: 88,
          requestNumber: 'AH-REQ-88',
          propertyId: 114,
          visitorName: 'Deepak Joshi',
          status: IndustrialVisitStatus.awaitingHost,
        ),
      ];

      when(() => mockVisitBloc.state).thenReturn(
        IndustrialVisitState(
          status: IndustrialVisitBlocStatus.loaded,
          visits: testVisits,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Tap Approve
      await tester.tap(find.text('Approve'));
      await tester.pump();

      verify(() => mockVisitBloc.add(const DecideVisitEvent(visitId: 88, action: 'APPROVE'))).called(1);

      // Toggle Duty
      await tester.tap(find.byType(Switch));
      await tester.pump();

      verify(() => mockVisitBloc.add(const ClockOutDutyEvent())).called(1);
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
          successMessage: 'Visitor Allocated to Cabin 104',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          successMessage: 'Visitor Allocated to Cabin 104',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Visitor Allocated to Cabin 104'), findsOneWidget);

      // Error toast
      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'Reallocation failed',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'Reallocation failed',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Reallocation failed'), findsOneWidget);
    });
  });
}
