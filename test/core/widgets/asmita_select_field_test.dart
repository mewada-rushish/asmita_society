import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/widgets/asmita_select_field.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';

void main() {
  testWidgets('AsmitaSelectField opens selection using AsmitaBottomSheet component and selects option', (tester) async {
    String? selectedValue;

    final items = [
      const AsmitaSelectItem(
        value: 'vehicle_1',
        label: 'Mercedes E220d • MH 04 AB 1234',
        subtitle: 'Primary Executive Saloon',
        icon: Icons.directions_car_filled_rounded,
      ),
      const AsmitaSelectItem(
        value: 'vehicle_2',
        label: 'BMW 730Ld • MH 01 CZ 9999',
        subtitle: 'Chauffeured Limousine',
        icon: Icons.directions_car_filled_rounded,
      ),
      const AsmitaSelectItem(
        value: 'vehicle_3',
        label: 'Audi A6 • MH 02 EF 5678',
        subtitle: 'Secondary Sedan',
        icon: Icons.directions_car_filled_rounded,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: AsmitaSelectField<String>(
                  label: 'Select Vehicle',
                  value: selectedValue,
                  items: items,
                  onChanged: (val) {
                    setState(() => selectedValue = val);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('Select Vehicle'), findsOneWidget);
    expect(find.text('Select an option'), findsOneWidget);

    // Tap to open selection sheet
    await tester.tap(find.text('Select an option'));
    await tester.pumpAndSettle();

    // Verify it uses the official AsmitaBottomSheet component
    expect(find.byType(AsmitaBottomSheet), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Verify items are visible
    expect(find.text('Mercedes E220d • MH 04 AB 1234'), findsOneWidget);
    expect(find.text('Primary Executive Saloon'), findsOneWidget);
    expect(find.text('BMW 730Ld • MH 01 CZ 9999'), findsOneWidget);
    expect(find.text('Audi A6 • MH 02 EF 5678'), findsOneWidget);

    // Tap second option
    await tester.tap(find.text('BMW 730Ld • MH 01 CZ 9999'));
    await tester.pumpAndSettle();

    // Sheet should be dismissed
    expect(find.byType(AsmitaBottomSheet), findsNothing);

    // Field should reflect selected value
    expect(selectedValue, equals('vehicle_2'));
    expect(find.text('BMW 730Ld • MH 01 CZ 9999'), findsOneWidget);
  });
}
