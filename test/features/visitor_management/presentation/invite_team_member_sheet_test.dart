import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/auth/data/models/user_model.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/team_invite_repository.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/invite_team_member_sheet.dart';

class MockTeamInviteRepository extends Mock implements TeamInviteRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTeamInviteRepository mockRepository;

  setUp(() {
    mockRepository = MockTeamInviteRepository();

    when(() => mockRepository.getSocietyDepartments(any())).thenAnswer(
      (_) async => [
        {'id': 1, 'name': 'Executive Management'},
        {'id': 2, 'name': 'IT & Infrastructure'},
        {'id': 3, 'name': 'Accounts & Finance'},
      ],
    );

    when(() => mockRepository.getDelegationStatus(societyId: any(named: 'societyId')))
        .thenAnswer((_) async => null);
  });

  Widget createTestWidget({
    required UserModel? user,
    TeamInviteRepository? repository,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: InviteTeamMemberSheet(
          user: user,
          repository: repository ?? mockRepository,
        ),
      ),
    );
  }

  UserModel createTestUser({
    required int userId,
    required String fullName,
    required String primaryRole,
    int? rolePower,
    Map<String, dynamic>? roleDetails,
    int societyId = 114,
    String societyName = 'AsmitA House',
  }) {
    return UserModel(
      userId: userId,
      fullName: fullName,
      primaryRole: primaryRole,
      accountType: 'corporate',
      rolePower: rolePower,
      roleDetails: roleDetails,
      societyId: societyId,
      societyName: societyName,
    );
  }

  group('InviteTeamMemberSheet - Role & Permission Gating', () {
    testWidgets('Director sees all 4 target roles and unlocked department selection', (tester) async {
      final director = createTestUser(
        userId: 1,
        fullName: 'Jane Director',
        primaryRole: 'Director',
        rolePower: 500,
      );

      await tester.pumpWidget(createTestWidget(user: director));
      await tester.pumpAndSettle();

      // Check allowed target roles
      expect(find.text('Head of Department (HOD)'), findsOneWidget);
      expect(find.text('Team Leader'), findsOneWidget);
      expect(find.text('Corporate Employee'), findsOneWidget);
      expect(find.text('Security Guard'), findsOneWidget);

      // Department dropdown should be present and populated
      expect(find.byType(DropdownButton<int>), findsOneWidget);
      expect(find.text('Executive Management'), findsOneWidget);

      // Verify no locked padlock icon
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('HOD sees 2 target roles and locked department', (tester) async {
      final hod = createTestUser(
        userId: 2,
        fullName: 'Robert Head',
        primaryRole: 'Corporate Employee',
        rolePower: 300,
        roleDetails: {
          'is_hod': true,
          'department_id': 2,
          'department_name': 'IT & Infrastructure',
          'designation': 'Head of Department',
        },
      );

      await tester.pumpWidget(createTestWidget(user: hod));
      await tester.pumpAndSettle();

      // Allowed target roles: Team Leader and Corporate Employee only
      expect(find.text('Team Leader'), findsOneWidget);
      expect(find.text('Corporate Employee'), findsOneWidget);
      expect(find.text('Head of Department (HOD)'), findsNothing);
      expect(find.text('Security Guard'), findsNothing);

      // Department is locked with padlock icon
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('IT & Infrastructure'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsNothing);
    });

    testWidgets('Team Leader sees 1 target role and locked department', (tester) async {
      final tl = createTestUser(
        userId: 3,
        fullName: 'Alice Leader',
        primaryRole: 'Team Leader',
        rolePower: 200,
        roleDetails: {
          'department_id': 3,
          'department_name': 'Accounts & Finance',
          'designation': 'Team Lead',
        },
      );

      await tester.pumpWidget(createTestWidget(user: tl));
      await tester.pumpAndSettle();

      // Allowed target role: Corporate Employee only
      expect(find.text('Corporate Employee'), findsOneWidget);
      expect(find.text('Team Leader'), findsNothing);
      expect(find.text('Head of Department (HOD)'), findsNothing);

      // Department is locked
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('Accounts & Finance'), findsOneWidget);
    });

    testWidgets('Active Delegatee inherits Director privilege and shows banner', (tester) async {
      // Normal employee without direct management role
      final employee = createTestUser(
        userId: 4,
        fullName: 'David Assistant',
        primaryRole: 'Corporate Employee',
        rolePower: 100,
        roleDetails: {
          'designation': 'Executive Assistant',
        },
      );

      // Mock active delegation from Jane Director
      when(() => mockRepository.getDelegationStatus(societyId: 114)).thenAnswer(
        (_) async => {
          'incomingDelegations': [
            {
              'id': 10,
              'is_active': true,
              'delegator': {
                'full_name': 'Jane Director',
                'primary_role': 'Director',
                'role_power': 500,
                'role_details': {
                  'department_id': 1,
                  'department_name': 'Executive Management',
                },
              },
            },
          ],
        },
      );

      await tester.pumpWidget(createTestWidget(user: employee));
      await tester.pump(); // Starts loading delegation
      await tester.pumpAndSettle();

      // Should show Active Delegation Banner
      expect(
        find.text('Acting on behalf of Jane Director (Executive Management)'),
        findsOneWidget,
      );

      // Inherits Director allowed roles
      expect(find.text('Head of Department (HOD)'), findsOneWidget);
      expect(find.text('Team Leader'), findsOneWidget);
      expect(find.text('Corporate Employee'), findsOneWidget);
      expect(find.text('Security Guard'), findsOneWidget);
    });

    testWidgets('Unauthorized user without delegation shows Access Restricted view', (tester) async {
      final guard = createTestUser(
        userId: 5,
        fullName: 'Sam Guard',
        primaryRole: 'Security Guard',
        rolePower: 50,
      );

      when(() => mockRepository.getDelegationStatus(societyId: 114))
          .thenAnswer((_) async => {'incomingDelegations': []});

      await tester.pumpWidget(createTestWidget(user: guard));
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.text('Generate Invite Link'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('InviteTeamMemberSheet - Form Validation & Submission', () {
    testWidgets('validates 10-digit mobile number if entered', (tester) async {
      final director = createTestUser(
        userId: 1,
        fullName: 'Jane Director',
        primaryRole: 'Director',
        rolePower: 500,
      );

      await tester.pumpWidget(createTestWidget(user: director));
      await tester.pumpAndSettle();

      // Enter an invalid 4-digit number
      final phoneField = find.widgetWithText(TextFormField, '10-digit mobile number');
      expect(phoneField, findsOneWidget);
      await tester.enterText(phoneField, '1234');
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Generate Invite Link'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid 10-digit mobile number'), findsOneWidget);
      verifyNever(() => mockRepository.generateInvite(
            societyId: any(named: 'societyId'),
            targetRole: any(named: 'targetRole'),
          ));
    });

    testWidgets('successful submission with phone displays DLT SMS status and sharing buttons', (tester) async {
      final director = createTestUser(
        userId: 1,
        fullName: 'Jane Director',
        primaryRole: 'Director',
        rolePower: 500,
      );

      when(
        () => mockRepository.generateInvite(
          societyId: 114,
          targetRole: any(named: 'targetRole'),
          departmentId: any(named: 'departmentId'),
          departmentName: any(named: 'departmentName'),
          recipientName: 'Mark Spencer',
          recipientPhone: '9876543210',
          targetUnitId: any(named: 'targetUnitId'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'rawToken': 'mock_token_777',
          'inviteUrl': 'https://admin.myasmita.com/invite/join/mock_token_777',
          'expiresAt': '2026-11-12T01:41:20.000Z',
          'tokenType': 'ONBOARDING',
          'smsSent': true,
        },
      );

      await tester.pumpWidget(createTestWidget(user: director));
      await tester.pumpAndSettle();

      // Fill name & phone
      final nameField = find.widgetWithText(TextFormField, 'e.g. John Doe');
      final phoneField = find.widgetWithText(TextFormField, '10-digit mobile number');

      await tester.enterText(nameField, 'Mark Spencer');
      await tester.enterText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Generate Invite Link'));
      await tester.pumpAndSettle();

      // State B verification
      expect(find.text('Invite Created Successfully!'), findsOneWidget);

      // DLT SMS Status Display with template ID
      expect(
        find.text('SMS invite dispatched to +91 9876543210 via DLT Template 1677100000000395667'),
        findsOneWidget,
      );

      // Invite URL displayed
      expect(
        find.text('https://admin.myasmita.com/invite/join/mock_token_777'),
        findsOneWidget,
      );

      // Action buttons
      expect(find.text('Share via WhatsApp'), findsOneWidget);
      expect(find.text('Copy Link / Share'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('successful submission without phone displays direct link ready notice', (tester) async {
      final tl = createTestUser(
        userId: 3,
        fullName: 'Alice Leader',
        primaryRole: 'Team Leader',
        rolePower: 200,
        roleDetails: {
          'department_id': 3,
          'department_name': 'Accounts & Finance',
        },
      );

      when(
        () => mockRepository.generateInvite(
          societyId: 114,
          targetRole: 'Corporate Employee',
          departmentId: 3,
          departmentName: 'Accounts & Finance',
          recipientName: null,
          recipientPhone: null,
          targetUnitId: 3,
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'rawToken': 'mock_token_888',
          'inviteUrl': 'https://admin.myasmita.com/invite/join/mock_token_888',
          'expiresAt': '2026-11-12T01:41:20.000Z',
          'tokenType': 'ONBOARDING',
          'smsSent': false,
        },
      );

      await tester.pumpWidget(createTestWidget(user: tl));
      await tester.pumpAndSettle();

      // Submit without entering name or phone
      await tester.tap(find.text('Generate Invite Link'));
      await tester.pumpAndSettle();

      // State B verification for direct link
      expect(find.text('Invite Created Successfully!'), findsOneWidget);
      expect(
        find.text('Direct link ready for sharing (DLT Template 1677100000000395667)'),
        findsOneWidget,
      );
      expect(find.text('Share via WhatsApp'), findsOneWidget);
      expect(find.text('Copy Link / Share'), findsOneWidget);
    });
  });
}
