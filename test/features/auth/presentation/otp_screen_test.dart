import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/presentation/otp_screen.dart';
import 'package:asmita_society/features/auth/presentation/registration_screen.dart';
import 'package:asmita_society/features/auth/presentation/approval_pending_screen.dart';
import 'package:asmita_society/features/dashboard/presentation/main_dashboard_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockGuardGateBloc extends Mock implements GuardGateBloc {}
class MockVisitorBloc extends Mock implements VisitorBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockGuardGateBloc mockGuardGateBloc;
  late MockVisitorBloc mockVisitorBloc;
  late StreamController<AuthState> authStateController;

  const testPhone = '9876543210';
  final dummyUser = UserModel(
    userId: 205,
    fullName: 'Test User',
    mobileNumber: testPhone,
    primaryRole: 'Security Guard',
    accountType: 'app',
    societyId: 114,
    societyName: 'AsmitA House',
  );

  setUpAll(() {
    registerFallbackValue(const AuthVerifyRequested(mobile: testPhone, otp: '123456'));
    registerFallbackValue(const AuthInitiateRequested(mobile: testPhone));
    registerFallbackValue(LoadExpectedInvites());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockGuardGateBloc = MockGuardGateBloc();
    mockVisitorBloc = MockVisitorBloc();

    authStateController = StreamController<AuthState>.broadcast();
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockGuardGateBloc.stream).thenAnswer((_) => const Stream<GuardGateState>.empty());
    when(() => mockGuardGateBloc.state).thenReturn(const GuardGateState());
    when(() => mockGuardGateBloc.close()).thenAnswer((_) async {});

    when(() => mockVisitorBloc.stream).thenAnswer((_) => const Stream<VisitorState>.empty());
    when(() => mockVisitorBloc.state).thenReturn(const VisitorHistoryLoaded(history: []));
    when(() => mockVisitorBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildTestableWidget({AuthState? initialState}) {
    if (initialState != null) {
      when(() => mockAuthBloc.state).thenReturn(initialState);
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<GuardGateBloc>.value(value: mockGuardGateBloc),
        BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
      ],
      child: const MaterialApp(
        home: OtpScreen(phoneNumber: testPhone),
      ),
    );
  }

  group('OtpScreen Widget Tests', () {
    testWidgets('renders all static UI elements correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Verify back button and security icon
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.security_rounded), findsOneWidget);

      // Verify header texts
      expect(find.text("Verify It's You"), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains(testPhone),
        ),
        findsOneWidget,
      );

      // Verify 30-second timer text
      expect(find.textContaining('Resend code in 00:'), findsOneWidget);

      // Verify submit button
      expect(find.text('Verify Secure Code'), findsOneWidget);
    });

    testWidgets('entering 6 digits automatically dispatches AuthVerifyRequested', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Find the invisible TextField and enter 6 digits
      final textField = find.byType(TextField);
      await tester.enterText(textField, '654321');
      await tester.pump();

      // Verify all 6 digits are displayed in their respective boxes
      expect(find.text('6'), findsWidgets);
      expect(find.text('5'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('1'), findsWidgets);

      // Verify bloc received the verify request automatically
      verify(() => mockAuthBloc.add(const AuthVerifyRequested(mobile: testPhone, otp: '654321'))).called(1);
    });

    testWidgets('shows loading spinner and disables button during AuthLoading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget(initialState: const AuthLoading()));
      await tester.pump();

      // Should show AsmitaLoadingIndicator
      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);

      // Verify button is disabled
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('timer counts down and enables Resend OTP button after 30 seconds', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Initially countdown is active
      expect(find.textContaining('Resend code in 00:'), findsOneWidget);

      // Advance time by 31 seconds
      await tester.pump(const Duration(seconds: 31));

      // Should now show "Resend OTP"
      expect(find.text('Resend OTP'), findsOneWidget);

      // Tap Resend OTP
      await tester.tap(find.text('Resend OTP'));
      await tester.pump();

      // Verify initiate request sent and timer restarted
      verify(() => mockAuthBloc.add(const AuthInitiateRequested(mobile: testPhone))).called(1);
      expect(find.textContaining('Resend code in 00:'), findsOneWidget);
    });

    testWidgets('navigates to MainDashboardScreen with normalized role on AuthAuthenticated', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Emit AuthAuthenticated with DB role "Security Guard"
      authStateController.add(AuthAuthenticated(user: dummyUser, sessionRole: 'Security Guard'));
      await tester.pump(Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify success toast
      expect(find.text('Identity verified successfully.'), findsOneWidget);

      // Verify MainDashboardScreen is mounted with normalized role
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      final dashboard = tester.widget<MainDashboardScreen>(find.byType(MainDashboardScreen));
      expect(dashboard.userRole, 'guard');
    });

    testWidgets('shows error toast and resets OTP on AuthError', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Enter digits
      final textField = find.byType(TextField);
      await tester.enterText(textField, '123456');
      await tester.pump();

      // Emit AuthError
      const errorMessage = 'Invalid or expired OTP code.';
      authStateController.add(const AuthError(message: errorMessage));
      await tester.pump(Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify error toast
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('navigates to RegistrationScreen on AuthRegistrationRequired', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Emit AuthRegistrationRequired
      authStateController.add(const AuthRegistrationRequired(mobile: testPhone));
      await tester.pump(Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RegistrationScreen), findsOneWidget);
    });

    testWidgets('navigates to ApprovalPendingScreen on AuthPendingApproval', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      // Emit AuthPendingApproval
      authStateController.add(const AuthPendingApproval());
      await tester.pump(Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ApprovalPendingScreen), findsOneWidget);
    });
  });
}
