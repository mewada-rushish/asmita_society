import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shimmer/shimmer.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/department_delegation_screen.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 101,
    mobileNumber: '9988776655',
    fullName: 'David HOD',
    primaryRole: 'Corporate Employee',
    accountType: 'corporate',
    rolePower: 200,
    roleScope: 'corporate',
    societyId: 114,
    societyName: 'AsmitA House',
    roleDetails: const {
      'department_id': 5,
      'department_name': 'Engineering',
      'is_hod': true,
    },
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(
      user: testUser,
      sessionRole: 'Corporate Employee',
    ));
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  testWidgets('DepartmentDelegationScreen renders skeletal loading while fetching', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: const MaterialApp(
          home: DepartmentDelegationScreen(
            departmentId: 5,
            departmentName: 'Engineering',
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify toggle is present
    expect(find.text('Enable Out-of-Office Delegation'), findsOneWidget);

    // Verify switch is present
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    // Toggle switch ON
    await tester.tap(switchFinder);
    await tester.pump();

    // Verify delegation is toggled on
    expect(find.text('Delegation is currently ACTIVE'), findsOneWidget);

    // While loading, skeletal shimmering widgets are rendered
    expect(find.byType(Shimmer), findsWidgets);

    // Allow timers to complete gracefully
    await tester.pump(const Duration(seconds: 1));
  });
}
