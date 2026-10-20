import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/dashboard/presentation/main_dashboard_screen.dart';
import 'package:asmita_society/features/dashboard/presentation/views/owner_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/tenant_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/guard_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/director_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/employee_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/receptionist_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/views/facility_staff_dashboard_view.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
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
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';

import 'package:asmita_society/features/community/presentation/providers/community_provider.dart';
import 'package:asmita_society/features/community/bloc/community_state.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVisitorBloc extends Mock implements VisitorBloc {}
class MockQuickActionsBloc extends Mock implements QuickActionsBloc {}
class MockCommunityPostBloc extends Mock implements CommunityPostBloc {}
class MockAmenitiesBloc extends Mock implements AmenitiesBloc {}
class MockGuardGateBloc extends Mock implements GuardGateBloc {}
class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}

class FakeCommunityNotifier extends CommunityNotifier {
  @override
  CommunityState build() {
    return const CommunityLoaded([]);
  }

  @override
  Future<void> loadMessages({int? currentUserId, String? currentUserName, bool isRefresh = false}) async {}

  @override
  void startPolling({bool Function()? isAtBottom}) {}

  @override
  void stopPolling() {}
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockVisitorBloc mockVisitorBloc;
  late MockQuickActionsBloc mockQuickActionsBloc;
  late MockCommunityPostBloc mockCommunityPostBloc;
  late MockAmenitiesBloc mockAmenitiesBloc;
  late MockGuardGateBloc mockGuardGateBloc;
  late MockIndustrialVisitBloc mockIndustrialVisitBloc;

  late StreamController<AuthState> authStateController;
  late StreamController<VisitorState> visitorStateController;
  late StreamController<QuickActionsState> quickActionsStateController;
  late StreamController<CommunityPostState> communityPostStateController;
  late StreamController<AmenitiesState> amenitiesStateController;
  late StreamController<GuardGateState> guardGateStateController;
  late StreamController<IndustrialVisitState> industrialVisitStateController;

  final testUser = UserModel(
    userId: 1,
    fullName: 'Test User',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  setUpAll(() {
    registerFallbackValue(const LoadMyHistory(residentId: 1, isRefresh: true));
    registerFallbackValue(LoadQuickActions());
    registerFallbackValue(LoadCommunityPosts());
    registerFallbackValue(const LoadIndustrialVisits());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVisitorBloc = MockVisitorBloc();
    mockQuickActionsBloc = MockQuickActionsBloc();
    mockCommunityPostBloc = MockCommunityPostBloc();
    mockAmenitiesBloc = MockAmenitiesBloc();
    mockGuardGateBloc = MockGuardGateBloc();
    mockIndustrialVisitBloc = MockIndustrialVisitBloc();

    authStateController = StreamController<AuthState>.broadcast();
    visitorStateController = StreamController<VisitorState>.broadcast();
    quickActionsStateController = StreamController<QuickActionsState>.broadcast();
    communityPostStateController = StreamController<CommunityPostState>.broadcast();
    amenitiesStateController = StreamController<AmenitiesState>.broadcast();
    guardGateStateController = StreamController<GuardGateState>.broadcast();
    industrialVisitStateController = StreamController<IndustrialVisitState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
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

    when(() => mockIndustrialVisitBloc.stream).thenAnswer((_) => industrialVisitStateController.stream);
    when(() => mockIndustrialVisitBloc.state).thenReturn(const IndustrialVisitState());
    when(() => mockIndustrialVisitBloc.close()).thenAnswer((_) async {});
    when(() => mockIndustrialVisitBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await authStateController.close();
    await visitorStateController.close();
    await quickActionsStateController.close();
    await communityPostStateController.close();
    await amenitiesStateController.close();
    await guardGateStateController.close();
    await industrialVisitStateController.close();
  });

  Widget buildTestableWidget(String userRole) {
    return ProviderScope(
      overrides: [
        communityProvider.overrideWith(() => FakeCommunityNotifier()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
          BlocProvider<QuickActionsBloc>.value(value: mockQuickActionsBloc),
          BlocProvider<CommunityPostBloc>.value(value: mockCommunityPostBloc),
          BlocProvider<AmenitiesBloc>.value(value: mockAmenitiesBloc),
          BlocProvider<GuardGateBloc>.value(value: mockGuardGateBloc),
          BlocProvider<IndustrialVisitBloc>.value(value: mockIndustrialVisitBloc),
        ],
        child: MaterialApp(
          home: MainDashboardScreen(userRole: userRole),
        ),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async => await tester.pumpWidget(const SizedBox()));
  }

  group('MainDashboardScreen Universal Routing & Architecture Widget Tests', () {
    testWidgets('renders OwnerDashboardView for owner role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('owner'));
      await tester.pump();

      expect(find.byType(OwnerDashboardView), findsOneWidget);
    });

    testWidgets('renders TenantDashboardView for tenant role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('tenant'));
      await tester.pump();

      expect(find.byType(TenantDashboardView), findsOneWidget);
    });

    testWidgets('renders GuardDashboardView for guard role and custom security role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('security_guard'));
      await tester.pump();

      expect(find.byType(GuardDashboardView), findsOneWidget);
    });

    testWidgets('renders DirectorDashboardView for director role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('director'));
      await tester.pump();

      expect(find.byType(DirectorDashboardView), findsOneWidget);
    });

    testWidgets('renders EmployeeDashboardView for employee/host role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('employee'));
      await tester.pump();

      expect(find.byType(EmployeeDashboardView), findsOneWidget);
    });

    testWidgets('renders ReceptionistDashboardView for receptionist role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('receptionist'));
      await tester.pump();

      expect(find.byType(ReceptionistDashboardView), findsOneWidget);
    });

    testWidgets('renders FacilityStaffDashboardView for facility role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('facility'));
      await tester.pump();

      expect(find.byType(FacilityStaffDashboardView), findsOneWidget);
    });
  });
}
