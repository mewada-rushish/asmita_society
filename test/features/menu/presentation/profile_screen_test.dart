import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/menu/presentation/screens/profile_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 601,
    fullName: 'Aditi Deshmukh',
    primaryRole: 'owner',
    emailId: 'aditi.deshmukh@example.com',
    mobileNumber: '+91 9876543210',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  setUpAll(() {
    registerFallbackValue(
      const AuthUpdateProfileRequested(
        fullName: 'Aditi Deshmukh',
        email: 'aditi.deshmukh@example.com',
        mobile: '+91 9876543210',
      ),
    );
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildTestableWidget() {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ProfileScreen Production Widget Tests', () {
    testWidgets('renders user avatar initials, full name, and role badge', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget); // Initials for Aditi Deshmukh
      expect(find.text('Aditi Deshmukh'), findsNWidgets(2)); // Header + Details row
      expect(find.text('OWNER'), findsOneWidget);
    });

    testWidgets('displays read-only profile details in default view mode', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('aditi.deshmukh@example.com'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('Save Profile'), findsNothing);
    });

    testWidgets('toggling edit mode presents text fields and Save Profile button', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final editIcon = find.byIcon(Icons.edit_outlined);
      expect(editIcon, findsOneWidget);

      await tester.tap(editIcon);
      await tester.pump();

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Save Profile'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('cancelling edit mode restores view mode and hides Save Profile button', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(find.text('Save Profile'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('Save Profile'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows validation snackbar if name or phone is empty on save', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      // Clear full name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '');
      await tester.pump();

      await tester.tap(find.text('Save Profile'));
      await tester.pump();

      expect(find.text('Name and Phone are required'), findsOneWidget);
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('submitting valid edited profile dispatches AuthUpdateProfileRequested', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Aditi D. Roy');
      await tester.pump();

      await tester.tap(find.text('Save Profile'));
      await tester.pump();

      verify(() => mockAuthBloc.add(any(that: isA<AuthUpdateProfileRequested>()))).called(1);
    });
  });
}
