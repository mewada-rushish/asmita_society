import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/views/director_dashboard_view.dart';
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
    registerFallbackValue(const DecideVisitEvent(visitId: 1, action: 'APPROVE'));
    registerFallbackValue(const AcknowledgeVisitEvent(1));
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
    VoidCallback? onContactReceptionist,
    Function(int, String)? onDecideVisit,
    Function(int)? onAcknowledgeVisit,
  }) {
    return BlocProvider<IndustrialVisitBloc>.value(
      value: mockVisitBloc,
      child: MaterialApp(
        home: DirectorDashboardView(
          visits: visits,
          onContactReceptionist: onContactReceptionist,
          onDecideVisit: onDecideVisit,
          onAcknowledgeVisit: onAcknowledgeVisit,
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

  group('DirectorDashboardView Production Widget Tests', () {
    testWidgets('renders executive title, KPI metrics, and VIP visits feed', (tester) async {
      setMobileScreen(tester);
      final testVisits = [
        const IndustrialVisitModel(
          id: 1,
          requestNumber: 'AH-DIR-101',
          propertyId: 114,
          visitorName: 'Rajesh Mehra',
          status: IndustrialVisitStatus.awaitingHost,
          departmentName: 'Executive Office',
          purpose: 'Quarterly Audit Review',
        ),
        const IndustrialVisitModel(
          id: 2,
          requestNumber: 'AH-DIR-102',
          propertyId: 114,
          visitorName: 'Sanjay Singhania',
          status: IndustrialVisitStatus.approved,
          departmentName: 'Board of Directors',
        ),
        const IndustrialVisitModel(
          id: 3,
          requestNumber: 'AH-DIR-103',
          propertyId: 114,
          visitorName: 'Ananya Birla',
          status: IndustrialVisitStatus.checkedIn,
          departmentName: 'VIP Lounge',
        ),
      ];

      await tester.pumpWidget(buildTestableWidget(visits: testVisits));
      await tester.pump();

      expect(find.text('Executive Office'), findsAtLeastNWidgets(1));
      expect(find.text('Director Operations & VIP Gateways'), findsOneWidget);
      expect(find.text('Receptionist'), findsOneWidget);

      // KPI Counts
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Approved'), findsNWidgets(2)); // KPI label + Status badge
      expect(find.text('Inside HQ'), findsOneWidget);
      expect(find.text('3 Total Visits'), findsOneWidget);

      // Visitors
      expect(find.text('Rajesh Mehra'), findsOneWidget);
      expect(find.text('Purpose: Quarterly Audit Review'), findsOneWidget);
      expect(find.text('Sanjay Singhania'), findsOneWidget);
      expect(find.text('Ananya Birla'), findsOneWidget);
    });

    testWidgets('calls onContactReceptionist when provided', (tester) async {
      setMobileScreen(tester);
      bool contacted = false;
      await tester.pumpWidget(
        buildTestableWidget(
          visits: const [],
          onContactReceptionist: () => contacted = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Receptionist'));
      expect(contacted, isTrue);
    });

    testWidgets('opens Floor Support Hotline sheet when onContactReceptionist is omitted', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(visits: const []));
      await tester.pump();

      // Tap Receptionist button
      await tester.tap(find.text('Receptionist'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Floor Support Hotline'), findsOneWidget);
      expect(find.text('Main Reception Desk'), findsOneWidget);
      expect(find.text('Gate 1 Security Control'), findsOneWidget);

      // Tap Call
      await tester.tap(find.text('Call').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Floor Support Hotline'), findsNothing);
      expect(find.text('Calling Main Reception (Ext 101)...'), findsOneWidget);
    });

    testWidgets('triggers callbacks for approve, reject, and acknowledge actions', (tester) async {
      setMobileScreen(tester);
      int? decidedId;
      String? decidedAction;
      int? ackedId;

      final testVisits = [
        const IndustrialVisitModel(
          id: 42,
          requestNumber: 'AH-DIR-042',
          propertyId: 114,
          visitorName: 'Dr. Vikram Sarabhai',
          status: IndustrialVisitStatus.awaitingHost,
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          visits: testVisits,
          onDecideVisit: (id, action) {
            decidedId = id;
            decidedAction = action;
          },
          onAcknowledgeVisit: (id) {
            ackedId = id;
          },
        ),
      );
      await tester.pump();

      // Tap Acknowledge
      await tester.tap(find.text('Acknowledge'));
      await tester.pump();

      expect(ackedId, equals(42));
      expect(find.text('Acknowledged'), findsOneWidget);

      // Tap Reject
      await tester.tap(find.text('Reject'));
      await tester.pump();

      expect(decidedId, equals(42));
      expect(decidedAction, equals('REJECT'));

      // Tap Approve
      await tester.tap(find.text('Approve'));
      await tester.pump();

      expect(decidedId, equals(42));
      expect(decidedAction, equals('APPROVE'));
    });

    testWidgets('dispatches bloc events directly when live and callbacks are omitted', (tester) async {
      setMobileScreen(tester);
      final testVisits = [
        const IndustrialVisitModel(
          id: 55,
          requestNumber: 'AH-DIR-055',
          propertyId: 114,
          visitorName: 'Ratan Tata',
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

      verify(() => mockVisitBloc.add(const DecideVisitEvent(visitId: 55, action: 'APPROVE'))).called(1);

      // Tap Reject
      await tester.tap(find.text('Reject'));
      await tester.pump();

      verify(() => mockVisitBloc.add(const DecideVisitEvent(visitId: 55, action: 'REJECT'))).called(1);

      // Tap Acknowledge
      await tester.tap(find.text('Acknowledge'));
      await tester.pump();

      verify(() => mockVisitBloc.add(const AcknowledgeVisitEvent(55))).called(1);
    });

    testWidgets('shows empty state when visits list is empty', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(visits: const []));
      await tester.pump();

      expect(find.text('No pending executive visitor appointments.'), findsOneWidget);
      expect(find.byIcon(Icons.person_pin_outlined), findsOneWidget);
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
          successMessage: 'VIP Pass Approved by Director',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          successMessage: 'VIP Pass Approved by Director',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('VIP Pass Approved by Director'), findsOneWidget);

      // Error toast
      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'VIP Approval Gateway Timeout',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'VIP Approval Gateway Timeout',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('VIP Approval Gateway Timeout'), findsOneWidget);
    });
  });
}
