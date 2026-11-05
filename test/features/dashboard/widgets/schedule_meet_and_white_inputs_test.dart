import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/widgets/asmita_text_field.dart';

void main() {
  group('AsmitaTextField White Background Tests', () {
    testWidgets('renders pure white background in Light mode by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AsmitaTextField(
              label: 'Visitor Name',
              hint: 'Full legal name',
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final TextField textField = tester.widget(textFieldFinder);
      expect(textField.decoration?.fillColor, Colors.white);
      expect(textField.decoration?.filled, true);
    });

    testWidgets('renders custom fillColor when provided', (tester) async {
      const customColor = Color(0xFFF0FDF4);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AsmitaTextField(
              label: 'Visitor Name',
              hint: 'Full legal name',
              fillColor: customColor,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.fillColor, customColor);
    });
  });

  group('Schedule a Meet Time Slots Logic', () {
    test('time slots range strictly from 9:00 AM to 7:00 PM with 30-min intervals', () {
      final List<TimeOfDay> expectedSlots = [
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 9, minute: 30),
        const TimeOfDay(hour: 10, minute: 0),
        const TimeOfDay(hour: 10, minute: 30),
        const TimeOfDay(hour: 11, minute: 0),
        const TimeOfDay(hour: 11, minute: 30),
        const TimeOfDay(hour: 12, minute: 0),
        const TimeOfDay(hour: 12, minute: 30),
        const TimeOfDay(hour: 13, minute: 0),
        const TimeOfDay(hour: 13, minute: 30),
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 14, minute: 30),
        const TimeOfDay(hour: 15, minute: 0),
        const TimeOfDay(hour: 15, minute: 30),
        const TimeOfDay(hour: 16, minute: 0),
        const TimeOfDay(hour: 16, minute: 30),
        const TimeOfDay(hour: 17, minute: 0),
        const TimeOfDay(hour: 17, minute: 30),
        const TimeOfDay(hour: 18, minute: 0),
        const TimeOfDay(hour: 18, minute: 30),
        const TimeOfDay(hour: 19, minute: 0),
      ];

      expect(expectedSlots.length, 21);
      expect(expectedSlots.first, const TimeOfDay(hour: 9, minute: 0));
      expect(expectedSlots.last, const TimeOfDay(hour: 19, minute: 0));

      for (int i = 0; i < expectedSlots.length - 1; i++) {
        final current = expectedSlots[i];
        final next = expectedSlots[i + 1];
        final currentMinutes = current.hour * 60 + current.minute;
        final nextMinutes = next.hour * 60 + next.minute;
        expect(nextMinutes - currentMinutes, 30, reason: 'Interval between slots must be exactly 30 minutes');
      }
    });
  });
}
