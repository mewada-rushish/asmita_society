import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/presentation/registration_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/repositories/auth_repository.dart';
import 'package:asmita_society/features/auth/data/repositories/property_repository.dart';
import 'package:asmita_society/features/auth/data/models/invite_token_info.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockPropertyRepository extends Mock implements PropertyRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late MockAuthRepository mockAuthRepository;
  late MockPropertyRepository mockPropertyRepository;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockAuthRepository = MockAuthRepository();
    mockPropertyRepository = MockPropertyRepository();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockPropertyRepository.getSocieties()).thenAnswer((_) async => []);
  });

  tearDown(() {
    authStateController.close();
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: child,
      ),
    );
  }

  group('RegistrationScreen Invite Resolution & Auto-fill', () {
    testWidgets('resolves invite token and locks society, department, and role', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const inviteToken = 'test_token_123';
      const tokenInfo = InviteTokenInfo(
        success: true,
        societyId: 114,
        societyName: 'AsmitA House',
        targetRole: 'Corporate Employee',
        departmentId: 3,
        departmentName: 'Accounts',
        recipientPhone: '9876543210',
        recipientName: 'John Doe',
      );

      when(() => mockAuthRepository.getInviteTokenInfo(inviteToken))
          .thenAnswer((_) async => tokenInfo);

      await tester.pumpWidget(
        buildTestWidget(
          RegistrationScreen(
            inviteToken: inviteToken,
            authRepository: mockAuthRepository,
            propertyRepository: mockPropertyRepository,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAuthRepository.getInviteTokenInfo(inviteToken)).called(1);

      // Verify "Verified Invitation" banner is displayed
      expect(find.text('Verified Invitation'), findsOneWidget);

      // Verify Society is pre-filled and locked
      expect(find.text('AsmitA House'), findsOneWidget);

      // Verify Department is pre-filled and displayed
      expect(find.text('Accounts'), findsOneWidget);

      // Verify Workplace is displayed as Corporate Campus
      expect(find.text('Corporate Campus'), findsOneWidget);

      // Verify Role is locked to Corporate Employee
      expect(find.text('Corporate Employee'), findsOneWidget);

      // Verify residential hierarchy (Tower, Floor, Flat) is NOT displayed in corporate mode
      expect(find.text('Select Tower'), findsNothing);
      expect(find.text('Select Floor'), findsNothing);
      expect(find.text('Select Flat'), findsNothing);
    });

    testWidgets('corporate invite proceeds to Step 2 without residential hierarchy', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const inviteToken = 'corp_token';
      const tokenInfo = InviteTokenInfo(
        success: true,
        societyId: 114,
        societyName: 'AsmitA House',
        targetRole: 'Corporate Employee',
        departmentId: 3,
        departmentName: 'Accounts',
        recipientPhone: '9876543210',
        recipientName: 'Jane Smith',
      );

      when(() => mockAuthRepository.getInviteTokenInfo(inviteToken))
          .thenAnswer((_) async => tokenInfo);

      await tester.pumpWidget(
        buildTestWidget(
          RegistrationScreen(
            inviteToken: inviteToken,
            authRepository: mockAuthRepository,
            propertyRepository: mockPropertyRepository,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Next button to proceed to Step 2
      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Step 2 should be active (Personal Details)
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Step 2 of 2'), findsOneWidget);

      // Pre-filled recipient name and recipient phone should be present
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Phone number should show "Verified" lock indicator
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('unspecified recipient phone allows manual 10-digit mobile entry in Step 2', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const inviteToken = 'unspecified_phone_token';
      const tokenInfo = InviteTokenInfo(
        success: true,
        societyId: 114,
        societyName: 'AsmitA House',
        targetRole: 'Corporate Employee',
        departmentId: 3,
        departmentName: 'Accounts',
        recipientPhone: null, // No pre-specified phone
        recipientName: null,
      );

      when(() => mockAuthRepository.getInviteTokenInfo(inviteToken))
          .thenAnswer((_) async => tokenInfo);

      await tester.pumpWidget(
        buildTestWidget(
          RegistrationScreen(
            inviteToken: inviteToken,
            authRepository: mockAuthRepository,
            propertyRepository: mockPropertyRepository,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Proceed to Step 2
      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Step 2 Personal details
      expect(find.text('Personal Details'), findsOneWidget);

      // Mobile field should be empty and prompt for input
      expect(find.text('Enter 10-digit mobile number'), findsOneWidget);
      // No "Verified" badge for mobile
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('backwards compatibility: verifiedMobile from OTP initializes correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestWidget(
          RegistrationScreen(
            verifiedMobile: '9988776655',
            authRepository: mockAuthRepository,
            propertyRepository: mockPropertyRepository,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Since inviteToken is null, residential setup is available
      expect(find.text('Select Society'), findsOneWidget);
      expect(find.text('Owner / Tenant'), findsOneWidget);
    });
  });
}
