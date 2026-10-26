import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/views/guard_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_pass_check_in_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_delivery_entry_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_vehicle_draft_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/manual_override_dialog.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockGuardGateBloc extends Mock implements GuardGateBloc {}
class MockIndustrialVisitRepository extends Mock implements IndustrialVisitRepository {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockGuardGateBloc mockGateBloc;
  late StreamController<GuardGateState> gateStateController;
  late MockIndustrialVisitRepository mockIndustrialRepository;
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;
  late IndustrialVisitBloc industrialVisitBloc;

  final testGuardUser = UserModel(
    userId: 1,
    fullName: 'Guard Ramesh',
    primaryRole: 'security_guard',
    accountType: 'app',
    societyName: 'AsmitA House',
  );

  setUpAll(() {
    registerFallbackValue(LoadExpectedInvites());
    registerFallbackValue(const SearchInviteByCode('123456'));
    registerFallbackValue(const CheckInPreApprovedVisitor('1'));
  });

  setUp(() {
    mockGateBloc = MockGuardGateBloc();
    gateStateController = StreamController<GuardGateState>.broadcast();
    when(() => mockGateBloc.stream).thenAnswer((_) => gateStateController.stream);
    when(() => mockGateBloc.state).thenReturn(
      const GuardGateState(
        status: GuardGateStatus.loaded,
        expectedInvites: [],
        isLoadingExpected: false,
      ),
    );
    when(() => mockGateBloc.close()).thenAnswer((_) async {});
    when(() => mockGateBloc.add(any())).thenReturn(null);

    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: testGuardUser, sessionRole: 'guard'));
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    mockIndustrialRepository = MockIndustrialVisitRepository();
    industrialVisitBloc = IndustrialVisitBloc(repository: mockIndustrialRepository);
  });

  tearDown(() async {
    await gateStateController.close();
    await authStateController.close();
    industrialVisitBloc.close();
  });

  Widget createWidgetUnderTest({
    VoidCallback? onNavigateToMenu,
    VoidCallback? onNavigateToHistory,
    VoidCallback? onNavigateToScanner,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<GuardGateBloc>.value(value: mockGateBloc),
        BlocProvider<IndustrialVisitBloc>.value(value: industrialVisitBloc),
      ],
      child: MaterialApp(
        home: GuardDashboardView(
          onNavigateToMenu: onNavigateToMenu ?? () {},
          onNavigateToHistory: onNavigateToHistory ?? () {},
          onNavigateToScanner: onNavigateToScanner ?? () {},
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

  group('GuardDashboardView Production Widget Tests', () {
    testWidgets('renders header, gate assignment, search section, and empty expected list', (tester) async {
      setMobileScreen(tester);
      bool historyTapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onNavigateToHistory: () => historyTapped = true,
        ),
      );
      await tester.pump();

      // Check header
      expect(find.text('Security Guard'), findsOneWidget);

      // Tap history
      await tester.tap(find.byIcon(Icons.history));
      expect(historyTapped, isTrue);

      // Gate assignment
      expect(find.text('Gate Assignment'), findsOneWidget);
      expect(find.text('On Duty'), findsOneWidget);
      expect(find.text('Gate 1 (Pedestrian)'), findsOneWidget);
      expect(find.text('Gate 2 (Parking)'), findsOneWidget);

      // Default Gate 1 action buttons
      expect(find.text('Verify Pass'), findsOneWidget);
      expect(find.text('Delivery Intake'), findsOneWidget);
      expect(find.text('Manual Security Override (Cap: 5)'), findsOneWidget);

      // Search section
      expect(find.text('Scan or Enter Pass Code'), findsOneWidget);
      expect(find.text('e.g. 123456'), findsOneWidget);

      // New Walk-in button
      expect(find.text('New Walk-in Visitor'), findsOneWidget);

      // Empty state
      expect(find.text('No expected visitors for today'), findsOneWidget);
    });

    testWidgets('switches between Gate 1 (Pedestrian) and Gate 2 (Parking) with correct actions', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Default Gate 1 actions visible
      expect(find.text('Verify Pass'), findsOneWidget);
      expect(find.text('Generate Vehicle Draft Slip (QR)'), findsNothing);

      // Tap Gate 2 chip
      await tester.tap(find.text('Gate 2 (Parking)'));
      await tester.pump();

      // Gate 2 action is now visible
      expect(find.text('Generate Vehicle Draft Slip (QR)'), findsOneWidget);
      expect(find.text('Verify Pass'), findsNothing);

      // Switch back to Gate 1
      await tester.tap(find.text('Gate 1 (Pedestrian)'));
      await tester.pump();

      expect(find.text('Verify Pass'), findsOneWidget);
      expect(find.text('Generate Vehicle Draft Slip (QR)'), findsNothing);
    });

    testWidgets('navigates to GuardPassCheckInScreen when Verify Pass is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Verify Pass'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GuardPassCheckInScreen), findsOneWidget);
    });

    testWidgets('navigates to GuardDeliveryEntryScreen when Delivery Intake is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Delivery Intake'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GuardDeliveryEntryScreen), findsOneWidget);
    });

    testWidgets('opens ManualOverrideDialog when Manual Security Override is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Manual Security Override (Cap: 5)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ManualOverrideDialog), findsOneWidget);
      expect(find.text('Security Override'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ManualOverrideDialog), findsNothing);
    });

    testWidgets('navigates to GuardVehicleDraftScreen when Gate 2 vehicle slip is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Gate 2 (Parking)'));
      await tester.pump();

      await tester.tap(find.text('Generate Vehicle Draft Slip (QR)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GuardVehicleDraftScreen), findsOneWidget);
    });

    testWidgets('validates pass code length and shows error toast when code < 6 digits', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '123');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.text('Please enter a 6-digit access code'), findsOneWidget);
    });

    testWidgets('triggers onNavigateToScanner when scanner button is tapped', (tester) async {
      setMobileScreen(tester);
      bool scannerTapped = false;
      await tester.pumpWidget(
        createWidgetUnderTest(onNavigateToScanner: () => scannerTapped = true),
      );
      await tester.pump();

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.qr_code_scanner));
      expect(scannerTapped, isTrue);
    });

    testWidgets('dispatches SearchInviteByCode when 6-digit code is submitted', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '654321');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      verify(() => mockGateBloc.add(const SearchInviteByCode('654321'))).called(1);
    });

    testWidgets('shows Check-in Dialog when searchResult is emitted in state', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final searchResultData = {
        'id': 101,
        'visitor_name': 'Ramesh Kumar',
        'invite_type': 'Guest',
        'tower_name': 'Tower A',
        'flat_number': '101',
      };

      when(() => mockGateBloc.state).thenReturn(
        GuardGateState(
          status: GuardGateStatus.success,
          searchResult: searchResultData,
        ),
      );
      gateStateController.add(
        GuardGateState(
          status: GuardGateStatus.success,
          searchResult: searchResultData,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Verify Visitor'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Tower A - 101'), findsOneWidget);
      expect(find.text('Confirm Check-in'), findsOneWidget);

      await tester.tap(find.text('Confirm Check-in'));
      await tester.pump();

      verify(() => mockGateBloc.add(const CheckInPreApprovedVisitor('101', isPreApproved: true))).called(1);
    });

    testWidgets('renders expected visitors and confirms check-in through dialog', (tester) async {
      setMobileScreen(tester);
      final testInvite = {
        'id': 55,
        'visitor_name': 'Devendra Singh',
        'invite_type': 'Vendor',
        'tower_name': 'Unit',
        'flat_number': '402',
        'valid_from': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'valid_to': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'status': 'APPROVED',
      };

      when(() => mockGateBloc.state).thenReturn(
        GuardGateState(
          status: GuardGateStatus.loaded,
          expectedInvites: [testInvite],
          isLoadingExpected: false,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Devendra Singh'), findsOneWidget);
      expect(find.text('VENDOR'), findsOneWidget);

      // Tap check in icon
      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog opens
      expect(find.text('Verify Visitor'), findsOneWidget);
      expect(find.text('Confirm Check-in'), findsOneWidget);

      // Confirm check in
      await tester.tap(find.text('Confirm Check-in'));
      await tester.pump();

      verify(() => mockGateBloc.add(const CheckInPreApprovedVisitor('55', isPreApproved: true))).called(1);
    });

    testWidgets('shows loading indicator when isLoadingExpected is true and list empty', (tester) async {
      setMobileScreen(tester);
      when(() => mockGateBloc.state).thenReturn(
        const GuardGateState(
          status: GuardGateStatus.loading,
          expectedInvites: [],
          isLoadingExpected: true,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsWidgets);
    });

    testWidgets('shows error toast when state has errorMessage', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      when(() => mockGateBloc.state).thenReturn(
        const GuardGateState(
          status: GuardGateStatus.error,
          errorMessage: 'Access Code Expired',
        ),
      );
      gateStateController.add(
        const GuardGateState(
          status: GuardGateStatus.error,
          errorMessage: 'Access Code Expired',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Access Code Expired'), findsOneWidget);
    });

    testWidgets('shows success toast when state has successMessage', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      when(() => mockGateBloc.state).thenReturn(
        const GuardGateState(
          status: GuardGateStatus.success,
          successMessage: 'Visitor Approved',
        ),
      );
      gateStateController.add(
        const GuardGateState(
          status: GuardGateStatus.success,
          successMessage: 'Visitor Approved',
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Visitor Approved'), findsOneWidget);
    });
  });
}
