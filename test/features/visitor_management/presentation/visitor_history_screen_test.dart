import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/visitor_history_screen.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/data/models/visitor_history_item.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockVisitorBloc extends Mock implements VisitorBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockVisitorBloc mockVisitorBloc;
  late MockAuthBloc mockAuthBloc;
  late StreamController<VisitorState> visitorStateController;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 101,
    fullName: 'Rushish Mewada',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  final sampleHistoryItems = [
    {
      'id': 1,
      'record_type': 'PRE_APPROVED',
      'visitor_name': 'Rahul Sharma',
      'company_name': 'Zomato',
      'invite_type': 'Delivery',
      'created_at': '2026-10-20T14:30:00Z',
      'start_time': '14:30',
      'end_time': '15:00',
      'status': 'APPROVED',
      'vehicle_number': 'MH04AB1234',
    },
    {
      'id': 2,
      'record_type': 'GATE_ENTRY',
      'visitor_name': 'Dr. Patel',
      'company_name': 'Guest',
      'visitor_type_name': 'Guest',
      'created_at': '2026-10-20T10:15:00Z',
      'checkin_at': '10:15',
      'status': 'CHECKED_IN',
    },
  ];

  setUpAll(() {
    registerFallbackValue(const LoadMyHistory(residentId: 101));
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
    when(() => mockVisitorBloc.state).thenReturn(
      VisitorHistoryLoaded(history: sampleHistoryItems.map((e) => VisitorHistoryItem.fromJson(e)).toList()),
    );
    when(() => mockVisitorBloc.close()).thenAnswer((_) async {});
    when(() => mockVisitorBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await visitorStateController.close();
    await authStateController.close();
  });

  Widget buildTestableWidget({
    VoidCallback? onBack,
    String? filterCategory,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
      ],
      child: MaterialApp(
        home: VisitorHistoryScreen(
          onBack: onBack,
          filterCategory: filterCategory,
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

  group('VisitorHistoryScreen Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator when VisitorLoading state is active', (tester) async {
      setMobileScreen(tester);
      when(() => mockVisitorBloc.state).thenReturn(VisitorLoading());

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders empty state message when VisitorHistoryLoaded has no items', (tester) async {
      setMobileScreen(tester);
      when(() => mockVisitorBloc.state).thenReturn(
        const VisitorHistoryLoaded(history: []),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('No visitor history found'), findsOneWidget);
    });

    testWidgets('renders visitor history cards with correct titles, badges and entry times', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Visitor History'), findsOneWidget);
      // Normalized Delivery item title uses company name 'Zomato'
      expect(find.text('Zomato'), findsOneWidget);
      // Normalized Gate Entry uses visitor name 'Dr. Patel'
      expect(find.text('Dr. Patel'), findsOneWidget);
      expect(find.text('Pre-approved by Rushish Mewada'), findsNothing); // Modal text
      expect(find.text('by Rushish Mewada'), findsOneWidget); // Card subtitle text
      expect(find.text('Entered via Main Gate'), findsOneWidget);
    });

    testWidgets('renders error view with retry button when VisitorError state occurs', (tester) async {
      setMobileScreen(tester);
      when(() => mockVisitorBloc.state).thenReturn(
        const VisitorError(message: 'Network connection failed. Please retry.'),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Network connection failed. Please retry.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => mockVisitorBloc.add(any(that: isA<LoadMyHistory>()))).called(greaterThanOrEqualTo(1));
    });

    testWidgets('tapping filter button opens Filter History bottom sheet', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final filterIcon = find.byIcon(Icons.filter_list_rounded);
      expect(filterIcon, findsOneWidget);

      await tester.tap(filterIcon);
      await tester.pumpAndSettle();

      expect(find.text('Filter History'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
    });

    testWidgets('tapping a visitor card opens detailed visitor bottom sheet', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Tap on the Zomato card
      await tester.tap(find.text('Zomato'));
      await tester.pumpAndSettle();

      expect(find.text('Gate Access Status'), findsOneWidget);
      expect(find.text('Arrival Date'), findsOneWidget);
      expect(find.text('Entry Boundary Check'), findsOneWidget);
      expect(find.text('Pre-Approved'), findsOneWidget);
      expect(find.text('Inbound Timestamp'), findsOneWidget);
      expect(find.text('Vehicle Number'), findsOneWidget);
      expect(find.text('MH04AB1234'), findsOneWidget);
    });

    testWidgets('tapping onBack calls callback cleanly', (tester) async {
      setMobileScreen(tester);
      bool backCalled = false;
      await tester.pumpWidget(buildTestableWidget(onBack: () => backCalled = true));
      await tester.pump();

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();

      expect(backCalled, isTrue);
    });

    testWidgets('filterCategory prop filters list correctly', (tester) async {
      setMobileScreen(tester);
      // Filter by 'Delivery' should show Zomato but hide Dr. Patel (Guest)
      await tester.pumpWidget(buildTestableWidget(filterCategory: 'Delivery'));
      await tester.pump();

      expect(find.text('Zomato'), findsOneWidget);
      expect(find.text('Dr. Patel'), findsNothing);
    });
  });
}
