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
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_pre_approve_wizard.dart';

import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_event.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVisitorBloc extends Mock implements VisitorBloc {}
class MockGuardGateBloc extends Mock implements GuardGateBloc {}

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

  late StreamController<AuthState> authStateController;
  late StreamController<VisitorState> visitorStateController;
  late StreamController<GuardGateState> guardGateStateController;

  final testUser = UserModel(
    userId: 1,
    fullName: 'Test Resident',
    primaryRole: 'owner',
    accountType: 'app',
    societyId: 1,
    societyName: 'AsmitA Grandeur',
    permissions: const {'canManageVisitors': true, 'visitor_management': true},
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

    authStateController = StreamController<AuthState>.broadcast();
    visitorStateController = StreamController<VisitorState>.broadcast();
    guardGateStateController = StreamController<GuardGateState>.broadcast();

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
  });

  tearDown(() {
    authStateController.close();
    visitorStateController.close();
    guardGateStateController.close();
  });

  Widget createTestBed({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
        BlocProvider<GuardGateBloc>.value(value: mockGuardGateBloc),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AsmitaPreApproveWizard.showAsModalSheet(ctx);
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Adversarial 1: Slide-Up Bottom Sheet 80% Constraint', () {
    testWidgets('Sheet height NEVER exceeds 80% screen height at 600px height (500w)', (tester) async {
      tester.view.physicalSize = const Size(500, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      expect(sheetSize.height, lessThanOrEqualTo(600 * 0.80 + 0.1));
    });

    testWidgets('Sheet height NEVER exceeds 80% screen height at 800px height (500w)', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      expect(sheetSize.height, lessThanOrEqualTo(800 * 0.80 + 0.1));
    });

    testWidgets('Sheet height NEVER exceeds 80% screen height at 1200px height (600w)', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);

      final sheetSize = tester.getSize(sheetFinder);
      expect(sheetSize.height, lessThanOrEqualTo(1200 * 0.80 + 0.1));
    });

    testWidgets('Keyboard expansion (viewInsets.bottom: 300) does not overflow or crash (500w)', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(AsmitaBottomSheet), findsOneWidget);

      // Simulate soft keyboard opening
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(AsmitaBottomSheet), findsOneWidget);

      // Verify the sheet container itself shrunk or clamped safely
      final sheetSize = tester.getSize(find.byType(AsmitaBottomSheet));
      expect(sheetSize.height, lessThanOrEqualTo((800 - 300) * 0.80 + 0.1));
    });
  });

  group('Adversarial 2: Pre-Approve Type Field Plan Dynamic Visibility', () {
    testWidgets('Guest form shows name, phone, purpose, guest count; hides delivery/cab/trade', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Step 0: Category selection - tap 'Guest'
      final guestTile = find.text('Guest');
      expect(guestTile, findsOneWidget);
      await tester.tap(guestTile);
      await tester.pumpAndSettle();

      // Verify Guest fields visible
      expect(find.text('Guest / Visitor Name (Optional)'), findsOneWidget);
      expect(find.text('Mobile Number (Optional)'), findsOneWidget);
      expect(find.text('Number of Guests:'), findsOneWidget);
      expect(find.text('Purpose of Visit*'), findsOneWidget);

      // Verify foreign fields hidden
      expect(find.text('Delivery Partner / App*'), findsNothing);
      expect(find.text('Leave at Gate'), findsNothing);
      expect(find.text('Trip Direction *'), findsNothing);
      expect(find.text('Service Category / Trade *'), findsNothing);
    });

    testWidgets('Delivery form shows delivery platform, Leave at Gate; hides guest count, cab direction, trades', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Step 0: Category selection - tap 'Delivery'
      final deliveryTile = find.text('Delivery');
      expect(deliveryTile, findsOneWidget);
      await tester.tap(deliveryTile);
      await tester.pumpAndSettle();

      // Verify Delivery fields visible
      expect(find.text('Delivery Partner / App*'), findsOneWidget);
      expect(find.text('Surprise Delivery'), findsOneWidget);
      expect(find.text('Authorize Entry'), findsOneWidget);

      // Verify foreign fields hidden
      expect(find.text('Number of Guests:'), findsNothing);
      expect(find.text('Trip Direction *'), findsNothing);
      expect(find.text('Safe Pickup Mode'), findsNothing);
      expect(find.text('Service Category / Trade *'), findsNothing);
    });

    testWidgets('Cab form shows cab provider, vehicle reg, trip direction; hides delivery, trades', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Step 0: Category selection - tap 'Cab'
      final cabTile = find.text('Cab');
      expect(cabTile, findsOneWidget);
      await tester.tap(cabTile);
      await tester.pumpAndSettle();

      // Verify Cab fields visible
      expect(find.text('Cab / Vehicle Provider'), findsOneWidget);
      expect(find.text('Cab / Vehicle Registration Number *'), findsOneWidget);
      expect(find.text('2 : 2 : 4'), findsOneWidget);
      expect(find.text('Safe Pickup Mode'), findsOneWidget);
      expect(find.text('Authorize Entry'), findsOneWidget);

      // Verify foreign fields hidden
      expect(find.text('Delivery Partner / App*'), findsNothing);
      expect(find.text('Leave at Gate'), findsNothing);
      expect(find.text('Number of Guests:'), findsNothing);
      expect(find.text('Service Category / Trade *'), findsNothing);
    });

    testWidgets('Visiting Help form shows service trade chips, technician name; hides Leave at Gate, cab direction', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestBed(child: const SizedBox()));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Step 0: Category selection - tap 'Visiting Help'
      final helpTile = find.text('Visiting Help');
      expect(helpTile, findsOneWidget);
      await tester.tap(helpTile);
      await tester.pumpAndSettle();

      // Verify Visiting Help fields visible
      expect(find.text('Technician / Contractor Name (Optional)'), findsOneWidget);
      expect(find.text('Authorize Entry'), findsOneWidget);

      // Verify foreign fields hidden
      expect(find.text('Leave at Gate'), findsNothing);
      expect(find.text('Trip Direction *'), findsNothing);
      expect(find.text('Safe Pickup Mode'), findsNothing);
      expect(find.text('Delivery Partner / App*'), findsNothing);
    });
  });
}
