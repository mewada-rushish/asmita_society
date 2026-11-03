import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/menu/presentation/screens/pets_screen.dart';
import 'package:asmita_society/features/menu/bloc/pets_bloc.dart';
import 'package:asmita_society/features/menu/bloc/pets_event.dart';
import 'package:asmita_society/features/menu/bloc/pets_state.dart';
import 'package:asmita_society/features/menu/data/models/pet_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockPetsBloc extends Mock implements PetsBloc {}

class FakePetsEvent extends Fake implements PetsEvent {}

class TestPetsNotifier {
  final FutureOr<List<PetModel>> Function() onBuild;
  bool deletePetCalled = false;
  int? deletedPetId;

  TestPetsNotifier(this.onBuild);
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePetsEvent());
  });

  late MockAuthBloc mockAuthBloc;
  late MockPetsBloc mockPetsBloc;
  late StreamController<AuthState> authStateController;
  late StreamController<PetsState> petsStateController;

  final testUser = UserModel(
    userId: 1001,
    fullName: 'Pooja Bhatt',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  final samplePets = [
    PetModel(
      id: 301,
      name: 'Bella',
      breed: 'Golden Retriever',
      isVaccinated: true,
      avatarUrl: null,
    ),
    PetModel(
      id: 302,
      name: 'Milo',
      breed: 'Persian Cat',
      isVaccinated: false,
      avatarUrl: null,
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockPetsBloc = MockPetsBloc();
    authStateController = StreamController<AuthState>.broadcast();
    petsStateController = StreamController<PetsState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});

    when(() => mockPetsBloc.stream).thenAnswer((_) => petsStateController.stream);
    when(() => mockPetsBloc.state).thenReturn(PetsLoaded(samplePets));
    when(() => mockPetsBloc.close()).thenAnswer((_) async {});
    when(() => mockPetsBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await authStateController.close();
    await petsStateController.close();
  });

  Widget buildTestableWidget({
    FutureOr<List<PetModel>> Function()? onBuild,
    TestPetsNotifier? notifier,
    PetsState? state,
  }) {
    final PetsState resolvedState;
    if (state != null) {
      resolvedState = state;
    } else if (notifier != null) {
      resolvedState = PetsLoaded(notifier.onBuild() as dynamic);
    } else if (onBuild != null) {
      final res = onBuild();
      if (res is Future) {
        resolvedState = PetsLoading();
      } else {
        resolvedState = PetsLoaded(res);
      }
    } else {
      resolvedState = const PetsLoaded([]);
    }

    when(() => mockPetsBloc.state).thenReturn(resolvedState);
    if (notifier != null) {
      when(() => mockPetsBloc.add(any())).thenAnswer((invocation) {
        final event = invocation.positionalArguments[0];
        if (event is DeletePet) {
          notifier.deletePetCalled = true;
          notifier.deletedPetId = event.id;
        }
      });
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<PetsBloc>.value(value: mockPetsBloc),
      ],
      child: const MaterialApp(
        home: PetsScreen(),
      ),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('PetsScreen Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator while petsProvider is loading', (tester) async {
      setMobileScreen(tester);
      final completer = Completer<List<PetModel>>();

      await tester.pumpWidget(buildTestableWidget(onBuild: () => completer.future));
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when no pets exist', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => <PetModel>[]));
      await tester.pumpAndSettle();

      expect(find.text('No pets added yet.'), findsOneWidget);
    });

    testWidgets('renders pet cards with names, breeds, initials, and vaccination badges', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => samplePets));
      await tester.pumpAndSettle();

      expect(find.text('Bella'), findsOneWidget);
      expect(find.text('Golden Retriever'), findsOneWidget);
      expect(find.text('B'), findsOneWidget); // Initial
      expect(find.text('Vaccinated'), findsOneWidget);

      expect(find.text('Milo'), findsOneWidget);
      expect(find.text('Persian Cat'), findsOneWidget);
      expect(find.text('M'), findsOneWidget); // Initial
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('tapping pet card opens CupertinoActionSheet with Edit and Delete options', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => samplePets));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bella'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Edit Pet'), findsOneWidget);
      expect(find.text('Delete Pet'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Delete Pet opens confirmation dialog and deletes on confirm', (tester) async {
      setMobileScreen(tester);
      final customNotifier = TestPetsNotifier(() => samplePets);

      await tester.pumpWidget(buildTestableWidget(
        onBuild: () => samplePets,
        notifier: customNotifier,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bella'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Pet'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Delete Pet'), findsOneWidget);
      expect(find.text('Are you sure you want to remove Bella?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(customNotifier.deletePetCalled, isTrue);
      expect(customNotifier.deletedPetId, equals(301));
    });

    testWidgets('tapping FloatingActionButton opens Add Pet modal bottom sheet', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => samplePets));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Add Pet'), findsOneWidget);
      expect(find.text('PET NAME'), findsOneWidget);
      expect(find.text('BREED'), findsOneWidget);
      expect(find.descendant(of: find.byType(CupertinoListTile), matching: find.text('Vaccinated')), findsOneWidget);
      expect(find.text('Save Pet'), findsOneWidget);
    });
  });
}
