import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/services/presentation/screens/daily_help_screen.dart';
import 'package:asmita_society/features/services/bloc/daily_help_bloc.dart';
import 'package:asmita_society/features/services/bloc/daily_help_event.dart';
import 'package:asmita_society/features/services/bloc/daily_help_state.dart';
import 'package:asmita_society/features/services/data/models/daily_help_model.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockDailyHelpBloc extends Mock implements DailyHelpBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockDailyHelpBloc mockDailyHelpBloc;
  late MockAuthBloc mockAuthBloc;
  late StreamController<DailyHelpState> dailyHelpStateController;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 202,
    fullName: 'Pooja Mehta',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
    societyId: 101,
  );

  final sampleDailyHelp = [
    DailyHelpModel(
      id: 1,
      societyId: 101,
      name: 'Sunita Kamble',
      phone: '9876543210',
      role: 'Maid',
      kycStatus: 'Verified',
      isActive: true,
    ),
    DailyHelpModel(
      id: 2,
      societyId: 101,
      name: 'Raju Yadav',
      phone: '9876543211',
      role: 'Driver',
      kycStatus: 'Pending',
      isActive: true,
    ),
    DailyHelpModel(
      id: 3,
      societyId: 101,
      name: 'Ashok Plumber',
      phone: '9876543212',
      role: 'Plumber',
      kycStatus: 'Approved',
      isActive: true,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const FetchDailyHelp());
    registerFallbackValue(const AddDailyHelp(name: '', phone: '', role: ''));
  });

  setUp(() {
    mockDailyHelpBloc = MockDailyHelpBloc();
    mockAuthBloc = MockAuthBloc();
    dailyHelpStateController = StreamController<DailyHelpState>.broadcast();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockDailyHelpBloc.stream).thenAnswer((_) => dailyHelpStateController.stream);
    when(() => mockDailyHelpBloc.state).thenReturn(
      DailyHelpState(
        status: DailyHelpStatus.loaded,
        dailyHelpList: sampleDailyHelp,
      ),
    );
    when(() => mockDailyHelpBloc.close()).thenAnswer((_) async {});
    when(() => mockDailyHelpBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await dailyHelpStateController.close();
    await authStateController.close();
  });

  Widget buildTestableWidget({
    VoidCallback? onNavigateToSearch,
    VoidCallback? onNavigateToCommunity,
    ValueChanged<int>? onNavigateToTab,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<DailyHelpBloc>.value(value: mockDailyHelpBloc),
      ],
      child: MaterialApp(
        home: DailyHelpScreen(
          onNavigateToSearch: onNavigateToSearch,
          onNavigateToCommunity: onNavigateToCommunity,
          onNavigateToTab: onNavigateToTab,
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

  group('DailyHelpScreen Production Widget Tests', () {
    testWidgets('renders loading indicator when state is loading with empty list', (tester) async {
      setMobileScreen(tester);
      when(() => mockDailyHelpBloc.state).thenReturn(
        const DailyHelpState(status: DailyHelpStatus.loading, dailyHelpList: []),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders error message when state is error with empty list', (tester) async {
      setMobileScreen(tester);
      when(() => mockDailyHelpBloc.state).thenReturn(
        const DailyHelpState(
          status: DailyHelpStatus.error,
          dailyHelpList: [],
          errorMessage: 'Connection timed out',
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Error: Connection timed out'), findsOneWidget);
    });

    testWidgets('renders daily help list with helper names, roles, and verified badges', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Daily Help'), findsOneWidget);
      expect(find.text('Available Staff'), findsOneWidget);
      expect(find.text('Sunita Kamble'), findsOneWidget);
      expect(find.text('Raju Yadav'), findsOneWidget);
      expect(find.text('Ashok Plumber'), findsOneWidget);

      // Sunita and Ashok have Verified/Approved KYC, Raju is Pending
      expect(find.byIcon(Icons.verified_rounded), findsNWidgets(2));
    });

    testWidgets('category filter chips filter providers list accurately', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Tap on 'Maids' chip (index 1)
      final maidChip = find.widgetWithText(ChoiceChip, 'Maids');
      expect(maidChip, findsOneWidget);
      await tester.tap(maidChip, warnIfMissed: false);
      await tester.pump();

      // Only Sunita Kamble should appear
      expect(find.text('Sunita Kamble'), findsOneWidget);
      expect(find.text('Raju Yadav'), findsNothing);
      expect(find.text('Ashok Plumber'), findsNothing);

      // Tap on 'Car Cleaners' chip (index 3) which has no helpers
      final carCleanerChip = find.widgetWithText(ChoiceChip, 'Car Cleaners');
      expect(carCleanerChip, findsOneWidget);
      await tester.tap(carCleanerChip, warnIfMissed: false);
      await tester.pump();

      expect(find.text('No helpers registered in this category.'), findsOneWidget);
    });

    testWidgets('tapping Add Contact opens bottom sheet and displays input fields', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final addBtn = find.text('Add Contact');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Select category'), findsOneWidget);
    });

    testWidgets('header action buttons trigger callbacks', (tester) async {
      setMobileScreen(tester);
      bool searchTriggered = false;
      bool chatTriggered = false;

      await tester.pumpWidget(buildTestableWidget(
        onNavigateToSearch: () => searchTriggered = true,
        onNavigateToCommunity: () => chatTriggered = true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pump();
      expect(searchTriggered, isTrue);

      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pump();
      expect(chatTriggered, isTrue);
    });
  });
}
