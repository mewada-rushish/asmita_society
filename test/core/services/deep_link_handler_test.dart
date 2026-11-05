import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/core/services/deep_link_handler.dart';
import 'package:asmita_society/features/auth/presentation/registration_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_pass_check_in_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GlobalKey<NavigatorState> navigatorKey;
  late MockAuthBloc mockAuthBloc;
  late MockIndustrialVisitBloc mockIndustrialVisitBloc;

  setUp(() {
    navigatorKey = GlobalKey<NavigatorState>();
    mockAuthBloc = MockAuthBloc();
    mockIndustrialVisitBloc = MockIndustrialVisitBloc();

    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockIndustrialVisitBloc.state).thenReturn(const IndustrialVisitState());
    when(() => mockIndustrialVisitBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildApp(Widget home) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<IndustrialVisitBloc>.value(value: mockIndustrialVisitBloc),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: home,
      ),
    );
  }

  group('DeepLinkHandler', () {
    testWidgets('handleUri routes join token to RegistrationScreen with inviteToken and null verifiedMobile',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const Scaffold(body: Text('Home'))),
      );

      const mockJoinToken = 'mock_invite_token_fixture_777';
      final uri = Uri.parse('https://admin.myasmita.com/invite/join/$mockJoinToken');

      DeepLinkHandler.handleUri(uri, navigatorKey);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final registrationFinder = find.byType(RegistrationScreen);
      expect(registrationFinder, findsOneWidget);

      final registrationScreen = tester.widget<RegistrationScreen>(registrationFinder);
      expect(registrationScreen.inviteToken, mockJoinToken);
      expect(registrationScreen.verifiedMobile, isNull,
          reason: 'CRITICAL: verifiedMobile must NOT be populated with invite token');
    });

    testWidgets('handleUri routes pass token to GuardPassCheckInScreen', (tester) async {
      await tester.pumpWidget(
        buildApp(const Scaffold(body: Text('Home'))),
      );

      final uri = Uri.parse('https://admin.myasmita.com/invite/pass/pass_token_123');

      DeepLinkHandler.handleUri(uri, navigatorKey);
      await tester.pumpAndSettle();

      expect(find.byType(GuardPassCheckInScreen), findsOneWidget);
    });

    testWidgets('handleUri ignores non-invite or invalid path URIs', (tester) async {
      await tester.pumpWidget(
        buildApp(const Scaffold(body: Text('Home'))),
      );

      final uri = Uri.parse('https://admin.myasmita.com/other/route/something');

      DeepLinkHandler.handleUri(uri, navigatorKey);
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationScreen), findsNothing);
      expect(find.byType(GuardPassCheckInScreen), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
