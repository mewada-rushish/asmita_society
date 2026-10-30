import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/community/presentation/screens/community_screen.dart';
import 'package:asmita_society/features/community/bloc/community_bloc.dart';
import 'package:asmita_society/features/community/bloc/community_event.dart';
import 'package:asmita_society/features/community/bloc/community_state.dart';
import 'package:asmita_society/features/community/data/models/chat_message_model.dart';
import 'package:asmita_society/features/community/presentation/composer/chat_composer.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockCommunityBloc extends Mock implements CommunityBloc {}

class FakeCommunityEvent extends Fake implements CommunityEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCommunityEvent());
  });

  late MockAuthBloc mockAuthBloc;
  late MockCommunityBloc mockCommunityBloc;
  late StreamController<AuthState> authStateController;
  late StreamController<CommunityState> communityStateController;

  final testUser = UserModel(
    userId: 301,
    fullName: 'Ananya Roy',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  final sampleMessages = [
    const ChatMessageModel(
      id: 'msg_1',
      sender: 'Kavita Singh',
      isMe: false,
      time: 'Today|10:30 AM',
      type: 'text',
      content: 'Water supply maintenance will be held tomorrow between 2-4 PM.',
    ),
    const ChatMessageModel(
      id: 'msg_2',
      sender: 'You',
      isMe: true,
      time: 'Today|10:35 AM',
      type: 'text',
      content: 'Noted, thank you for informing!',
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockCommunityBloc = MockCommunityBloc();
    authStateController = StreamController<AuthState>.broadcast();
    communityStateController = StreamController<CommunityState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockCommunityBloc.stream).thenAnswer((_) => communityStateController.stream);
    when(() => mockCommunityBloc.state).thenReturn(const CommunityLoaded([]));
    when(() => mockCommunityBloc.close()).thenAnswer((_) async {});
    when(() => mockCommunityBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await authStateController.close();
    await communityStateController.close();
  });

  Widget buildTestableWidget({
    CommunityState initialState = const CommunityLoaded([]),
    VoidCallback? onNavigateToSearch,
    VoidCallback? onNavigateToCommunity,
  }) {
    when(() => mockCommunityBloc.state).thenReturn(initialState);
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<CommunityBloc>.value(value: mockCommunityBloc),
      ],
      child: MaterialApp(
        home: CommunityScreen(
          onNavigateToSearch: onNavigateToSearch,
          onNavigateToCommunity: onNavigateToCommunity,
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

  group('CommunityScreen Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator when community state is loading', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(initialState: CommunityLoading()));
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders error view with retry button on CommunityError', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          initialState: const CommunityError('Unable to connect to community server.'),
        ),
      );
      await tester.pump();

      expect(find.text('Unable to connect to community server.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders message list and ChatComposer in CommunityLoaded state', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          initialState: CommunityLoaded(sampleMessages),
        ),
      );
      await tester.pump();

      expect(find.text('Water supply maintenance will be held tomorrow between 2-4 PM.'), findsOneWidget);
      expect(find.text('Noted, thank you for informing!'), findsOneWidget);
      expect(find.byType(ChatComposer), findsOneWidget);
    });

    testWidgets('renders floating message actions bar when selectedMessageIds is not empty', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(
        buildTestableWidget(
          initialState: CommunityLoaded(
            sampleMessages,
            selectedMessageIds: {'msg_1'},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('header search and chat callbacks forward properly', (tester) async {
      setMobileScreen(tester);
      bool searchClicked = false;
      bool chatClicked = false;

      await tester.pumpWidget(
        buildTestableWidget(
          initialState: const CommunityLoaded([]),
          onNavigateToSearch: () => searchClicked = true,
          onNavigateToCommunity: () => chatClicked = true,
        ),
      );
      await tester.pump();

      final searchBtn = find.byIcon(Icons.search_rounded);
      expect(searchBtn, findsOneWidget);
      await tester.tap(searchBtn);
      await tester.pump();
      expect(searchClicked, isTrue);

      final chatBtn = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(chatBtn, findsOneWidget);
      await tester.tap(chatBtn);
      await tester.pump();
      expect(chatClicked, isTrue);
    });
  });
}
