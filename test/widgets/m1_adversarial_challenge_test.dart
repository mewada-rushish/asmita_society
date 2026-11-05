import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_pre_approve_wizard.dart';
import 'package:asmita_society/features/dashboard/presentation/views/owner_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/tenant_dashboard_view.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_bloc.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_state.dart';
import 'package:asmita_society/features/dashboard/data/models/quick_action_registry.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/services/bloc/amenities_bloc.dart';
import 'package:asmita_society/features/services/bloc/amenities_state.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVisitorBloc extends Mock implements VisitorBloc {}
class MockGuardGateBloc extends Mock implements GuardGateBloc {}
class MockQuickActionsBloc extends Mock implements QuickActionsBloc {}
class MockCommunityPostBloc extends Mock implements CommunityPostBloc {}
class MockAmenitiesBloc extends Mock implements AmenitiesBloc {}

class FakeVisitorEvent extends Fake implements VisitorEvent {}

void main() {
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
    userId: 101,
    fullName: 'Empirical Tester',
    primaryRole: 'owner',
    accountType: 'app',
    societyId: 1,
    societyName: 'AsmitA Grandeur',
    flatMappings: [
      FlatMapping(
        mappingId: 1,
        flatId: 201,
        flatNumber: 'A-201',
        towerId: 1,
        towerName: 'Tower A',
        ownershipType: 'owner',
      ),
    ],
    permissions: const {
      'canManageVisitors': true,
      'visitor_management': true,
      'community': true,
    },
  );

  setUpAll(() {
    registerFallbackValue(FakeVisitorEvent());
  });

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

  tearDown(() async {
    await authStateController.close();
    await visitorStateController.close();
    await guardGateStateController.close();
    await quickActionsStateController.close();
    await communityPostStateController.close();
    await amenitiesStateController.close();
  });

  Widget buildWizardApp({Widget? child}) {
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
            builder: (context) => child ?? ElevatedButton(
              onPressed: () => AsmitaPreApproveWizard.showAsModalSheet(context),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  group('Milestone 1 Adversarial Challenge: Validation & Edge Cases', () {
    testWidgets('Guest form: Entering 9 digits for phone rejects submission with error toast', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Guest in category selection
      await tester.tap(find.text('Guest'));
      await tester.pumpAndSettle();

      // Enter 9 digits into mobile number field (2nd TextField in Guest form)
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      // Index 1 is mobile number
      await tester.enterText(textFields.at(1), '987654321');
      await tester.pumpAndSettle();

      // Scroll to Authorize Entry button and tap
      final submitBtn = find.text('Authorize Entry');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verification: Error toast shown, VisitorBloc never received CreatePreApprovedInviteEvent
      expect(find.text('Please enter a valid 10-digit mobile number.'), findsOneWidget);
      verifyNever(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });

    testWidgets('Cab form: Submitting lowercase vehicle number formats to uppercase in payload', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Switch to Cab category
      await tester.tap(find.text('Cab'));
      await tester.pumpAndSettle();

      // Enter lowercase vehicle reg number into the vehicle text field
      final vehicleField = find.byType(TextField).first;
      await tester.enterText(vehicleField, 'mh 04 cd 5678');
      await tester.pumpAndSettle();

      // Tap Authorize Cab
      final submitBtn = find.text('Authorize Cab');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Capture dispatched event
      final captured = verify(() => mockVisitorBloc.add(captureAny())).captured;
      expect(captured.isNotEmpty, isTrue);
      final event = captured.first as CreatePreApprovedInviteEvent;
      expect(event.payload['invite_type'], equals('cab'));
      expect(event.payload['vehicle_number'], equals('MH 04 CD 5678'));
    });

    testWidgets('Delivery form: Submitting with Other company but empty custom name rejects with error toast', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Switch to Delivery category
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();

      // Tap 'View All' to open company network sheet
      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      // Select 'Other' in the grid
      final otherFinder = find.text('Other').last;
      await tester.ensureVisible(otherFinder);
      await tester.tap(otherFinder);
      await tester.pumpAndSettle();

      // Confirm Selection with empty text
      await tester.tap(find.text('Confirm Selection'));
      await tester.pumpAndSettle();

      // Tap Authorize Delivery
      final submitBtn = find.text('Authorize Delivery');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verification: Error toast shown, no event dispatched
      expect(find.text('Please enter the delivery company name.'), findsOneWidget);
      verifyNever(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });

    testWidgets('Visiting Help form: Submitting without helper name rejects with error toast', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Switch to Visiting Help category
      await tester.tap(find.text('Visiting Help'));
      await tester.pumpAndSettle();

      // Leave helper name empty and tap Authorize Service Partner
      final submitBtn = find.text('Authorize Service Partner');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verification: Error toast shown, no event dispatched
      expect(find.text('Please enter technician or service partner name.'), findsOneWidget);
      verifyNever(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });

    testWidgets('Visiting Help form: Payload correctly maps to invite_type "guest" to prevent 400 backend schema failure', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Switch to Visiting Help category
      await tester.tap(find.text('Visiting Help'));
      await tester.pumpAndSettle();

      // Select 'Electrician' chip
      await tester.tap(find.text('Electrician'));
      await tester.pumpAndSettle();

      // Enter helper name into first textfield
      final helperNameField = find.byType(TextField).first;
      await tester.enterText(helperNameField, 'Ramesh Electrician');
      await tester.pumpAndSettle();

      // Tap Authorize Service Partner
      final submitBtn = find.text('Authorize Service Partner');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Capture dispatched event
      final captured = verify(() => mockVisitorBloc.add(captureAny())).captured;
      expect(captured.isNotEmpty, isTrue);
      final event = captured.first as CreatePreApprovedInviteEvent;

      // Verification: invite_type must be strictly 'guest'
      expect(event.payload['invite_type'], equals('guest'));
      expect(event.payload['company_name'], equals('Electrician'));
      expect(event.payload['visitor_name'], equals('Ramesh Electrician'));
      expect(event.payload['purpose'], contains('Electrician'));
    });
  });

  group('Milestone 1 Adversarial Challenge: Bottom Sheet Constraints & Scrolling', () {
    testWidgets('Slide-up sheet height never exceeds 80% screen height across viewport variations', (tester) async {
      // Test 800px viewport
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final sheetFinder = find.byType(AsmitaBottomSheet);
      expect(sheetFinder, findsOneWidget);
      final sheetSize800 = tester.getSize(sheetFinder);
      expect(sheetSize800.height, lessThanOrEqualTo(800 * 0.80 + 0.5));

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Test 1000px viewport
      tester.view.physicalSize = const Size(500, 1000);
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final sheetSize1000 = tester.getSize(find.byType(AsmitaBottomSheet));
      expect(sheetSize1000.height, lessThanOrEqualTo(1000 * 0.80 + 0.5));
    });

    testWidgets('ClampingScrollPhysics is configured on the modal scroll view', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final scrollViews = tester.widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final hasClamping = scrollViews.any((sv) => sv.physics is ClampingScrollPhysics);
      expect(hasClamping, isTrue);
    });

    testWidgets('Bottom buttons remain scrollable and tappable when keyboard is visible', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWizardApp());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Guest category to enter form
      await tester.tap(find.text('Guest'));
      await tester.pumpAndSettle();

      // Simulate keyboard open with 280px viewInsets bottom
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final submitBtn = find.text('Authorize Entry');
      expect(submitBtn, findsOneWidget);

      // Ensure visible by scrolling in constrained height
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();

      // Verify button is tappable without layout exception
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verification: Even with keyboard taking 280px of 800px viewport,
      // the scroll view allowed scrolling down to tap Authorize Entry,
      // which safely submitted the form (event dispatched with Guest defaults)
      verify(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });
  });

  group('Milestone 1 Adversarial Challenge: Dashboard Invocation & Permissions', () {
    testWidgets('OwnerDashboardView blocks pre-approve sheet when permission is denied', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final restrictedUser = UserModel(
        userId: 102,
        fullName: 'Restricted Owner',
        primaryRole: 'owner',
        accountType: 'app',
        permissions: const {'canManageVisitors': false},
      );
      when(() => mockAuthBloc.state).thenReturn(
        AuthAuthenticated(user: restrictedUser, sessionRole: 'owner'),
      );

      await tester.pumpWidget(
        buildWizardApp(
          child: OwnerDashboardView(
            onNavigateToViewMore: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pre-Approve Quick Action
      await tester.tap(find.text('Pre-Approve'));
      await tester.pumpAndSettle();

      // Expect permission error toast and sheet NOT opened
      expect(find.text('Your role does not have permission to pre-approve visitors.'), findsOneWidget);
      expect(find.byType(AsmitaBottomSheet), findsNothing);
    });

    testWidgets('TenantDashboardView blocks pre-approve sheet when permission is denied', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final restrictedTenant = UserModel(
        userId: 103,
        fullName: 'Restricted Tenant',
        primaryRole: 'tenant',
        accountType: 'app',
        permissions: const {'canManageVisitors': false},
      );
      when(() => mockAuthBloc.state).thenReturn(
        AuthAuthenticated(user: restrictedTenant, sessionRole: 'tenant'),
      );

      await tester.pumpWidget(
        buildWizardApp(
          child: TenantDashboardView(
            onNavigateToViewMore: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pre-Approve Quick Action
      await tester.tap(find.text('Pre-Approve'));
      await tester.pumpAndSettle();

      // Expect permission error toast and sheet NOT opened
      expect(find.text('Your role does not have permission to pre-approve visitors.'), findsOneWidget);
      expect(find.byType(AsmitaBottomSheet), findsNothing);
    });
  });
}
