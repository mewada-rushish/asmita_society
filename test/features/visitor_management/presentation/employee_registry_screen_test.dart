import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/employee_registry_screen.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 1,
    mobileNumber: '9800000005',
    fullName: 'Test Receptionist',
    primaryRole: 'Receptionist',
    accountType: 'corporate',
    rolePower: 100,
    roleScope: 'corporate',
    societyId: 115,
    societyName: 'AsmitA House',
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();

    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'Receptionist'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const EmployeeRegistryScreen(),
      ),
    );
  }

  group('EmployeeRegistryScreen KPI Tabs & Responsive Layout Tests', () {
    testWidgets(
      'Renders Pending, In, Out, All KPI metric tabs with squircle icons and BoundedCanvas',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Verify BoundedCanvas is present
        expect(find.byType(BoundedCanvas), findsOneWidget);

        // Verify all 4 tabs are rendered
        expect(find.text('Pending'), findsAtLeastNWidgets(1));
        expect(find.text('In'), findsAtLeastNWidgets(1));
        expect(find.text('Out'), findsAtLeastNWidgets(1));
        expect(find.text('All'), findsAtLeastNWidgets(1));

        // Verify icons for Pending, In, Out, All
        expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
        expect(find.byIcon(Icons.login_rounded), findsOneWidget);
        expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
        expect(find.byIcon(Icons.groups_rounded), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets('Tapping KPI tabs triggers tab selection smoothly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap on 'Pending' tab
      final pendingTabFinder = find.widgetWithText(GestureDetector, 'Pending');
      expect(pendingTabFinder, findsOneWidget);
      await tester.tap(pendingTabFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on 'In' tab
      final inTabFinder = find.widgetWithText(GestureDetector, 'In');
      expect(inTabFinder, findsOneWidget);
      await tester.tap(inTabFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on 'Out' tab
      final outTabFinder = find.widgetWithText(GestureDetector, 'Out');
      expect(outTabFinder, findsOneWidget);
      await tester.tap(outTabFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Tap on 'All' tab
      final allTabFinder = find.widgetWithText(GestureDetector, 'All');
      expect(allTabFinder, findsOneWidget);
      await tester.tap(allTabFinder);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets(
      'Compact width phone (< 360dp) retains full society title without header overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 600 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Title should be present and scaled down cleanly via FittedBox
        expect(find.text('AsmitA House'), findsOneWidget);
        expect(find.text('Staff Registry'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets(
      'Filter button opens slideup bottom sheet with Floors grid and Departments list',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Verify the single filter button is present and dropdowns are removed
        final filterBtnFinder = find.byKey(const Key('employee_registry_filter_btn'));
        expect(filterBtnFinder, findsOneWidget);
        expect(find.text('All Floors'), findsNothing);
        expect(find.text('All Departments'), findsNothing);

        // Tap the filter button to open slideup
        await tester.tap(filterBtnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Verify slideup title and tabs
        expect(find.text('Filter Staff'), findsOneWidget);
        expect(find.text('Floors'), findsOneWidget);
        expect(find.text('Departments'), findsOneWidget);
        expect(find.text('Apply Filters'), findsOneWidget);

        // Switch to Departments tab
        await tester.tap(find.text('Departments'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap Apply Filters to close sheet
        await tester.tap(find.byKey(const Key('apply_staff_filters_btn')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Sheet is closed
        expect(find.text('Filter Staff'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  });
}
