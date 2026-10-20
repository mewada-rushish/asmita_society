import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/menu/presentation/screens/vehicles_screen.dart';
import 'package:asmita_society/features/menu/presentation/providers/vehicles_provider.dart';
import 'package:asmita_society/features/menu/data/models/vehicle_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

import 'package:asmita_society/features/menu/data/repositories/vehicles_repository.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockVehiclesRepository extends Mock implements VehiclesRepository {}

class TestVehiclesNotifier extends VehiclesNotifier {
  final FutureOr<List<VehicleModel>> Function() onBuild;
  bool deleteVehicleCalled = false;
  int? deletedVehicleId;

  TestVehiclesNotifier(this.onBuild);

  @override
  FutureOr<List<VehicleModel>> build() => onBuild();

  @override
  Future<bool> deleteVehicle(int id) async {
    deleteVehicleCalled = true;
    deletedVehicleId = id;
    return true;
  }
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockVehiclesRepository mockVehiclesRepository;
  late StreamController<AuthState> authStateController;

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
      type: '4-wheeler',
      makeModel: 'Honda City',
      licensePlate: 'MH 02 CZ 4421',
      parkingSlot: 'P-12',
      flatId: 501,
    ),
    VehicleModel(
      id: 202,
      type: '2-wheeler',
      makeModel: 'Royal Enfield',
      licensePlate: 'MH 02 DK 9912',
      parkingSlot: 'B-04',
      flatId: 501,
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockVehiclesRepository = MockVehiclesRepository();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    when(() => mockVehiclesRepository.getParkingSlots()).thenAnswer((_) async => ['P-1', 'P-2']);
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildTestableWidget({
    required FutureOr<List<VehicleModel>> Function() onBuild,
    TestVehiclesNotifier? notifier,
  }) {
    return ProviderScope(
      overrides: [
        vehiclesRepositoryProvider.overrideWithValue(mockVehiclesRepository),
        vehiclesProvider.overrideWith(() => notifier ?? TestVehiclesNotifier(onBuild)),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const MaterialApp(
          home: VehiclesScreen(),
        ),
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
