import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/dashboard/presentation/views/receptionist_dashboard_view.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/receptionist_lobby_updates_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/employee_registry_screen.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockIndustrialVisitBloc mockVisitBloc;

  setUpAll(() {
    registerFallbackValue(const LoadIndustrialVisits());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVisitBloc = MockIndustrialVisitBloc();

    when(() => mockVisitBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockVisitBloc.state).thenReturn(const IndustrialVisitState());
    when(() => mockVisitBloc.close()).thenAnswer((_) async {});
  });

  Widget buildTestableWidget({
    required UserModel user,
  }) {
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user, sessionRole: user.primaryRole));
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => Stream.value(AuthAuthenticated(user: user, sessionRole: user.primaryRole)),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<IndustrialVisitBloc>.value(value: mockVisitBloc),
      ],
      child: const MaterialApp(
        home: ReceptionistDashboardView(
          visits: [],
          initialIsOnDuty: true,
        ),
      ),
    );
  }

  testWidgets('Property Receptionist sees embedded Staff Registry and Lobby & Alerts quick action', (tester) async {
    final propertyUser = UserModel(
      userId: 272,
      fullName: 'Test Receptionist',
      primaryRole: 'Gate Receptionist',
      accountType: 'INDUSTRIAL_STAFF',
      societyId: 1,
      roleDetails: {
        'designation': 'Gate Receptionist',
        'desk_code': 'GR-D01',
      },
    );

    await tester.pumpWidget(buildTestableWidget(user: propertyUser));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Quick Action #3 is 'Lobby & Alerts'
    expect(find.text('Lobby & Alerts'), findsOneWidget);
    expect(find.byIcon(Icons.meeting_room_rounded), findsOneWidget);

    // Verify embedded Staff Registry is present on dashboard
    expect(find.byType(EmployeeRegistryScreen), findsOneWidget);

    // Tap 'Lobby & Alerts' quick action to navigate to ReceptionistLobbyUpdatesScreen
    await tester.tap(find.text('Lobby & Alerts'));
    await tester.pumpAndSettle();

    // Verify ReceptionistLobbyUpdatesScreen opened with header and tabs
    expect(find.byType(ReceptionistLobbyUpdatesScreen), findsOneWidget);
    expect(find.text('Lobby & Floor Updates'), findsOneWidget);
    expect(find.text('Lobby Waiting (0)'), findsOneWidget);
    expect(find.text('Floor Alerts (0)'), findsOneWidget);
    expect(find.text('Lobby is All Clear'), findsOneWidget);
  });

  testWidgets('Floor Receptionist sees Staff Registry quick action and Lobby/Floor tabs on dashboard', (tester) async {
    final floorUser = UserModel(
      userId: 266,
      fullName: 'Shanti Sailoni',
      primaryRole: 'Floor Receptionist',
      accountType: 'INDUSTRIAL_STAFF',
      societyId: 1,
      roleDetails: {
        'designation': 'Floor Receptionist',
        'floor': '1',
      },
    );

    await tester.pumpWidget(buildTestableWidget(user: floorUser));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Quick Action #3 is 'Staff Registry' for Floor Receptionist
    expect(find.text('Staff Registry'), findsOneWidget);
    expect(find.byIcon(Icons.badge_rounded), findsOneWidget);

    // Verify Lobby Waiting and Floor Alerts tabs are shown directly on dashboard
    expect(find.text('Lobby Waiting (0)'), findsOneWidget);
    expect(find.text('Floor Alerts (0)'), findsOneWidget);

    // Verify embedded EmployeeRegistryScreen is NOT rendered on dashboard
    expect(find.byType(EmployeeRegistryScreen), findsNothing);
  });
}
