import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/widgets/asmita_vehicle_plate_field.dart';

void main() {
  testWidgets('AsmitaIndianVehiclePlateField renders 2:2:2:4 boxes with IND badge and without 2:2:4 text badge', (tester) async {
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
    // Badge "2 : 2 : 4" should be completely removed
    expect(find.text('2 : 2 : 4'), findsNothing);
    // 4 boxes: State (2), RTO (2), Series (2), Unique Number (4)
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('Auto-focus traversal across 2:2:2:4 boxes as user types', (tester) async {
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

    // Type 2 characters in Box 2 ('04')
    await tester.enterText(fields.at(1), '04');
    await tester.pump();
    expect(controller.text, equals('MH 04'));

    // Type 2 characters in Box 3 ('AB')
    await tester.enterText(fields.at(2), 'AB');
    await tester.pump();
    expect(controller.text, equals('MH 04 AB'));

    // Type 4 characters in Box 4 ('1234')
    await tester.enterText(fields.at(3), '1234');
    await tester.pump();
    expect(controller.text, equals('MH 04 AB 1234'));
  });

  testWidgets('Syncs from parent controller when initial value or external update occurs', (tester) async {
    final controller = TextEditingController(text: 'DL 01 AZ 9876');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsmitaIndianVehiclePlateField(
            controller: controller,
          ),
        ),
      ),
    );

    expect(controller.text, equals('DL 01 AZ 9876'));

    // Test external clear
    controller.clear();
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('Auto-distributes pasted full vehicle plate into 2:2:2:4 boxes', (tester) async {
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

    // Paste contiguous 'MH04AB1234' into Box 1
    await tester.enterText(fields.at(0), 'MH04AB1234');
    await tester.pump();

    expect(controller.text, equals('MH 04 AB 1234'));
  });
}
