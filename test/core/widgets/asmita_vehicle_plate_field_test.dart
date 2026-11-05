import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/widgets/asmita_vehicle_plate_field.dart';

void main() {
  testWidgets('AsmitaIndianVehiclePlateField renders 2:2:4 boxes with IND badge', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsmitaIndianVehiclePlateField(
            controller: controller,
            label: 'Cab / Vehicle Registration Number',
          ),
        ),
      ),
    );

    expect(find.text('Cab / Vehicle Registration Number'), findsOneWidget);
    expect(find.text('IND'), findsOneWidget);
    expect(find.text('2 : 2 : 4'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('Auto-focus traversal across 2:2:4 boxes as user types', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsmitaIndianVehiclePlateField(
            controller: controller,
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);

    // Type 2 characters in Box 1 ('MH')
    await tester.enterText(fields.at(0), 'MH');
    await tester.pump();
    expect(controller.text, equals('MH'));

    // Type 2 characters in Box 2 ('02')
    await tester.enterText(fields.at(1), '02');
    await tester.pump();
    expect(controller.text, equals('MH 02'));

    // Type 4 characters in Box 3 ('1234')
    await tester.enterText(fields.at(2), '1234');
    await tester.pump();
    expect(controller.text, equals('MH 02 1234'));
  });

  testWidgets('Syncs from parent controller when initial value or external update occurs', (tester) async {
    final controller = TextEditingController(text: 'DL 01 9876');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsmitaIndianVehiclePlateField(
            controller: controller,
          ),
        ),
      ),
    );

    expect(controller.text, equals('DL 01 9876'));

    // Test external clear
    controller.clear();
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('Auto-distributes pasted full vehicle plate into 2:2:4 boxes', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsmitaIndianVehiclePlateField(
            controller: controller,
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);

    // Paste contiguous 'MH041234' into Box 1
    await tester.enterText(fields.at(0), 'MH041234');
    await tester.pump();

    expect(controller.text, equals('MH 04 1234'));
  });
}
