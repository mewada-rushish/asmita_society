import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/views/owner_dashboard_view.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/data/models/visitor_history_item.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_bloc.dart';
import 'package:asmita_society/features/dashboard/bloc/quick_actions/quick_actions_state.dart';
import 'package:asmita_society/features/dashboard/data/models/quick_action_registry.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_event.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/services/bloc/amenities_bloc.dart';
import 'package:asmita_society/features/services/bloc/amenities_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVisitorBloc extends Mock implements VisitorBloc {}
class MockQuickActionsBloc extends Mock implements QuickActionsBloc {}
class MockCommunityPostBloc extends Mock implements CommunityPostBloc {}
class MockAmenitiesBloc extends Mock implements AmenitiesBloc {}
class MockGuardGateBloc extends Mock implements GuardGateBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockVisitorBloc mockVisitorBloc;
  late MockQuickActionsBloc mockQuickActionsBloc;
  late MockCommunityPostBloc mockCommunityPostBloc;
  late MockAmenitiesBloc mockAmenitiesBloc;
  late MockGuardGateBloc mockGuardGateBloc;

  late StreamController<AuthState> authStateController;
  late StreamController<VisitorState> visitorStateController;
  late StreamController<QuickActionsState> quickActionsStateController;
  late StreamController<CommunityPostState> communityPostStateController;
  late StreamController<AmenitiesState> amenitiesStateController;
  late StreamController<GuardGateState> guardGateStateController;

  final testOwnerUser = UserModel(
    userId: 1,
    fullName: 'Rajesh Mehta',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  setUpAll(() {
    registerFallbackValue(const LoadMyHistory(residentId: 1, isRefresh: true));
    registerFallbackValue(LoadQuickActions());
    registerFallbackValue(LoadCommunityPosts());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVisitorBloc = MockVisitorBloc();
    mockQuickActionsBloc = MockQuickActionsBloc();
    mockCommunityPostBloc = MockCommunityPostBloc();
    mockAmenitiesBloc = MockAmenitiesBloc();
    mockGuardGateBloc = MockGuardGateBloc();

    authStateController = StreamController<AuthState>.broadcast();
    visitorStateController = StreamController<VisitorState>.broadcast();
    quickActionsStateController = StreamController<QuickActionsState>.broadcast();
    communityPostStateController = StreamController<CommunityPostState>.broadcast();
    amenitiesStateController = StreamController<AmenitiesState>.broadcast();
    guardGateStateController = StreamController<GuardGateState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testOwnerUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockVisitorBloc.stream).thenAnswer((_) => visitorStateController.stream);
    when(() => mockVisitorBloc.state).thenReturn(const VisitorHistoryLoaded(history: []));
    when(() => mockVisitorBloc.close()).thenAnswer((_) async {});
    when(() => mockVisitorBloc.add(any())).thenReturn(null);

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
    when(() => mockAmenitiesBloc.state).thenReturn(
      const AmenitiesState(status: AmenitiesStatus.loaded),
    );
    when(() => mockAmenitiesBloc.close()).thenAnswer((_) async {});

    when(() => mockGuardGateBloc.stream).thenAnswer((_) => guardGateStateController.stream);
    when(() => mockGuardGateBloc.state).thenReturn(const GuardGateState());
    when(() => mockGuardGateBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
    await visitorStateController.close();
    await quickActionsStateController.close();
    await communityPostStateController.close();
    await amenitiesStateController.close();
    await guardGateStateController.close();
  });

  Widget buildTestableWidget({
    VoidCallback? onNavigateToCommunity,
    VoidCallback? onNavigateToHistory,
    VoidCallback? onNavigateToViewMore,
    VoidCallback? onNavigateToServices,
    VoidCallback? onNavigateToDailyHelp,
    VoidCallback? onNavigateToAllNotices,
    VoidCallback? onNavigateToSearch,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
        BlocProvider<QuickActionsBloc>.value(value: mockQuickActionsBloc),
        BlocProvider<CommunityPostBloc>.value(value: mockCommunityPostBloc),
        BlocProvider<AmenitiesBloc>.value(value: mockAmenitiesBloc),
        BlocProvider<GuardGateBloc>.value(value: mockGuardGateBloc),
      ],
      child: MaterialApp(
        home: OwnerDashboardView(
          onNavigateToCommunity: onNavigateToCommunity,
          onNavigateToHistory: onNavigateToHistory,
          onNavigateToViewMore: onNavigateToViewMore,
          onNavigateToServices: onNavigateToServices,
          onNavigateToDailyHelp: onNavigateToDailyHelp,
          onNavigateToAllNotices: onNavigateToAllNotices,
          onNavigateToSearch: onNavigateToSearch,
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

  group('OwnerDashboardView Production Widget Tests', () {
    testWidgets('renders dynamic user initials and primary header with actions', (tester) async {
      setMobileScreen(tester);
      bool searched = false;
      bool navigatedChat = false;

      await tester.pumpWidget(
        buildTestableWidget(
          onNavigateToSearch: () => searched = true,
          onNavigateToCommunity: () => navigatedChat = true,
        ),
      );
      await tester.pump();

      // Dynamic initials computed from Rajesh Mehta
      expect(find.text('RM'), findsOneWidget);

      // Search button tap
      final searchIcon = find.byIcon(Icons.search_rounded);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      expect(searched, isTrue);

      // Chat button tap
      final chatIcon = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(chatIcon, findsOneWidget);
      await tester.tap(chatIcon);
      expect(navigatedChat, isTrue);
    });

    testWidgets('renders Quick Actions matrix and triggers onNavigateToViewMore', (tester) async {
      setMobileScreen(tester);
      bool viewMoreClicked = false;

      await tester.pumpWidget(
        buildTestableWidget(
          onNavigateToViewMore: () => viewMoreClicked = true,
        ),
      );
      await tester.pump();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Customise'), findsOneWidget);
      expect(find.text('Pre-Approve'), findsOneWidget);
      expect(find.text('View More'), findsOneWidget);

      await tester.tap(find.text('View More'));
      await tester.pump();
      expect(viewMoreClicked, isTrue);
    });

    testWidgets('opens Pre-Approve wizard dialog when Pre-Approve action is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Pre-Approve'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AsmitaDialog), findsOneWidget);
      expect(find.text('Pre-Approve Entry'), findsOneWidget);
    });

    testWidgets('opens Security Alert wizard dialog when Security action is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Security'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AsmitaDialog), findsOneWidget);
      expect(find.text('Security Alert'), findsOneWidget);
    });

    testWidgets('opens Raise Alert wizard dialog when Raise Alert action is tapped', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.text('Raise Alert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AsmitaDialog), findsOneWidget);
      expect(find.text('Raise an Alert'), findsOneWidget);
    });

    testWidgets('renders gate sync updates when available and handles View All navigation', (tester) async {
      setMobileScreen(tester);
      bool historyNavigated = false;

      final now = DateTime.now();
      final todayFormatted = now.toIso8601String();

      final testHistory = [
        {
          'id': 101,
          'visitor_name': 'Amazon Courier',
          'company_name': 'Amazon',
          'record_type': 'PRE_APPROVED',
          'invite_type': 'Delivery',
          'created_at': todayFormatted,
          'is_viewed': true,
          'resident_id': 1,
        },
      ];

      when(() => mockVisitorBloc.state).thenReturn(
        VisitorHistoryLoaded(history: testHistory.map((e) => VisitorHistoryItem.fromJson(e)).toList()),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          onNavigateToHistory: () => historyNavigated = true,
        ),
      );
      await tester.pump();

      expect(find.text("Today's Entry Updates"), findsOneWidget);
      expect(find.text('Amazon'), findsOneWidget);

      // Tap View All
      await tester.tap(find.text('View All').first);
      await tester.pump();
      expect(historyNavigated, isTrue);
    });

    testWidgets('renders empty gate sync updates message when no updates today', (tester) async {
      setMobileScreen(tester);
      when(() => mockVisitorBloc.state).thenReturn(
        const VisitorHistoryLoaded(history: []),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text("Today's Entry Updates"), findsOneWidget);
      expect(find.text('You have no new updates'), findsOneWidget);
    });
  });
}
