import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_bloc.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_state.dart';
import 'package:asmita_society/features/dashboard/data/models/quick_action_registry.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/services/bloc/amenities_bloc.dart';
import 'package:asmita_society/features/services/bloc/amenities_state.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_pre_approve_wizard.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVisitorBloc extends Mock implements VisitorBloc {}
class MockGuardGateBloc extends Mock implements GuardGateBloc {}
class MockQuickActionsBloc extends Mock implements QuickActionsBloc {}
class MockCommunityPostBloc extends Mock implements CommunityPostBloc {}
class MockAmenitiesBloc extends Mock implements AmenitiesBloc {}

class FakeVisitorEvent extends Fake implements VisitorEvent {}
class FakeGuardGateEvent extends Fake implements GuardGateEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeVisitorEvent());
    registerFallbackValue(FakeGuardGateEvent());
  });

  late MockAuthBloc mockAuthBloc;
  late MockVisitorBloc mockVisitorBloc;
  late MockGuardGateBloc mockGuardGateBloc;
  late MockQuickActionsBloc mockQuickActionsBloc;
  late MockCommunityPostBloc mockCommunityPostBloc;
  late MockAmenitiesBloc mockAmenitiesBloc;

  late StreamController<AuthState> authStateController;
  late StreamController<VisitorState> visitorStateController;
  late StreamController<GuardGateState> guardGateStateController;
  late StreamController<QuickActionsState> quickActionsStateController;
  late StreamController<CommunityPostState> communityPostStateController;
  late StreamController<AmenitiesState> amenitiesStateController;

  final testUser = UserModel(
    userId: 1,
    fullName: 'Rajesh Mehta',
    primaryRole: 'owner',
    accountType: 'app',
    societyId: 1,
    societyName: 'AsmitA Grandeur',
    permissions: const {
      'canManageVisitors': true,
      'visitor_management': true,
      'community': true,
    },
    flatMappings: [
      FlatMapping(
        mappingId: 10,
        flatId: 101,
        flatNumber: 'A-101',
        towerId: 1,
        towerName: 'Tower A',
        ownershipType: 'owner',
      ),
    ],
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVisitorBloc = MockVisitorBloc();
    mockGuardGateBloc = MockGuardGateBloc();
    mockQuickActionsBloc = MockQuickActionsBloc();
    mockCommunityPostBloc = MockCommunityPostBloc();
    mockAmenitiesBloc = MockAmenitiesBloc();

    authStateController = StreamController<AuthState>.broadcast();
    visitorStateController = StreamController<VisitorState>.broadcast();
    guardGateStateController = StreamController<GuardGateState>.broadcast();
    quickActionsStateController = StreamController<QuickActionsState>.broadcast();
    communityPostStateController = StreamController<CommunityPostState>.broadcast();
    amenitiesStateController = StreamController<AmenitiesState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockVisitorBloc.stream).thenAnswer((_) => visitorStateController.stream);
    when(() => mockVisitorBloc.state).thenReturn(const VisitorHistoryLoaded(history: []));
    when(() => mockVisitorBloc.close()).thenAnswer((_) async {});
    when(() => mockVisitorBloc.add(any())).thenReturn(null);

    when(() => mockGuardGateBloc.stream).thenAnswer((_) => guardGateStateController.stream);
    when(() => mockGuardGateBloc.state).thenReturn(const GuardGateState());
    when(() => mockGuardGateBloc.close()).thenAnswer((_) async {});
    when(() => mockGuardGateBloc.add(any())).thenReturn(null);

    when(() => mockQuickActionsBloc.stream).thenAnswer((_) => quickActionsStateController.stream);
    when(() => mockQuickActionsBloc.state).thenReturn(
      const QuickActionsLoaded(QuickActionRegistry.defaultActions),
    );
    when(() => mockQuickActionsBloc.close()).thenAnswer((_) async {});

    when(() => mockCommunityPostBloc.stream).thenAnswer((_) => communityPostStateController.stream);
    when(() => mockCommunityPostBloc.state).thenReturn(
      const CommunityPostState(status: CommunityPostStatus.loaded, posts: []),
    );
    when(() => mockCommunityPostBloc.close()).thenAnswer((_) async {});

    when(() => mockAmenitiesBloc.stream).thenAnswer((_) => amenitiesStateController.stream);
    when(() => mockAmenitiesBloc.state).thenReturn(const AmenitiesState());
    when(() => mockAmenitiesBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() {
    authStateController.close();
    visitorStateController.close();
    guardGateStateController.close();
    quickActionsStateController.close();
    communityPostStateController.close();
    amenitiesStateController.close();
  });

  Widget buildTestbed({
    bool isGuardMode = false,
    String? title,
    String? subtitle,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
        BlocProvider<GuardGateBloc>.value(value: mockGuardGateBloc),
        BlocProvider<QuickActionsBloc>.value(value: mockQuickActionsBloc),
        BlocProvider<CommunityPostBloc>.value(value: mockCommunityPostBloc),
        BlocProvider<AmenitiesBloc>.value(value: mockAmenitiesBloc),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AsmitaPreApproveWizard.showAsModalSheet(
                    ctx,
                    isGuardMode: isGuardMode,
                    title: title,
                    subtitle: subtitle,
                  );
                },
                child: const Text('Open Pre-Approve Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Pre-Approval Slide-up Sheet Presentation & 80% Constraint', () {
    testWidgets('triggering pre-approval launches an AsmitaBottomSheet modal slide-up sheet', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      // Verify AsmitaBottomSheet exists
      expect(find.byType(AsmitaBottomSheet), findsOneWidget);

      // Verify default title is Pre-Approve Entry
      expect(find.text('Pre-Approve Entry'), findsOneWidget);

      // Verify close button exists
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);

      // Verify category tiles exist inside the sheet
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Cab'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Visiting Help'), findsOneWidget);
    });

    testWidgets('triggering pre-approval in guard mode sets title and subtitle appropriately', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed(isGuardMode: true));
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(AsmitaBottomSheet), findsOneWidget);
      expect(find.text('New Walk-in Visitor'), findsOneWidget);
      expect(find.text('Record lobby guest entry details'), findsOneWidget);
    });

    testWidgets('enforces strict 80% screen height constraint across 600px viewport', (tester) async {
      const double screenHeight = 600.0;
      const double screenWidth = 400.0;
      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      const maxPermittedHeight = screenHeight * 0.80; // 480.0
      expect(sheetSize.height, lessThanOrEqualTo(maxPermittedHeight + 0.5));
      expect(sheetSize.height, greaterThan(0.0));
    });

    testWidgets('enforces strict 80% screen height constraint across 800px viewport', (tester) async {
      const double screenHeight = 800.0;
      const double screenWidth = 480.0;
      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      const maxPermittedHeight = screenHeight * 0.80; // 640.0
      expect(sheetSize.height, lessThanOrEqualTo(maxPermittedHeight + 0.5));
      expect(sheetSize.height, greaterThan(0.0));
    });

    testWidgets('enforces strict 80% screen height constraint across 1000px viewport', (tester) async {
      const double screenHeight = 1000.0;
      const double screenWidth = 600.0;
      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      const maxPermittedHeight = screenHeight * 0.80; // 800.0
      expect(sheetSize.height, lessThanOrEqualTo(maxPermittedHeight + 0.5));
      expect(sheetSize.height, greaterThan(0.0));
    });

    testWidgets('enforces strict 80% screen height constraint across large 1200px tablet viewport', (tester) async {
      const double screenHeight = 1200.0;
      const double screenWidth = 800.0;
      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      const maxPermittedHeight = screenHeight * 0.80; // 960.0
      expect(sheetSize.height, lessThanOrEqualTo(maxPermittedHeight + 0.5));
      expect(sheetSize.height, greaterThan(0.0));
    });

    testWidgets('simulates keyboard display (280px insets) and adapts smoothly without overflow or collapse', (tester) async {
      const double screenHeight = 800.0;
      const double screenWidth = 480.0;
      const double keyboardInset = 280.0;

      tester.view.physicalSize = const Size(screenWidth, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      final initialSheetSize = tester.getSize(find.byType(AsmitaBottomSheet));
      expect(initialSheetSize.height, lessThanOrEqualTo(screenHeight * 0.80 + 0.5));

      // Simulate soft keyboard opening
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardInset);
      await tester.pumpAndSettle();

      // Assert no exceptions thrown (no overflow)
      expect(tester.takeException(), isNull);
      expect(find.byType(AsmitaBottomSheet), findsOneWidget);

      // Verify the sheet height adapted to available height (screenHeight - keyboardInset)
      final adaptedSheetSize = tester.getSize(find.byType(AsmitaBottomSheet));
      const expectedMaxWithKeyboard = (screenHeight - keyboardInset) * 0.80;
      expect(adaptedSheetSize.height, lessThanOrEqualTo(expectedMaxWithKeyboard + 0.5));
      expect(adaptedSheetSize.height, greaterThanOrEqualTo(100.0));

      // Key UI components remain visible and functional
      expect(find.text('Pre-Approve Entry'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('verifies ClampingScrollPhysics and scroll interactivity on modal sheet content', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      // Tap Guest pass to open lengthy form
      await tester.tap(find.text('Guest'));
      await tester.pumpAndSettle();

      // Find the SingleChildScrollView wrapping the wizard
      final scrollViews = find.byType(SingleChildScrollView);
      expect(scrollViews, findsWidgets);

      // Verify that at least one scroll view uses ClampingScrollPhysics
      final singleChildWidgets = tester.widgetList<SingleChildScrollView>(scrollViews);
      final hasClamping = singleChildWidgets.any((w) => w.physics is ClampingScrollPhysics);
      expect(hasClamping, isTrue);

      // Verify scrollability: scroll down to reveal bottom submit button
      final submitButton = find.text('Authorize Entry');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();

      expect(submitButton, findsOneWidget);
    });

    testWidgets('tapping close icon dismisses modal bottom sheet smoothly', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestbed());
      await tester.tap(find.text('Open Pre-Approve Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(AsmitaBottomSheet), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Sheet is completely dismissed
      expect(find.byType(AsmitaBottomSheet), findsNothing);
    });
  });
}
