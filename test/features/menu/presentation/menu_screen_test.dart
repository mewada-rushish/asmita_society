import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/menu/presentation/screens/menu_screen.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_event.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVisitorBloc extends Mock implements VisitorBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockVisitorBloc mockVisitorBloc;
  late StreamController<AuthState> authStateController;
  late StreamController<VisitorState> visitorStateController;

  final testOwner = UserModel(
    userId: 501,
    fullName: 'Rameshwar Sharma',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
    flatMappings: [
      FlatMapping(
        mappingId: 1,
        flatId: 101,
        flatNumber: '402',
        towerId: 10,
        towerName: 'A Wing',
        ownershipType: 'owner',
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(AuthLogoutRequested());
    registerFallbackValue(ClearVisitorHistory());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVisitorBloc = MockVisitorBloc();
    authStateController = StreamController<AuthState>.broadcast();
    visitorStateController = StreamController<VisitorState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testOwner, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    when(() => mockAuthBloc.add(any())).thenReturn(null);

    when(() => mockVisitorBloc.stream).thenAnswer((_) => visitorStateController.stream);
    when(() => mockVisitorBloc.state).thenReturn(VisitorInitial());
    when(() => mockVisitorBloc.close()).thenAnswer((_) async {});
    when(() => mockVisitorBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await authStateController.close();
    await visitorStateController.close();
  });

  Widget buildTestableWidget(String userRole) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VisitorBloc>.value(value: mockVisitorBloc),
      ],
      child: MaterialApp(
        home: MenuScreen(userRole: userRole),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('MenuScreen Production Widget Tests', () {
    testWidgets('renders profile card with user name, initials and flat mapping for owner role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('owner'));
      await tester.pump();

      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Rameshwar Sharma'), findsOneWidget);
      expect(find.text('RS'), findsOneWidget);
      expect(find.text('Flat A Wing-402 • OWNER'), findsOneWidget);
    });

    testWidgets('renders residential sections and items for owner role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('owner'));
      await tester.pump();

      expect(find.text('My Household'), findsOneWidget);
      expect(find.text('Family Members'), findsOneWidget);
      expect(find.text('Tenants'), findsOneWidget);
      expect(find.text('Vehicles'), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);

      expect(find.text('Society Info'), findsOneWidget);
      expect(find.text('Committee Members'), findsOneWidget);
      expect(find.text('Rules & Regulations'), findsOneWidget);
      expect(find.text('Important Documents'), findsOneWidget);

      expect(find.text('Application'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('renders Access Requests instead of Tenants for tenant role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('tenant'));
      await tester.pump();

      expect(find.text('Access Requests'), findsOneWidget);
      expect(find.text('Tenants'), findsNothing);
    });

    testWidgets('hides residential household and society info sections for guard role', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('guard'));
      await tester.pump();

      expect(find.text('My Household'), findsNothing);
      expect(find.text('Society Info'), findsNothing);
      expect(find.text('Application'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tapping Logout opens confirmation dialog and confirms dispatch of logout events', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget('owner'));
      await tester.pump();

      final logoutItem = find.text('Logout');
      expect(logoutItem, findsOneWidget);

      await tester.tap(logoutItem);
      await tester.pumpAndSettle();

      expect(find.byType(AsmitaDialog), findsOneWidget);
      expect(find.text('Are you sure you want to logout? You will need to sign in again to access society features.'), findsOneWidget);

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Logout');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      verify(() => mockVisitorBloc.add(any(that: isA<ClearVisitorHistory>()))).called(1);
      verify(() => mockAuthBloc.add(any(that: isA<AuthLogoutRequested>()))).called(1);
    });
  });
}
