import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

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
    societyId: 101,
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

  Widget buildTestbed() {
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
            builder: (ctx) => ElevatedButton(
              onPressed: () => AsmitaPreApproveWizard.showAsModalSheet(ctx),
              child: const Text('Open Pre-Approve'),
            ),
          ),
        ),
      ),
    );
  }

  test('vehicleTypeOptions contains strictly Bike and Car', () {
    expect(AsmitaPreApproveWizard.vehicleTypeOptions, equals(['Bike', 'Car']));
  });

  testWidgets('renders only Bike and Car category options in Cab pass and allows toggling', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestbed());
    await tester.tap(find.text('Open Pre-Approve'));
    await tester.pumpAndSettle();

    // Tap 'Cab'
    await tester.tap(find.text('Cab'));
    await tester.pumpAndSettle();

    // Verify 'Vehicle Category' section exists
    expect(find.text('Vehicle Category'), findsOneWidget);

    // Verify Bike and Car chips are present
    expect(find.widgetWithText(ChoiceChip, 'Bike'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Car'), findsOneWidget);

    // Verify foreign/legacy chips are NOT present
    expect(find.text('Personal Bike'), findsNothing);
    expect(find.text('Personal Car'), findsNothing);
    expect(find.text('Auto / Cab'), findsNothing);
    expect(find.text('Commercial'), findsNothing);

    // Default is Car
    final carChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Car'));
    expect(carChip.selected, isTrue);

    final bikeChipBefore = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Bike'));
    expect(bikeChipBefore.selected, isFalse);

    // Tap 'Bike'
    await tester.tap(find.widgetWithText(ChoiceChip, 'Bike'));
    await tester.pumpAndSettle();

    final bikeChipAfter = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Bike'));
    expect(bikeChipAfter.selected, isTrue);

    final carChipAfter = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Car'));
    expect(carChipAfter.selected, isFalse);
  });
}
