import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/invite_pass_screen.dart';
import 'package:asmita_society/features/visitor_management/data/models/invite_model.dart';

void main() {
  final testInvite = PreApprovedInvite(
    id: 101,
    societyId: 1,
    towerId: 2,
    unitId: 404,
    residentId: 55,
    inviteType: 'Guest',
    inviteSubType: 'ONCE',
    companyName: 'Dr. John Watson',
    passCode: 'PASS-9876',
    qrCode: 'https://asmitasociety.com/pass/9876',
    validTo: DateTime(2026, 12, 31, 23, 59),
  );

  Widget buildTestableWidget(PreApprovedInvite invite) {
    return MaterialApp(
      home: InvitePassScreen(invite: invite),
    );
  }

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('InvitePassScreen Production Widget Tests', () {
    testWidgets('renders visitor pass title, type, company/visitor name and unit info', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(testInvite));
      await tester.pump();

      expect(find.text('Visitor Pass'), findsOneWidget);
      expect(find.text('ONCE PASS'), findsOneWidget);
      expect(find.text('Dr. John Watson'), findsOneWidget);
      expect(find.text('Flat 404'), findsOneWidget);
      expect(find.text('Valid Until'), findsOneWidget);
      expect(find.text('Pass Type'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('renders QrImageView when qrCode is present', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(testInvite));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('renders fallback QR icon when qrCode is empty or null', (tester) async {
      setMobileScreen(tester);
      final inviteWithoutQr = PreApprovedInvite(
        id: 102,
        societyId: 1,
        towerId: 2,
        unitId: 404,
        residentId: 55,
        inviteType: 'Delivery',
        inviteSubType: 'FREQUENT',
        qrCode: '',
      );

      await tester.pumpWidget(buildTestableWidget(inviteWithoutQr));
      await tester.pump();

      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('renders Share Invite Pass action button', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildTestableWidget(testInvite));
      await tester.pump();

      final shareBtn = find.text('Share Invite Pass');
      expect(shareBtn, findsOneWidget);
    });

    testWidgets('tapping back button navigates back', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InvitePassScreen(invite: testInvite)),
              ),
              child: const Text('Open Pass'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Pass'));
      await tester.pumpAndSettle();

      expect(find.text('Visitor Pass'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Open Pass'), findsOneWidget);
    });
  });
}
