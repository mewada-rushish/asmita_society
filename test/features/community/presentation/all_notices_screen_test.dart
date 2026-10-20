import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/community/presentation/screens/all_notices_screen.dart';
import 'package:asmita_society/features/community/bloc/community_post_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_post_event.dart';
import 'package:asmita_society/features/community/bloc/community_post_state.dart';
import 'package:asmita_society/features/community/data/models/community_post_model.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:asmita_society/l10n/app_localizations.dart';

class MockCommunityPostBloc extends Mock implements CommunityPostBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockCommunityPostBloc mockCommunityPostBloc;
  late MockAuthBloc mockAuthBloc;
  late StreamController<CommunityPostState> stateController;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 101,
    fullName: 'Rushish Mewada',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
    societyId: 1,
  );

  final samplePosts = [
    CommunityPostModel(
      id: 'post-1',
      title: 'Water Supply Maintenance',
      contentJson: 'Scheduled pipeline servicing on Friday from 10 AM to 2 PM.',
      authorName: 'Society Management',
      status: 'approved',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityPostModel(
      id: 'post-2',
      title: 'Diwali Celebration & Fireworks Guidelines',
      contentJson: 'All residents are requested to burst firecrackers only in designated playground areas.',
      authorName: 'Cultural Committee',
      status: 'approved',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(LoadCommunityPosts());
    registerFallbackValue(const DeleteCommunityPost(''));
  });

  setUp(() {
    mockCommunityPostBloc = MockCommunityPostBloc();
    mockAuthBloc = MockAuthBloc();
    stateController = StreamController<CommunityPostState>.broadcast();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockCommunityPostBloc.stream).thenAnswer((_) => stateController.stream);
    when(() => mockCommunityPostBloc.state).thenReturn(
      CommunityPostState(status: CommunityPostStatus.loaded, posts: samplePosts),
    );
    when(() => mockCommunityPostBloc.close()).thenAnswer((_) async {});
    when(() => mockCommunityPostBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await stateController.close();
    await authStateController.close();
  });

  Widget buildTestableWidget({
    ValueChanged<int>? onNavigateToTab,
    VoidCallback? onNavigateToCommunity,
    VoidCallback? onNavigateToSearch,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<CommunityPostBloc>.value(value: mockCommunityPostBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AllNoticesScreen(
          onNavigateToTab: onNavigateToTab,
          onNavigateToCommunity: onNavigateToCommunity,
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

  group('AllNoticesScreen Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator when status is loading', (tester) async {
      setMobileScreen(tester);
      when(() => mockCommunityPostBloc.state).thenReturn(
        const CommunityPostState(status: CommunityPostStatus.loading, posts: []),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders error text when status is error', (tester) async {
      setMobileScreen(tester);
      when(() => mockCommunityPostBloc.state).thenReturn(
        const CommunityPostState(status: CommunityPostStatus.error, posts: []),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Failed to load notices.'), findsOneWidget);
    });

    testWidgets('renders empty state text when active posts list is empty', (tester) async {
      setMobileScreen(tester);
      when(() => mockCommunityPostBloc.state).thenReturn(
        const CommunityPostState(status: CommunityPostStatus.loaded, posts: []),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('No active notices right now.'), findsOneWidget);
    });

    testWidgets('renders community post cards with titles and authors', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Community Posts'), findsOneWidget);
      expect(find.text('Water Supply Maintenance'), findsOneWidget);
      expect(find.text('Diwali Celebration & Fireworks Guidelines'), findsOneWidget);
      expect(find.text('New Post'), findsOneWidget);
    });

    testWidgets('tapping New Post button opens bottom sheet modal', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final newPostBtn = find.text('New Post');
      expect(newPostBtn, findsOneWidget);

      await tester.tap(newPostBtn);
      await tester.pumpAndSettle();

      expect(find.text('New Community Post'), findsOneWidget);
    });

    testWidgets('header action callbacks fire when tapped', (tester) async {
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

    testWidgets('tapping bottom navigation tab invokes onNavigateToTab', (tester) async {
      setMobileScreen(tester);
      int? selectedTab;

      await tester.pumpWidget(buildTestableWidget(
        onNavigateToTab: (index) => selectedTab = index,
      ));
      await tester.pump();

      // Tap on More tab (index 4) in BottomNavBar
      final moreIcon = find.byIcon(Icons.more_horiz_rounded);
      expect(moreIcon, findsOneWidget);
      await tester.tap(moreIcon);
      await tester.pump();

      expect(selectedTab, 4);
    });
  });
}
