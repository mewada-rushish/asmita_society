import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/menu/presentation/screens/vehicles_screen.dart';
import 'package:asmita_society/features/menu/bloc/vehicles_bloc.dart';
import 'package:asmita_society/features/menu/bloc/vehicles_event.dart';
import 'package:asmita_society/features/menu/bloc/vehicles_state.dart';
import 'package:asmita_society/features/menu/data/models/vehicle_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVehiclesBloc extends Mock implements VehiclesBloc {}

class FakeVehiclesEvent extends Fake implements VehiclesEvent {}

class TestVehiclesNotifier {
  final FutureOr<List<VehicleModel>> Function() onBuild;
  bool deleteVehicleCalled = false;
  int? deletedVehicleId;

  TestVehiclesNotifier(this.onBuild);
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeVehiclesEvent());
  });

  late MockAuthBloc mockAuthBloc;
  late MockVehiclesBloc mockVehiclesBloc;
  late StreamController<AuthState> authStateController;
  late StreamController<VehiclesState> vehiclesStateController;

  final testUser = UserModel(
    userId: 901,
    fullName: 'Arjun Kapoor',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
    flatMappings: [
      FlatMapping(
        mappingId: 1,
        flatId: 501,
        flatNumber: 'A-501',
        towerId: 10,
        towerName: 'Tower A',
        ownershipType: 'owner',
      ),
    ],
  );

  final sampleVehicles = [
    VehicleModel(
      id: 201,
      type: 'four_wheeler',
      makeModel: 'Honda City',
      licensePlate: 'MH 02 CZ 4421',
      parkingSlot: 'P-12',
    ),
    VehicleModel(
      id: 202,
      type: 'two_wheeler',
      makeModel: 'Royal Enfield',
      licensePlate: 'MH 02 DK 9912',
      parkingSlot: 'B-04',
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVehiclesBloc = MockVehiclesBloc();
    authStateController = StreamController<AuthState>.broadcast();
    vehiclesStateController = StreamController<VehiclesState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockVehiclesBloc.stream).thenAnswer((_) => vehiclesStateController.stream);
    when(() => mockVehiclesBloc.state).thenReturn(VehiclesLoaded(sampleVehicles));
    when(() => mockVehiclesBloc.close()).thenAnswer((_) async {});
    when(() => mockVehiclesBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await authStateController.close();
    await vehiclesStateController.close();
  });

  Widget buildTestableWidget({
    FutureOr<List<VehicleModel>> Function()? onBuild,
    TestVehiclesNotifier? notifier,
    VehiclesState? state,
  }) {
    final VehiclesState resolvedState;
    if (state != null) {
      resolvedState = state;
    } else if (notifier != null) {
      resolvedState = VehiclesLoaded(notifier.onBuild() as dynamic);
    } else if (onBuild != null) {
      final res = onBuild();
      if (res is Future) {
        resolvedState = VehiclesLoading();
      } else {
        resolvedState = VehiclesLoaded(res as dynamic);
      }
    } else {
      resolvedState = const VehiclesLoaded([]);
    }

    when(() => mockVehiclesBloc.state).thenReturn(resolvedState);
    if (notifier != null) {
      when(() => mockVehiclesBloc.add(any())).thenAnswer((invocation) {
        final event = invocation.positionalArguments[0];
        if (event is DeleteVehicle) {
          notifier.deleteVehicleCalled = true;
          notifier.deletedVehicleId = event.id;
        }
      });
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<VehiclesBloc>.value(value: mockVehiclesBloc),
      ],
      child: const MaterialApp(
        home: VehiclesScreen(),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('VehiclesScreen Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator while vehiclesProvider is loading', (tester) async {
      setMobileScreen(tester);
      final completer = Completer<List<VehicleModel>>();

      await tester.pumpWidget(buildTestableWidget(onBuild: () => completer.future));
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when no vehicles exist', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => <VehicleModel>[]));
      await tester.pumpAndSettle();

      expect(find.text('No vehicles added yet.'), findsOneWidget);
    });

    testWidgets('renders vehicle cards with correct icons, plates, and parking slots', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleVehicles));
      await tester.pumpAndSettle();

      expect(find.text('Honda City'), findsOneWidget);
      expect(find.text('MH 02 CZ 4421'), findsOneWidget);
      expect(find.text('Slot: P-12'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);

      expect(find.text('Royal Enfield'), findsOneWidget);
      expect(find.text('MH 02 DK 9912'), findsOneWidget);
      expect(find.text('Slot: B-04'), findsOneWidget);
      expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);
    });

    testWidgets('tapping vehicle card opens CupertinoActionSheet with Edit and Delete options', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleVehicles));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Honda City'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Edit Vehicle'), findsOneWidget);
      expect(find.text('Delete Vehicle'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Delete Vehicle in ActionSheet opens confirmation dialog and deletes on confirm', (tester) async {
      setMobileScreen(tester);
      final customNotifier = TestVehiclesNotifier(() => sampleVehicles);

      await tester.pumpWidget(buildTestableWidget(
        onBuild: () => sampleVehicles,
        notifier: customNotifier,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Honda City'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Vehicle'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Delete Vehicle'), findsOneWidget);
      expect(find.text('Are you sure you want to remove Honda City?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(customNotifier.deleteVehicleCalled, isTrue);
      expect(customNotifier.deletedVehicleId, equals(201));
    });

    testWidgets('tapping FloatingActionButton opens AddEditVehicleSheet', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleVehicles));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Add Vehicle bottom sheet header appears
      expect(find.text('Add Vehicle'), findsOneWidget);
    });
  });
}
