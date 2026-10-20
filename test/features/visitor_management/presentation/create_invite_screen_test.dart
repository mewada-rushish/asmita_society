import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/create_invite_screen.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/data/models/invite_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockVisitorBloc extends Mock implements VisitorBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockVisitorBloc mockVisitorBloc;
  late MockAuthBloc mockAuthBloc;
  late StreamController<VisitorState> visitorStateController;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 202,
    fullName: 'Rushish Mewada',
    primaryRole: 'owner',
    accountType: 'app',
    societyId: 1,
    flatMappings: [
      FlatMapping(
        mappingId: 10,
        flatId: 501,
        flatNumber: '501',
        towerId: 2,
        towerName: 'Tower B',
        ownershipType: 'owner',
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(const CreatePreApprovedInviteEvent(payload: {}));
  });

  setUp(() {
    mockVisitorBloc = MockVisitorBloc();
    mockAuthBloc = MockAuthBloc();
    visitorStateController = StreamController<VisitorState>.broadcast();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockVisitorBloc.stream).thenAnswer((_) => visitorStateController.stream);
    when(() => mockVisitorBloc.state).thenReturn(VisitorInitial());
    when(() => mockVisitorBloc.close()).thenAnswer((_) async {});
    when(() => mockVisitorBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await visitorStateController.close();
    await authStateController.close();
  });

  Widget buildTestableWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
      ],
      child: const MaterialApp(
        home: CreateInviteScreen(),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('CreateInviteScreen Production Widget Tests', () {
    testWidgets('renders initial UI elements and choice chips correctly', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Create Invite'), findsOneWidget);
      expect(find.text('Invite Type'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Cab'), findsOneWidget);

      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('One Time'), findsOneWidget);
      expect(find.text('Frequent'), findsOneWidget);

      expect(find.text('Visitor Name'), findsOneWidget);
      expect(find.text('Mobile Number (Optional)'), findsOneWidget);
      expect(find.text('Generate Pass'), findsOneWidget);
    });

    testWidgets('shows validation errors when visitor name is empty or short', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final generatePassBtn = find.text('Generate Pass');
      await tester.tap(generatePassBtn);
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);

      // Enter less than 3 chars
      await tester.enterText(find.byType(TextFormField).first, 'Ab');
      await tester.tap(generatePassBtn);
      await tester.pump();

      expect(find.text('Must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('validates 10-digit mobile number format if provided', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '12345');

      await tester.tap(find.text('Generate Pass'));
      await tester.pump();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);
    });

    testWidgets('switching invite type updates label and chips dynamically', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Tap Delivery chip
      await tester.tap(find.text('Delivery'));
      await tester.pump();

      expect(find.text('Company/Driver Name'), findsOneWidget);
    });

    testWidgets('renders loading indicator when VisitorState is VisitorLoading', (tester) async {
      setMobileScreen(tester);
      when(() => mockVisitorBloc.state).thenReturn(VisitorLoading());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('handles VisitorError snackbar notification', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      visitorStateController.add(const VisitorError(message: 'Failed to create invite on server'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Error: Failed to create invite on server'), findsOneWidget);
    });

    testWidgets('handles VisitorCreateSuccess snackbar notification', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final dummyInvite = PreApprovedInvite(
        id: 1,
        societyId: 1,
        towerId: 1,
        unitId: 501,
        residentId: 202,
        inviteType: 'Guest',
        inviteSubType: 'ONCE',
      );

      visitorStateController.add(VisitorCreateSuccess(invite: dummyInvite));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Invite created successfully!'), findsOneWidget);
    });
  });
}

