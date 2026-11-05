import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/menu/presentation/screens/menu_screen.dart';
import 'package:asmita_society/features/dashboard/presentation/views/employee_dashboard_view.dart';
import 'package:asmita_society/features/dashboard/presentation/screens/industrial_directory_screen.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockIndustrialVisitBloc mockVisitBloc;
  late StreamController<AuthState> authStateController;
  late StreamController<IndustrialVisitState> visitStateController;

  final directorUser = UserModel(
    userId: 1,
    mobileNumber: '9876543210',
    fullName: 'Jane Director',
    primaryRole: 'Director',
    accountType: 'corporate',
    rolePower: 500,
    roleScope: 'corporate',
    societyId: 114,
    societyName: 'AsmitA House',
    roleDetails: const {
      'department_id': 1,
      'department_name': 'Executive Management',
      'is_hod': false,
    },
  );

  final employeeUser = UserModel(
    userId: 2,
    mobileNumber: '9876543211',
    fullName: 'Bob Employee',
    primaryRole: 'Corporate Employee',
    accountType: 'corporate',
    rolePower: 100,
    roleScope: 'corporate',
    societyId: 114,
    societyName: 'AsmitA House',
    roleDetails: const {
      'department_id': 3,
      'department_name': 'Accounts',
      'is_hod': false,
    },
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVisitBloc = MockIndustrialVisitBloc();
    authStateController = StreamController<AuthState>.broadcast();
    visitStateController = StreamController<IndustrialVisitState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(
      user: directorUser,
      sessionRole: 'Director',
    ));
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockVisitBloc.stream).thenAnswer((_) => visitStateController.stream);
    when(() => mockVisitBloc.state).thenReturn(const IndustrialVisitState());
    when(() => mockVisitBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
    await visitStateController.close();
  });

  Widget wrapWithBlocs(Widget child, {UserModel? user}) {
    final authState = user != null
        ? AuthAuthenticated(user: user, sessionRole: user.primaryRole)
        : AuthAuthenticated(user: directorUser, sessionRole: 'Director');
    when(() => mockAuthBloc.state).thenReturn(authState);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<IndustrialVisitBloc>.value(value: mockVisitBloc),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Milestone 4: Dashboard Entry Points for Invite Team Member', () {
    testWidgets('MenuScreen renders Invite Team right below Department Delegation for Director', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithBlocs(
          const MenuScreen(userRole: 'Director'),
          user: directorUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Department Delegation'), findsOneWidget);
      expect(find.text('Invite Team'), findsOneWidget);
      expect(find.byIcon(Icons.group_add_rounded), findsOneWidget);
    });

    testWidgets('EmployeeDashboardView renders Invite Team for HOD designation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithBlocs(
          EmployeeDashboardView(
            designation: 'Head of Department (HOD)',
            visits: const <IndustrialVisitModel>[],
            onOpenDelegation: () {},
          ),
          user: directorUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invite Team'), findsOneWidget);
      expect(find.byIcon(Icons.group_add_rounded), findsOneWidget);
    });

    testWidgets('EmployeeDashboardView hides Invite Team for standard employee without delegation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithBlocs(
          EmployeeDashboardView(
            designation: 'Junior Associate',
            canDelegate: false,
            visits: const <IndustrialVisitModel>[],
            onOpenDelegation: () {},
          ),
          user: employeeUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invite Team'), findsNothing);
    });

    testWidgets('IndustrialDirectoryScreen renders Invite Team Member card and header pill', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final directorNoSociety = UserModel(
        userId: 1,
        mobileNumber: '9876543210',
        fullName: 'Jane Director',
        primaryRole: 'Director',
        accountType: 'corporate',
        rolePower: 500,
        roleScope: 'corporate',
        societyId: null,
        societyName: null,
      );

      await tester.pumpWidget(
        wrapWithBlocs(
          const IndustrialDirectoryScreen(),
          user: directorNoSociety,
        ),
      );
      await tester.pump();

      expect(find.text('Invite Team Member'), findsOneWidget);
      expect(find.text('Invite Member'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsAtLeastNWidgets(1));
    });
  });
}
