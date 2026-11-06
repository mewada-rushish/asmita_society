import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';
import 'package:asmita_society/features/dashboard/presentation/views/guard_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/facility_staff_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/incoming_visitor_approval_dialog.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockGuardGateBloc extends Mock implements GuardGateBloc {}
class MockIndustrialVisitRepository extends Mock implements IndustrialVisitRepository {}
class FakeGuardGateEvent extends Fake implements GuardGateEvent {}
class FakeIndustrialVisitEvent extends Fake implements IndustrialVisitEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockGuardGateBloc mockGateBloc;
  late MockIndustrialVisitRepository mockIndustrialRepository;
  late IndustrialVisitBloc industrialVisitBloc;
  late StreamController<GuardGateState> gateStateController;
  late StreamController<AuthState> authStateController;

  final testGuardUser = UserModel(
    userId: 10,
    fullName: 'Ramesh Guard',
    primaryRole: 'guard',
    accountType: 'app',
    societyName: 'AsmitA Industrial Campus',
  );

  setUpAll(() {
    registerFallbackValue(FakeGuardGateEvent());
    registerFallbackValue(FakeIndustrialVisitEvent());
  });

  setUp(() {
    mockGateBloc = MockGuardGateBloc();
    gateStateController = StreamController<GuardGateState>.broadcast();
    when(() => mockGateBloc.stream).thenAnswer((_) => gateStateController.stream);
    when(() => mockGateBloc.state).thenReturn(const GuardGateState());
    when(() => mockGateBloc.add(any())).thenReturn(null);
    when(() => mockGateBloc.close()).thenAnswer((_) async {});

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

  testWidgets('GuardDashboardView in Dark Theme: unselected gate chip uses dynamic onSurfaceVariant, not AsmitaPalette.textDark', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<GuardGateBloc>.value(value: mockGateBloc),
          BlocProvider<IndustrialVisitBloc>.value(value: industrialVisitBloc),
        ],
        child: MaterialApp(
          theme: AsmitaTheme.lightTheme,
          darkTheme: AsmitaTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: GuardDashboardView(
            onNavigateToMenu: () {},
            onNavigateToHistory: () {},
            onNavigateToScanner: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    // In Dark Theme, Gate 1 is selected (_selectedGateId == 1) and Gate 2 is unselected
    // Find Gate 2 (Parking) choice chip
    final gate2Finder = find.widgetWithText(ChoiceChip, 'Gate 2 (Parking)');
    expect(gate2Finder, findsOneWidget);

    final chipWidget = tester.widget<ChoiceChip>(gate2Finder);
    expect(chipWidget.selected, isFalse);

    // Verify labelStyle color is dynamic onSurfaceVariant, NOT AsmitaPalette.textDark
    final labelColor = chipWidget.labelStyle?.color;
    expect(labelColor, isNotNull);
    expect(labelColor, isNot(equals(AsmitaPalette.textDark)),
        reason: 'Unselected chip must NOT use hardcoded AsmitaPalette.textDark in dark mode');
    expect(labelColor, equals(AsmitaTheme.darkTheme.colorScheme.onSurfaceVariant),
        reason: 'Unselected chip must adapt to Theme onSurfaceVariant in dark mode');

    // Verify avatar icon color is dynamic onSurfaceVariant
    final iconWidget = chipWidget.avatar as Icon;
    expect(iconWidget.color, equals(AsmitaTheme.darkTheme.colorScheme.onSurfaceVariant),
        reason: 'Avatar icon must adapt to Theme onSurfaceVariant in dark mode');
  });

  testWidgets('IncomingVisitorApprovalDialog in Dark Theme: surface container and adaptive onSurface text colors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AsmitaTheme.lightTheme,
        darkTheme: AsmitaTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: IncomingVisitorApprovalDialog(
            visitId: 101,
            visitorName: 'Rajesh Sharma',
            purpose: 'Quarterly Vendor Inspection',
            department: 'Procurement',
            gateId: '1',
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify visitor name text widget uses onSurface color
    final nameTextFinder = find.text('Rajesh Sharma');
    expect(nameTextFinder, findsOneWidget);
    final nameText = tester.widget<Text>(nameTextFinder);
    expect(nameText.style?.color, equals(AsmitaTheme.darkTheme.colorScheme.onSurface),
        reason: 'Visitor name must adapt to onSurface in dark mode');
    expect(nameText.style?.color, isNot(equals(AsmitaPalette.textDark)));

    // Verify purpose text widget uses onSurface color
    final purposeTextFinder = find.text('Quarterly Vendor Inspection');
    expect(purposeTextFinder, findsOneWidget);
    final purposeText = tester.widget<Text>(purposeTextFinder);
    expect(purposeText.style?.color, equals(AsmitaTheme.darkTheme.colorScheme.onSurface),
        reason: 'Purpose text must adapt to onSurface in dark mode');
    expect(purposeText.style?.color, isNot(equals(AsmitaPalette.textDark)));
  });

  testWidgets('FacilityStaffDashboardView in Dark Theme: expanded visitor roster uses adaptive surface color', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<IndustrialVisitBloc>.value(value: industrialVisitBloc),
        ],
        child: MaterialApp(
          theme: AsmitaTheme.lightTheme,
          darkTheme: AsmitaTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: FacilityStaffDashboardView(),
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap Building Occupancy Tracker to expand the roster
    final occupancyTrackerFinder = find.text('Building Occupancy Tracker');
    expect(occupancyTrackerFinder, findsOneWidget);
    await tester.tap(occupancyTrackerFinder);
    await tester.pumpAndSettle();

    // Verify roster header appears
    final rosterHeaderFinder = find.text('On-Premises Visitor Roster');
    expect(rosterHeaderFinder, findsOneWidget);

    // Find the roster container enclosing the roster header
    final rosterContainerFinder = find.ancestor(
      of: rosterHeaderFinder,
      matching: find.byType(Container),
    ).first;

    final containerWidget = tester.widget<Container>(rosterContainerFinder);
    final boxDecoration = containerWidget.decoration as BoxDecoration?;
    expect(boxDecoration?.color, equals(AsmitaTheme.darkTheme.colorScheme.surface),
        reason: 'Roster container must use adaptive surface color, not hardcoded white');
    expect(boxDecoration?.color, isNot(equals(Colors.white)));
  });
}
