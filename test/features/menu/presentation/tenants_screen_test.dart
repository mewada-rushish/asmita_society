import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/menu/presentation/screens/tenants_screen.dart';
import 'package:asmita_society/features/menu/bloc/tenant_bloc.dart';
import 'package:asmita_society/features/menu/bloc/tenant_event.dart';
import 'package:asmita_society/features/menu/bloc/tenant_state.dart';
import 'package:asmita_society/features/menu/data/models/tenant_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockTenantBloc extends Mock implements TenantBloc {}

class FakeTenantEvent extends Fake implements TenantEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTenantEvent());
  });

  late MockAuthBloc mockAuthBloc;
  late MockTenantBloc mockTenantBloc;
  late StreamController<AuthState> authStateController;
  late StreamController<TenantState> tenantStateController;

  final testUser = UserModel(
    userId: 801,
    fullName: 'Rajesh Khanna',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  final sampleTenants = [
    TenantModel(
      id: 1,
      name: 'Karan Malhotra',
      relationship: 'Primary Tenant',
      contactNumber: '9988776655',
      isEmergencyContact: false,
    ),
    TenantModel(
      id: 2,
      name: 'Simran Malhotra',
      relationship: 'Co-Tenant',
      contactNumber: '9988776644',
      isEmergencyContact: true,
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockTenantBloc = MockTenantBloc();
    authStateController = StreamController<AuthState>.broadcast();
    tenantStateController = StreamController<TenantState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockTenantBloc.stream).thenAnswer((_) => tenantStateController.stream);
    when(() => mockTenantBloc.state).thenReturn(TenantLoaded(sampleTenants));
    when(() => mockTenantBloc.close()).thenAnswer((_) async {});
    when(() => mockTenantBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await authStateController.close();
    await tenantStateController.close();
  });

  Widget buildTestableWidget({
    FutureOr<List<TenantModel>> Function()? onBuild,
    TenantState? state,
  }) {
    final TenantState resolvedState;
    if (state != null) {
      resolvedState = state;
    } else if (onBuild != null) {
      final res = onBuild();
      if (res is Future) {
        resolvedState = TenantLoading();
      } else {
        resolvedState = TenantLoaded(res as dynamic);
      }
    } else {
      resolvedState = const TenantLoaded([]);
    }

    when(() => mockTenantBloc.state).thenReturn(resolvedState);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<TenantBloc>.value(value: mockTenantBloc),
      ],
      child: const MaterialApp(
        home: TenantsScreen(),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('TenantsScreen Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator while tenantProvider is loading', (tester) async {
      setMobileScreen(tester);
      final completer = Completer<List<TenantModel>>();

      await tester.pumpWidget(buildTestableWidget(onBuild: () => completer.future));
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when no tenants exist', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => <TenantModel>[]));
      await tester.pumpAndSettle();

      expect(find.text('No Tenants added yet.'), findsOneWidget);
    });

    testWidgets('renders tenant cards with names, relationships and emergency badge', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleTenants));
      await tester.pumpAndSettle();

      expect(find.text('Karan Malhotra'), findsOneWidget);
      expect(find.text('Primary Tenant'), findsOneWidget);
      expect(find.text('Simran Malhotra'), findsOneWidget);
      expect(find.text('Co-Tenant'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);
    });

    testWidgets('tapping tenant card opens CupertinoActionSheet with Edit and Delete options', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleTenants));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Karan Malhotra'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Edit Member'), findsOneWidget);
      expect(find.text('Delete Member'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Add Tenant FAB opens Add Tenant bottom sheet modal', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleTenants));
      await tester.pumpAndSettle();

      final addFab = find.byKey(const ValueKey('add_tenant_fab'));
      expect(addFab, findsOneWidget);

      await tester.tap(addFab);
      await tester.pumpAndSettle();

      expect(find.text('Add Tenant'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('RELATIONSHIP'), findsOneWidget);
      expect(find.text('CONTACT NUMBER'), findsOneWidget);
      expect(find.text('Set as Emergency Contact'), findsOneWidget);
      expect(find.text('Save Tenant'), findsOneWidget);
    });

    testWidgets('shows validation dialog if contact number is invalid on save', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleTenants));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add_tenant_fab')));
      await tester.pumpAndSettle();

      final nameField = find.byType(CupertinoTextField).first;
      final contactField = find.byType(CupertinoTextField).last;

      await tester.enterText(nameField, 'Rahul Bose');
      await tester.enterText(contactField, '555');
      await tester.pump();

      await tester.tap(find.text('Save Tenant'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Invalid Number'), findsOneWidget);
      expect(find.text('Please enter a valid 10-digit contact number.'), findsOneWidget);
    });

    testWidgets('tapping History FAB shows tenant selection sheet if multiple tenants exist', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleTenants));
      await tester.pumpAndSettle();

      final historyFab = find.byKey(const ValueKey('request_history_fab'));
      expect(historyFab, findsOneWidget);

      await tester.tap(historyFab);
      await tester.pumpAndSettle();

      expect(find.text('Select Tenant'), findsOneWidget);
      expect(find.text('Karan Malhotra'), findsNWidgets(2)); // Card + Sheet item
    });
  });
}
