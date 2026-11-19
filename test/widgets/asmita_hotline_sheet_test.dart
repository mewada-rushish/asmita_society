import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/dashboard/widgets/asmita_hotline_sheet.dart';

void main() {
  testWidgets('AsmitaHotlineSheet builds category dropdown without type mismatch exception', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AsmitaHotlineSheet(societyId: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify header and category dropdown rendered cleanly
    expect(find.text('HOTLINE CONTACTS'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.textContaining('All'), findsWidgets);
  });
}
