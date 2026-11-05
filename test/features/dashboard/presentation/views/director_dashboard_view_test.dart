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
import 'package:asmita_society/core/widgets/asmita_employee_card.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockIndustrialVisitBloc mockVisitBloc;
  late StreamController<IndustrialVisitState> visitStateController;
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;

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

    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(
        sessionRole: 'director',
        user: UserModel(
          userId: 10,
          fullName: 'Executive Director',
          primaryRole: 'director',
          accountType: 'app',
          societyName: 'AsmitA House',
          roleDetails: {
            'department_name': 'Executive Office',
            'cabin_code': 'CAB-DIR-01',
            'desk_code': 'DIR-DSK-01',
            'designation': 'Executive Director',
          },
        ),
      ),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await visitStateController.close();
    await authStateController.close();
  });

  Widget buildTestableWidget({
    List<IndustrialVisitModel>? visits,
    VoidCallback? onContactReceptionist,
    Function(int, String)? onDecideVisit,
    Function(int)? onAcknowledgeVisit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<IndustrialVisitBloc>.value(value: mockVisitBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
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
    testWidgets('renders executive hero card, KPI metrics, quick actions and waiting queue', (tester) async {
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

      // 1. Executive Hero Card (AsmitaEmployeeCard)
      expect(find.byType(AsmitaEmployeeCard), findsOneWidget);
      expect(find.text('Executive Director'), findsWidgets);
      expect(find.text('Executive Office'), findsWidgets);

      // 2. Quick Actions
      expect(find.text('Pre-Approve'), findsOneWidget);
      expect(find.text('Car Valet'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Receptionist'), findsOneWidget);

      // 3. 2x2 Metric Overview
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('On-Site'), findsOneWidget);
      expect(find.text('Expected'), findsOneWidget);
      expect(find.text('Total Visits'), findsOneWidget);
      expect(find.text('3 Total Visits'), findsOneWidget);

      // 4. Waiting Queue Section
      expect(find.text('Who is Waiting'), findsOneWidget);
      expect(find.text('Waiting Since'), findsOneWidget);
      expect(find.text('Rajesh Mehra'), findsOneWidget);
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

    testWidgets('triggers callbacks for approve and reject from visit details modal', (tester) async {
      setMobileScreen(tester);
      int? decidedId;
      String? decidedAction;

      final testVisits = [
        const IndustrialVisitModel(
          id: 42,
          requestNumber: 'AH-DIR-042',
          propertyId: 114,
          visitorName: 'Dr. Vikram Sarabhai',
          status: IndustrialVisitStatus.awaitingHost,
          departmentName: 'Executive Office',
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          visits: testVisits,
          onDecideVisit: (id, action) {
            decidedId = id;
            decidedAction = action;
          },
        ),
      );
      await tester.pump();

      // Tap on the waiting visitor card to open details modal
      await tester.tap(find.text('Dr. Vikram Sarabhai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Approve Priority Entry'), findsOneWidget);
      expect(find.text('Decline Pass'), findsOneWidget);

      // Tap Reject / Decline
      await tester.tap(find.text('Decline Pass'));
      await tester.pump();

      expect(decidedId, equals(42));
      expect(decidedAction, equals('REJECT'));
    });

    testWidgets('shows empty waiting queue card when visits list is empty', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(visits: const []));
      await tester.pump();

      expect(find.text('Who is Waiting'), findsOneWidget);
      expect(find.text("No one's waiting"), findsOneWidget);
      expect(find.text('Queue Clear'), findsOneWidget);
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
