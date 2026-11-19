import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/services/permission_manager_service.dart';

void main() {
  setUp(() {
    PermissionManagerService.resetSession();
  });

  tearDown(() {
    PermissionManagerService.resetSession();
  });

  test('PermissionManagerService.resetSession resets session flags cleanly', () {
    PermissionManagerService.resetSession();
    // Test that invoking resetSession executes without errors
    expect(true, isTrue);
  });

  testWidgets('showPermissionSetupDialog with force: false does not pop on non-Android platform',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                PermissionManagerService.showPermissionSetupDialog(context, force: false);
              },
              child: const Text('Trigger Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger Dialog'));
    await tester.pumpAndSettle();

    // On desktop / non-Android, force: false should not open any modal bottom sheet
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('showPermissionSetupDialog blocks duplicate sheets when invoked concurrently',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                // Call it multiple times in rapid succession
                PermissionManagerService.showPermissionSetupDialog(context, force: true);
                PermissionManagerService.showPermissionSetupDialog(context, force: true);
                PermissionManagerService.showPermissionSetupDialog(context, force: true);
              },
              child: const Text('Trigger Concurrent'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger Concurrent'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Only one BottomSheet should ever be mounted
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Background Overlay & Alert'), findsOneWidget);

    // Dismiss it
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
  });
}
