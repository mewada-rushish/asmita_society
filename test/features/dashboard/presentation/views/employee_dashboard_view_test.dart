import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/views/employee_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/delivery_action_sheet.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/app_skeleton.dart';

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
    registerFallbackValue(const AuthRefreshProfileRequested());
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
        sessionRole: 'employee',
        user: UserModel(
          userId: 10,
          fullName: 'Rushish Mewada',
          primaryRole: 'employee',
          accountType: 'app',
        ),
      ),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await visitStateController.close();
    await authStateController.close();
  });

  Widget buildTestableWidget({
    String employeeName = 'Aditi Sharma',
    String departmentName = 'Accounts',
    String cabinNumber = '104',
    String deskNumber = '2',
    List<IndustrialVisitModel>? visits,
    VoidCallback? onOpenDelegation,
    Function(int, String)? onDecideVisit,
    Function(int)? onAcknowledgeVisit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<IndustrialVisitBloc>.value(value: mockVisitBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: EmployeeDashboardView(
            employeeName: employeeName,
            departmentName: departmentName,
            cabinNumber: cabinNumber,
            deskNumber: deskNumber,
            visits: visits,
            onOpenDelegation: onOpenDelegation ?? () {},
            onDecideVisit: onDecideVisit,
            onAcknowledgeVisit: onAcknowledgeVisit,
          ),
        ),
      ),
    );
  }

  group('EmployeeDashboardView Production Widget Tests', () {
    testWidgets('renders profile card, location badges, and delegation button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          employeeName: 'Rahul Verma',
          departmentName: 'Engineering',
          cabinNumber: '201',
          deskNumber: '5',
          visits: const [],
        ),
      );
      await tester.pump();

      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('201'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      expect(find.text('All Caught Up!'), findsOneWidget);
      expect(find.text('Pre-Approve'), findsOneWidget);
    });

    testWidgets('renders pending visitor cards and triggers action callbacks', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? decidedId;
      String? decidedAction;
      int? acknowledgedId;

      final testVisits = [
        IndustrialVisitModel(
          id: 42,
          requestNumber: 'AH-REQ-42',
          propertyId: 114,
          visitorName: 'Sanjay Gupta',
          status: IndustrialVisitStatus.awaitingHost,
          purpose: 'Vendor Discussion',
          createdAt: DateTime.now(),
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
            acknowledgedId = id;
          },
        ),
      );
      await tester.pump();

      expect(find.text('Sanjay Gupta'), findsOneWidget);
      expect(find.text('AH-REQ-42'), findsOneWidget);
      expect(find.text('Ack'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);

      // Tap Ack
      await tester.tap(find.text('Ack'));
      expect(acknowledgedId, equals(42));

      // Tap Approve
      await tester.tap(find.text('Approve'));
      expect(decidedId, equals(42));
      expect(decidedAction, equals('APPROVE'));

      // Tap Deny
      await tester.tap(find.text('Deny'));
      expect(decidedAction, equals('REJECT'));
    });

    testWidgets('renders delivery package and opens DeliveryActionSheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int? decidedId;
      String? decidedAction;

      final testDelivery = [
        IndustrialVisitModel(
          id: 99,
          requestNumber: 'DEL-99',
          propertyId: 114,
          visitorName: 'Amazon Agent',
          status: IndustrialVisitStatus.awaitingHost,
          isDelivery: true,
          deliveryCompany: 'BlueDart',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          visits: testDelivery,
          onDecideVisit: (id, action) {
            decidedId = id;
            decidedAction = action;
          },
        ),
      );
      await tester.pump();

      expect(find.text('BlueDart Delivery'), findsOneWidget);
      expect(find.text('Delivery Options'), findsOneWidget);

      // Open delivery action sheet
      await tester.tap(find.text('Delivery Options'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DeliveryActionSheet), findsOneWidget);
      expect(find.text('Collect at Gate (Recommended)'), findsOneWidget);

      // Tap Collect at Gate
      await tester.tap(find.text('Collect at Gate (Recommended)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(decidedId, equals(99));
      expect(decidedAction, equals('COLLECT_AT_GATE'));
    });

    testWidgets('dispatches bloc events directly when callbacks are not supplied', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testVisits = [
        IndustrialVisitModel(
          id: 77,
          requestNumber: 'AH-REQ-77',
          propertyId: 114,
          visitorName: 'Priya Sen',
          status: IndustrialVisitStatus.awaitingHost,
          createdAt: DateTime.now(),
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

      expect(find.text('Priya Sen'), findsOneWidget);

      // Tap Approve - should dispatch DecideVisitEvent to bloc
      await tester.tap(find.text('Approve'));
      await tester.pump();

      verify(() => mockVisitBloc.add(const DecideVisitEvent(visitId: 77, action: 'APPROVE'))).called(1);

      // Tap Ack - should dispatch AcknowledgeVisitEvent to bloc
      await tester.tap(find.text('Ack'));
      await tester.pump();

      verify(() => mockVisitBloc.add(const AcknowledgeVisitEvent(77))).called(1);
    });

    testWidgets('shows skeleton during initial empty load', (tester) async {
      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.loading,
          visits: [],
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AsmitaSkeleton), findsWidgets);
    });

    testWidgets('shows success and error toasts on state changes', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          successMessage: 'Visit approved successfully',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          successMessage: 'Visit approved successfully',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Visit approved successfully'), findsOneWidget);

      when(() => mockVisitBloc.state).thenReturn(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'Failed to acknowledge visit',
        ),
      );
      visitStateController.add(
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.error,
          errorMessage: 'Failed to acknowledge visit',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Failed to acknowledge visit'), findsOneWidget);
    });
  });
}
