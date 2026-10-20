import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/presentation/login_screen.dart';
import 'package:asmita_society/features/auth/presentation/otp_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;

  setUpAll(() {
    registerFallbackValue(const AuthInitiateRequested(mobile: '1234567890'));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildTestableWidget({AuthState? initialState}) {
    if (initialState != null) {
      when(() => mockAuthBloc.state).thenReturn(initialState);
    }
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all static UI elements correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Verify headings and subtitle
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(
        find.text('Please enter your phone number or email address\nand continue my asmita app.'),
        findsOneWidget,
      );
      expect(find.text('Phone Number'), findsOneWidget);

      // Verify country prefix and code
      expect(find.text('🇮🇳'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);

      // Verify Login button
      expect(find.text('Login'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('shows error toast when tapping Login with less than 10 digits', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Enter 5 digits
      final textField = find.byType(TextField);
      await tester.enterText(textField, '98765');
      await tester.pump();

      // Tap Login button
      final loginButton = find.byType(ElevatedButton);
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 350)); // Advance toast animation

      // Verify Toast error message
      expect(find.text('Please enter a valid 10-digit mobile number.'), findsOneWidget);

      // Verify AuthInitiateRequested was NOT added to bloc
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('restricts input to digits and maximum 10 characters', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final textField = find.byType(TextField);
      // Try typing 12 characters including letters and symbols
      await tester.enterText(textField, '98765abc!@4321099');
      await tester.pump();

      // Should only contain the first 10 digits
      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('dispatches AuthInitiateRequested when 10 digits are submitted', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '9876543210');
      await tester.pump();

      final loginButton = find.byType(ElevatedButton);
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump();

      verify(() => mockAuthBloc.add(const AuthInitiateRequested(mobile: '9876543210'))).called(1);
    });

    testWidgets('displays AsmitaLoadingIndicator and disables button during AuthLoading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(initialState: const AuthLoading()));
      await tester.pump();

      // Should show AsmitaLoadingIndicator
      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);

      // ElevatedButton should be disabled (onPressed == null)
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('navigates to OtpScreen and displays success toast on AuthOtpSent', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Emit AuthOtpSent state
      authStateController.add(const AuthOtpSent(mobile: '9876543210'));
      await tester.pump(Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // Complete navigation transition

      // Verify Toast was shown
      expect(find.text('Secure OTP sent to +91 9876543210'), findsOneWidget);

      // Verify OtpScreen is pushed to navigation stack
      expect(find.byType(OtpScreen), findsOneWidget);
    });

    testWidgets('shows error toast when AuthError is emitted', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      const errorMessage = 'Daily OTP limit reached. Please contact gate security.';
      authStateController.add(const AuthError(message: errorMessage));
      await tester.pump(Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // Advance toast animation

      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
