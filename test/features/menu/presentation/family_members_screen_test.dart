import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/menu/presentation/screens/family_members_screen.dart';
import 'package:asmita_society/features/menu/presentation/providers/family_provider.dart';
import 'package:asmita_society/features/menu/data/models/family_member_model.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class TestFamilyNotifier extends FamilyNotifier {
  final FutureOr<List<FamilyMemberModel>> Function() onBuild;
  bool addMemberCalled = false;
  bool deleteMemberCalled = false;

  TestFamilyNotifier(this.onBuild);

  @override
  FutureOr<List<FamilyMemberModel>> build() => onBuild();

  @override
  Future<bool> addMember({
    required String name,
    required String relationship,
    String? contactNumber,
    bool isEmergencyContact = false,
  }) async {
    addMemberCalled = true;
    return true;
  }

  @override
  Future<bool> deleteMember(int id) async {
    deleteMemberCalled = true;
    return true;
  }
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late StreamController<AuthState> authStateController;

  final testUser = UserModel(
    userId: 701,
    fullName: 'Sunita Sharma',
    primaryRole: 'owner',
    accountType: 'app',
    societyName: 'AsmitA Grandeur',
  );

  final sampleMembers = [
    FamilyMemberModel(
      id: -1,
      name: 'Sunita Sharma',
      relationship: 'Primary',
      contactNumber: '9876543210',
      isEmergencyContact: false,
    ),
    FamilyMemberModel(
      id: 2,
      name: 'Rohan Sharma',
      relationship: 'Son',
      contactNumber: '9123456780',
      isEmergencyContact: true,
    ),
    FamilyMemberModel(
      id: 3,
      name: 'Pooja Sharma',
      relationship: 'Daughter',
      contactNumber: '9822334455',
      isEmergencyContact: false,
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.stream).thenAnswer((_) => authStateController.stream);
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticated(user: testUser, sessionRole: 'owner'),
    );
    when(() => mockAuthBloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authStateController.close();
  });

  Widget buildTestableWidget({
    required FutureOr<List<FamilyMemberModel>> Function() onBuild,
  }) {
    return ProviderScope(
      overrides: [
        familyProvider.overrideWith(() => TestFamilyNotifier(onBuild)),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const MaterialApp(
          home: FamilyMembersScreen(),
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

  group('FamilyMembersScreen Production Widget Tests', () {
    testWidgets('renders AsmitaLoadingIndicator while familyProvider is loading', (tester) async {
      setMobileScreen(tester);
      final completer = Completer<List<FamilyMemberModel>>();

      await tester.pumpWidget(buildTestableWidget(onBuild: () => completer.future));
      await tester.pump();

      expect(find.byType(AsmitaLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders empty state when no family members exist', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => <FamilyMemberModel>[]));
      await tester.pumpAndSettle();

      expect(find.text('No family members added yet.'), findsOneWidget);
    });

    testWidgets('renders family member cards with names, relationships and emergency badge', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleMembers));
      await tester.pumpAndSettle();

      expect(find.text('Sunita Sharma'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Rohan Sharma'), findsOneWidget);
      expect(find.text('Son'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);
      expect(find.text('Pooja Sharma'), findsOneWidget);
      expect(find.text('Daughter'), findsOneWidget);
    });

    testWidgets('tapping primary member card shows informational snackbar', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleMembers));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sunita Sharma'));
      await tester.pump();

      expect(
        find.text('Primary member profile can be edited from the Profile section'),
        findsOneWidget,
      );
    });

    testWidgets('tapping secondary member card opens CupertinoActionSheet with Edit and Delete options', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleMembers));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rohan Sharma'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Edit Member'), findsOneWidget);
      expect(find.text('Delete Member'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping floating action button opens Add Family Member bottom sheet', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleMembers));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Add Family Member'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('RELATIONSHIP'), findsOneWidget);
      expect(find.text('CONTACT NUMBER'), findsOneWidget);
      expect(find.text('Set as Emergency Contact'), findsOneWidget);
      expect(find.text('Save Member'), findsOneWidget);
    });

    testWidgets('shows validation dialog if contact number is invalid on save', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(onBuild: () => sampleMembers));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter name and invalid contact (e.g., 5 digits)
      final nameField = find.byType(CupertinoTextField).first;
      final contactField = find.byType(CupertinoTextField).last;

      await tester.enterText(nameField, 'Vikram Sharma');
      await tester.enterText(contactField, '12345');
      await tester.pump();

      await tester.tap(find.text('Save Member'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('Invalid Number'), findsOneWidget);
      expect(find.text('Please enter a valid 10-digit contact number.'), findsOneWidget);
    });
  });
}
