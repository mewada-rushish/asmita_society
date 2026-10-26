import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:asmita_society/core/security/secure_storage_service.dart';
import 'package:asmita_society/features/onboarding/presentation/onboarding_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockSecureStorageService mockSecureStorage;
  late StreamController<AuthState> authStateController;

  setUpAll(() {
    registerFallbackValue(AuthCheckRequested());
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    mockAuthBloc = MockAuthBloc();
    mockSecureStorage = MockSecureStorageService();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.secureStorage).thenReturn(mockSecureStorage);
    when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const OnboardingScreen(),
      ),
    );
  }

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders first slide with skip capsule, title, and indicators', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Top skip capsule
      expect(find.text('Skip'), findsOneWidget);

      // Slide 1 Content
      expect(find.text('Smart IoT Access'), findsOneWidget);
      expect(find.text('ENTERPRISE & SOCIETY AUTOMATION'), findsOneWidget);
      expect(
        find.textContaining('Control your premises lighting'),
        findsOneWidget,
      );

      // Back button should be invisible on first page (opacity 0)
      final backButtonOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(backButtonOpacity.opacity, 0.0);
    });

    testWidgets('tapping Skip saves seen flag and dispatches AuthCheckRequested', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      verify(() => mockSecureStorage.write(
            key: 'has_seen_onboarding',
            value: 'true',
          )).called(1);
      verify(() => mockAuthBloc.add(any(that: isA<AuthCheckRequested>()))).called(1);
    });

    testWidgets('navigates through slides with forward and backward buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Next button on slide 1
      final forwardIcon = find.byIcon(Icons.arrow_forward_ios_rounded);
      expect(forwardIcon, findsOneWidget);
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Should now be on slide 2
      expect(find.text('High-Assurance Security'), findsOneWidget);
      expect(find.text('GATE-SYNC & VISITOR LOGS'), findsOneWidget);

      // Back button is now visible
      final backButtonOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(backButtonOpacity.opacity, 1.0);

      // Tap next again to reach slide 3
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Should now be on slide 3
      expect(find.text('Seamless ERP & BBPS'), findsOneWidget);
      expect(find.text('OPERATIONS & LEDGERS'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Back button to return to slide 2
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('High-Assurance Security'), findsOneWidget);
    });

    testWidgets('tapping Get Started on final slide completes onboarding', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Advance to slide 2
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Advance to slide 3
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      verify(() => mockSecureStorage.write(
            key: 'has_seen_onboarding',
            value: 'true',
          )).called(1);
      verify(() => mockAuthBloc.add(any(that: isA<AuthCheckRequested>()))).called(1);
    });

    testWidgets('swiping page advances slide correctly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Swipe left
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('High-Assurance Security'), findsOneWidget);
    });
  });
}
