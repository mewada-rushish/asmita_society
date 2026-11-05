import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_text_field.dart';
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
    userId: 42,
    fullName: 'Priya Sharma',
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
        flatId: 302,
        flatNumber: 'B-302',
        towerId: 1,
        towerName: 'Tower B',
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
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AsmitaPreApproveWizard.showAsModalSheet(ctx);
                },
                child: const Text('Open Pre-Approve Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openCategory(WidgetTester tester, String categoryName) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestbed());
    await tester.tap(find.text('Open Pre-Approve Sheet'));
    await tester.pumpAndSettle();

    expect(find.byType(AsmitaBottomSheet), findsOneWidget);
    await tester.tap(find.text(categoryName));
    await tester.pumpAndSettle();
  }

  Finder findTextFieldIn(String label) {
    return find.descendant(
      of: find.widgetWithText(AsmitaTextField, label),
      matching: find.byType(TextField),
    );
  }

  group('Pre-Approve Type Field Plan 1: Guest Pass Verification', () {
    testWidgets('renders all dedicated guest fields and suppresses foreign fields', (tester) async {
      await openCategory(tester, 'Guest');

      // Verify dedicated Guest fields
      expect(find.text('Guest / Visitor Name (Optional)'), findsOneWidget);
      expect(find.text('Mobile Number (Optional)'), findsOneWidget);
      expect(find.text('Arrival Date'), findsOneWidget);
      expect(find.text('Arrival Time'), findsOneWidget);
      expect(find.text('Purpose of Visit*'), findsOneWidget);
      expect(find.text('Number of Guests:'), findsOneWidget);
      expect(find.text('Vehicle Number (Optional)'), findsOneWidget);
      expect(find.text('VIP Priority Access'), findsOneWidget);
      expect(find.text('Authorize Entry'), findsOneWidget);

      // Verify foreign controls are NOT rendered
      expect(find.text('Delivery Partner / App*'), findsNothing);
      expect(find.text('Leave at Gate'), findsNothing);
      expect(find.text('Surprise Delivery'), findsNothing);
      expect(find.text('Trip Direction *'), findsNothing);
      expect(find.text('Cab / Vehicle Provider'), findsNothing);
      expect(find.text('Service Category / Trade *'), findsNothing);
    });

    testWidgets('guest count stepper increments and decrements within bounds (1 to 20)', (tester) async {
      await openCategory(tester, 'Guest');

      expect(find.text('1'), findsOneWidget);

      final minusBtn = find.byIcon(Icons.remove_circle_outline_rounded);
      final plusBtn = find.byIcon(Icons.add_circle_outline_rounded);

      // Decrement below 1 is blocked
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Increment to 3
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      // Decrement back to 2
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('Pre-Approve Type Field Plan 2: Delivery Pass Verification', () {
    testWidgets('renders all dedicated delivery fields and suppresses foreign fields', (tester) async {
      await openCategory(tester, 'Delivery');

      // Verify dedicated Delivery fields
      expect(find.text('Delivery Partner / App*'), findsOneWidget);
      expect(find.text('Zomato'), findsOneWidget);
      expect(find.text('Swiggy'), findsOneWidget);
      expect(find.text('Amazon'), findsOneWidget);
      expect(find.text('Blinkit'), findsOneWidget);
      expect(find.text('Delivery / Order ID (Optional)'), findsOneWidget);
      expect(find.text('Allow entry once in next:'), findsOneWidget);
      expect(find.text('Leave at Gate'), findsOneWidget);
      expect(find.text('Authorize security guard to collect parcel on your behalf.'), findsOneWidget);
      expect(find.text('Surprise Delivery'), findsOneWidget);
      expect(find.text('Delivery Partner Phone (Optional)'), findsOneWidget);
      expect(find.text('Authorize Delivery'), findsOneWidget);

      // Verify foreign controls are NOT rendered
      expect(find.text('Number of Guests:'), findsNothing);
      expect(find.text('Trip Direction *'), findsNothing);
      expect(find.text('Cab / Vehicle Provider'), findsNothing);
      expect(find.text('Safe Pickup Mode'), findsNothing);
      expect(find.text('Service Category / Trade *'), findsNothing);
    });

    testWidgets('toggling Leave at Gate updates visual card state', (tester) async {
      await openCategory(tester, 'Delivery');

      // Initially Leave at Gate radio is unchecked
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // Tap Leave at Gate card
      await tester.tap(find.text('Leave at Gate'));
      await tester.pumpAndSettle();

      // Now Leave at Gate is checked
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNothing);
    });
  });

  group('Pre-Approve Type Field Plan 3: Cab Pass Verification', () {
    testWidgets('renders all dedicated cab fields and suppresses foreign fields', (tester) async {
      await openCategory(tester, 'Cab');

      // Verify dedicated Cab fields
      expect(find.text('Cab / Vehicle Provider'), findsOneWidget);
      expect(find.text('Uber'), findsOneWidget);
      expect(find.text('Ola'), findsOneWidget);
      expect(find.text('Rapido'), findsOneWidget);
      expect(find.text('Vehicle Category'), findsOneWidget);
      expect(find.text('Vehicle Registration Number *'), findsOneWidget);
      expect(find.text('Trip Direction *'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Drop'), findsOneWidget);
      expect(find.text('Allow entry once in next:'), findsOneWidget);
      expect(find.text('Safe Pickup Mode'), findsOneWidget);
      expect(find.text('Driver Mobile Number (Optional)'), findsOneWidget);
      expect(find.text('Authorize Cab'), findsOneWidget);

      // Verify foreign controls are NOT rendered
      expect(find.text('Delivery Partner / App*'), findsNothing);
      expect(find.text('Leave at Gate'), findsNothing);
      expect(find.text('Surprise Delivery'), findsNothing);
      expect(find.text('Number of Guests:'), findsNothing);
      expect(find.text('Service Category / Trade *'), findsNothing);
    });

    testWidgets('allows toggling Trip Direction choice chips between Pickup and Drop', (tester) async {
      await openCategory(tester, 'Cab');

      // Tap Drop choice chip
      await tester.tap(find.text('Drop'));
      await tester.pumpAndSettle();

      // Verify ChoiceChip selection visual state
      final dropChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Drop'));
      expect(dropChip.selected, isTrue);

      final pickupChip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pickup'));
      expect(pickupChip.selected, isFalse);
    });
  });

  group('Pre-Approve Type Field Plan 4: Visiting Help Pass Verification', () {
    testWidgets('renders all dedicated visiting help fields and suppresses foreign fields', (tester) async {
      await openCategory(tester, 'Visiting Help');

      // Verify dedicated Visiting Help fields
      expect(find.text('Service Category / Trade *'), findsOneWidget);
      expect(find.text('Plumber'), findsOneWidget);
      expect(find.text('Electrician'), findsOneWidget);
      expect(find.text('Maid'), findsOneWidget);
      expect(find.text('Cook'), findsOneWidget);
      expect(find.text('Technician / Partner Name *'), findsOneWidget);
      expect(find.text('Mobile Number (Optional)'), findsOneWidget);
      expect(find.text('Work Description / Notes (Optional)'), findsOneWidget);
      expect(find.text('Vehicle Number (Optional)'), findsOneWidget);
      expect(find.text('Authorize Service Partner'), findsOneWidget);

      // Frequency selector Tabs
      expect(find.text('Once'), findsOneWidget);
      expect(find.text('Frequently'), findsOneWidget);

      // Verify foreign controls are NOT rendered
      expect(find.text('Leave at Gate'), findsNothing);
      expect(find.text('Surprise Delivery'), findsNothing);
      expect(find.text('Trip Direction *'), findsNothing);
      expect(find.text('Safe Pickup Mode'), findsNothing);
      expect(find.text('Delivery Partner / App*'), findsNothing);
    });

    testWidgets('selecting Other trade chip reveals Specify Service Trade input field', (tester) async {
      await openCategory(tester, 'Visiting Help');

      expect(find.text('Specify Service Trade *'), findsNothing);

      // Scroll to and tap 'Other' trade chip
      final otherChip = find.widgetWithText(ChoiceChip, 'Other');
      await tester.ensureVisible(otherChip);
      await tester.tap(otherChip);
      await tester.pumpAndSettle();

      expect(find.text('Specify Service Trade *'), findsOneWidget);
    });
  });

  group('Pre-Approve Validation & Submission Payload Dispatch Verification', () {
    testWidgets('Guest form rejects invalid 9-digit mobile number with error toast', (tester) async {
      await openCategory(tester, 'Guest');

      // Enter 9 digits into mobile number field
      final phoneField = findTextFieldIn('Mobile Number (Optional)');
      await tester.enterText(phoneField, '987654321');
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.text('Authorize Entry');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Error toast shown
      expect(find.text('Please enter a valid 10-digit mobile number.'), findsOneWidget);
      verifyNever(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });

    testWidgets('Cab form rejects submission when vehicle registration number is empty', (tester) async {
      await openCategory(tester, 'Cab');

      // Submit without entering vehicle registration
      final submitBtn = find.text('Authorize Cab');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Error toast shown
      expect(find.text('Please enter vehicle registration number for cab entries.'), findsOneWidget);
      verifyNever(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });

    testWidgets('Visiting Help form rejects submission when technician name is empty', (tester) async {
      await openCategory(tester, 'Visiting Help');

      // Submit without entering technician name
      final submitBtn = find.text('Authorize Service Partner');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Error toast shown
      expect(find.text('Please enter technician or service partner name.'), findsOneWidget);
      verifyNever(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });

    testWidgets('Visiting Help form rejects submission when Other trade is selected without trade name', (tester) async {
      await openCategory(tester, 'Visiting Help');

      // Scroll to and tap 'Other' trade chip
      final otherChip = find.widgetWithText(ChoiceChip, 'Other');
      await tester.ensureVisible(otherChip);
      await tester.tap(otherChip);
      await tester.pumpAndSettle();

      // Enter technician name but leave trade blank
      final nameField = findTextFieldIn('Technician / Partner Name *');
      await tester.enterText(nameField, 'Ramesh Technician');
      await tester.pumpAndSettle();

      final submitBtn = find.text('Authorize Service Partner');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please specify the service trade.'), findsOneWidget);
      verifyNever(() => mockVisitorBloc.add(any(that: isA<CreatePreApprovedInviteEvent>())));
    });

    testWidgets('valid Guest pass dispatches CreatePreApprovedInviteEvent with proper guest payload', (tester) async {
      await openCategory(tester, 'Guest');

      final nameField = findTextFieldIn('Guest / Visitor Name (Optional)');
      await tester.enterText(nameField, 'Sunil Sharma');

      final phoneField = findTextFieldIn('Mobile Number (Optional)');
      await tester.enterText(phoneField, '9876543210');

      // Select Purpose chip 'Family & Friends'
      await tester.tap(find.text('Family & Friends'));

      // Increment guest count to 2
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      final submitBtn = find.text('Authorize Entry');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final captured = verify(() => mockVisitorBloc.add(captureAny(that: isA<CreatePreApprovedInviteEvent>()))).captured;
      expect(captured.isNotEmpty, isTrue);

      final event = captured.last as CreatePreApprovedInviteEvent;
      final payload = event.payload;

      expect(payload['invite_type'], equals('guest'));
      expect(payload['visitor_name'], equals('Sunil Sharma'));
      expect(payload['mobile_number'], equals('9876543210'));
      expect(payload['max_guest_count'], equals(2));
      expect(payload['purpose'], equals('Family & Friends'));
      expect(payload['is_vip'], isFalse);
    });

    testWidgets('valid Delivery pass with Leave at Gate dispatches delivery payload', (tester) async {
      await openCategory(tester, 'Delivery');

      // Toggle Leave at Gate
      await tester.tap(find.text('Leave at Gate'));
      await tester.pumpAndSettle();

      final submitBtn = find.text('Authorize Delivery');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final captured = verify(() => mockVisitorBloc.add(captureAny(that: isA<CreatePreApprovedInviteEvent>()))).captured;
      expect(captured.isNotEmpty, isTrue);

      final event = captured.last as CreatePreApprovedInviteEvent;
      final payload = event.payload;

      expect(payload['invite_type'], equals('delivery'));
      expect(payload['company_name'], equals('Zomato'));
      expect(payload['delivery_company'], equals('Zomato'));
      expect(payload['leave_at_gate'], isTrue);
      expect(payload['invite_sub_type'], equals('ONCE'));
      expect(payload['visitor_name'], equals('Zomato Partner'));
      expect(payload['purpose'], contains('[Leave at Gate]'));
    });

    testWidgets('valid Cab pass dispatches cab payload with uppercase formatted registration', (tester) async {
      await openCategory(tester, 'Cab');

      // Enter lowercase vehicle reg
      final regField = findTextFieldIn('Vehicle Registration Number *');
      await tester.enterText(regField, 'mh 04 ab 1234');

      // Select Drop direction
      await tester.tap(find.text('Drop'));
      await tester.pumpAndSettle();

      final submitBtn = find.text('Authorize Cab');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final captured = verify(() => mockVisitorBloc.add(captureAny(that: isA<CreatePreApprovedInviteEvent>()))).captured;
      expect(captured.isNotEmpty, isTrue);

      final event = captured.last as CreatePreApprovedInviteEvent;
      final payload = event.payload;

      expect(payload['invite_type'], equals('cab'));
      expect(payload['company_name'], equals('Uber'));
      expect(payload['vehicle_number'], equals('MH 04 AB 1234'));
      expect(payload['purpose'], equals('Cab Drop'));
      expect(payload['title'], equals('Uber Cab (Drop)'));
      expect(payload['invite_sub_type'], equals('ONCE'));
    });

    testWidgets('valid Visiting Help pass strictly dispatches invite_type: guest matching backend enum', (tester) async {
      await openCategory(tester, 'Visiting Help');

      // Plumber is selected by default
      final nameField = findTextFieldIn('Technician / Partner Name *');
      await tester.enterText(nameField, 'Ramesh Plumber');
      await tester.pumpAndSettle();

      final submitBtn = find.text('Authorize Service Partner');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      final captured = verify(() => mockVisitorBloc.add(captureAny(that: isA<CreatePreApprovedInviteEvent>()))).captured;
      expect(captured.isNotEmpty, isTrue);

      final event = captured.last as CreatePreApprovedInviteEvent;
      final payload = event.payload;

      // Crucial backend schema alignment: enum strictly accepts 'guest', 'cab', 'delivery'
      expect(payload['invite_type'], equals('guest'));
      expect(payload['company_name'], equals('Plumber'));
      expect(payload['visitor_name'], equals('Ramesh Plumber'));
      expect(payload['purpose'], contains('Service Partner: Plumber'));
      expect(payload['invite_sub_type'], equals('ONCE'));
    });
  });
}
