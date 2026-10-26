import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_delivery_entry_screen.dart';
import 'package:asmita_society/features/visitor_management/presentation/screens/guard_pass_check_in_screen.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';

class MockIndustrialVisitBloc extends Mock implements IndustrialVisitBloc {}

void main() {
  late MockIndustrialVisitBloc mockIndustrialBloc;
  late StreamController<IndustrialVisitState> industrialStateController;

  final sampleVisit = IndustrialVisitModel(
    id: 42,
    requestNumber: 'REQ-2026-0042',
    propertyId: 1,
    visitorName: 'Rajesh Kumar',
    status: IndustrialVisitStatus.approved,
    hostName: 'Rushish Mewada',
    passCode: 'PASS-0042',
    arrivalMode: 'walk_in',
    departmentName: 'Engineering',
    verifiedOnSite: false,
  );

  final checkedInVisit = IndustrialVisitModel(
    id: 43,
    requestNumber: 'REQ-2026-0043',
    propertyId: 1,
    visitorName: 'Anita Roy',
    status: IndustrialVisitStatus.checkedIn,
    hostName: 'Aditi Sharma',
    passCode: 'PASS-0043',
    arrivalMode: 'vehicle',
    vehicleNumber: 'MH-04-AB-1234',
    departmentName: 'Accounts',
    verifiedOnSite: true,
  );

  setUpAll(() {
    registerFallbackValue(const CreateDeliveryIntakeEvent(
      deliveryCompany: 'Amazon',
      recipientName: 'Test',
      gateId: 1,
    ));
    registerFallbackValue(const CheckInPassEvent(visitId: 1, gateId: 1));
    registerFallbackValue(const CheckOutPassEvent(visitId: 1, gateId: 1));
  });

  setUp(() {
    mockIndustrialBloc = MockIndustrialVisitBloc();
    industrialStateController = StreamController<IndustrialVisitState>.broadcast();

    when(() => mockIndustrialBloc.stream).thenAnswer((_) => industrialStateController.stream);
    when(() => mockIndustrialBloc.state).thenReturn(
      IndustrialVisitState(
        status: IndustrialVisitBlocStatus.loaded,
        visits: [sampleVisit, checkedInVisit],
      ),
    );
    when(() => mockIndustrialBloc.close()).thenAnswer((_) async {});
    when(() => mockIndustrialBloc.add(any())).thenReturn(null);
  });

  tearDown(() async {
    await industrialStateController.close();
  });

  void setMobileScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('GuardDeliveryEntryScreen Production Widget Tests', () {
    Widget buildDeliveryScreen() {
      return BlocProvider<IndustrialVisitBloc>.value(
        value: mockIndustrialBloc,
        child: const MaterialApp(
          home: GuardDeliveryEntryScreen(gateId: 1),
        ),
      );
    }

    testWidgets('renders initial UI with courier dropdown and recipient fields', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildDeliveryScreen());
      await tester.pump();

      expect(find.text('Guard Delivery Intake'), findsOneWidget);
      expect(find.text('Delivery Flow: Guard captures delivery details. Recipient will be alerted to collect at gate or allow in.'), findsOneWidget);
      expect(find.text('Courier / Delivery Partner:'), findsOneWidget);
      expect(find.text('Amazon'), findsOneWidget);
      expect(find.text('Recipient Full Name'), findsOneWidget);
      expect(find.text('Log Delivery & Alert Recipient'), findsOneWidget);
    });

    testWidgets('shows custom courier input when Other is selected', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildDeliveryScreen());
      await tester.pump();

      await tester.tap(find.text('Amazon'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();

      expect(find.text('Specify Courier Name'), findsOneWidget);
    });

    testWidgets('shows warning snackbar when recipient name is empty on submit', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildDeliveryScreen());
      await tester.pump();

      await tester.tap(find.text('Log Delivery & Alert Recipient'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Courier company and recipient name are required.'), findsOneWidget);
    });

    testWidgets('dispatches CreateDeliveryIntakeEvent when fields are valid', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildDeliveryScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).last, 'Dr. Homi Bhabha');
      await tester.tap(find.text('Log Delivery & Alert Recipient'));
      await tester.pump();

      verify(() => mockIndustrialBloc.add(any(that: isA<CreateDeliveryIntakeEvent>()))).called(1);
    });

    testWidgets('shows success snackbar and pops route on actionSuccess', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider<IndustrialVisitBloc>.value(
                    value: mockIndustrialBloc,
                    child: const GuardDeliveryEntryScreen(gateId: 1),
                  ),
                ),
              ),
              child: const Text('Open Intake'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Intake'));
      await tester.pumpAndSettle();

      expect(find.text('Guard Delivery Intake'), findsOneWidget);

      industrialStateController.add(const IndustrialVisitState(
        status: IndustrialVisitBlocStatus.actionSuccess,
        successMessage: 'Package accepted at gate',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Package accepted at gate'), findsAtLeastNWidgets(1));
    });
  });

  group('GuardPassCheckInScreen Production Widget Tests', () {
    Widget buildPassScreen({int gateId = 1}) {
      return BlocProvider<IndustrialVisitBloc>.value(
        value: mockIndustrialBloc,
        child: MaterialApp(
          home: GuardPassCheckInScreen(gateId: gateId),
        ),
      );
    }

    testWidgets('renders Gate 1 title and pedestrian terminal banner', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildPassScreen(gateId: 1));
      await tester.pump();

      expect(find.text('Gate 1 Pedestrian Pass Verification'), findsOneWidget);
      expect(find.text('Active Terminal: Gate 1 (Pedestrians & Walk-ins Only)'), findsOneWidget);
      expect(find.text('Digital Pass Code'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
    });

    testWidgets('renders Gate 2 title and vehicle terminal banner', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildPassScreen(gateId: 2));
      await tester.pump();

      expect(find.text('Gate 2 Parking Pass Verification'), findsOneWidget);
      expect(find.text('Active Terminal: Gate 2 (Vehicles & Parking Only)'), findsOneWidget);
    });

    testWidgets('matches pass code and reveals visitor card with Check In button', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildPassScreen(gateId: 1));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'PASS-0042');
      await tester.tap(find.text('Verify'));
      await tester.pump();

      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Pass: PASS-0042 • REQ-2026-0042'), findsOneWidget);
      expect(find.text('Host / Executive'), findsOneWidget);
      expect(find.text('Rushish Mewada'), findsOneWidget);
      expect(find.text('Check In (Confirm On-Site)'), findsOneWidget);

      // Tap Check In
      await tester.tap(find.text('Check In (Confirm On-Site)'));
      await tester.pump();

      verify(() => mockIndustrialBloc.add(any(that: isA<CheckInPassEvent>()))).called(1);
    });

    testWidgets('matches checkedIn pass code and reveals Check Out button', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildPassScreen(gateId: 2));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'PASS-0043');
      await tester.tap(find.text('Verify'));
      await tester.pump();

      expect(find.text('Anita Roy'), findsOneWidget);
      expect(find.text('MH-04-AB-1234'), findsOneWidget);
      expect(find.text('Check Out (Exit Scan)'), findsOneWidget);

      // Tap Check Out
      await tester.tap(find.text('Check Out (Exit Scan)'));
      await tester.pump();

      verify(() => mockIndustrialBloc.add(any(that: isA<CheckOutPassEvent>()))).called(1);
    });

    testWidgets('triggers lockout after 3 consecutive failed verification attempts', (tester) async {
      setMobileScreen(tester);
      await tester.pumpWidget(buildPassScreen(gateId: 1));
      await tester.pump();

      final verifyBtn = find.text('Verify');
      final inputField = find.byType(TextField);

      // Attempt 1
      await tester.enterText(inputField, 'WRONG-1');
      await tester.tap(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pass code not found or expired. Failed attempt 1/3.'), findsOneWidget);

      // Attempt 2
      await tester.enterText(inputField, 'WRONG-2');
      await tester.tap(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pass code not found or expired. Failed attempt 2/3.'), findsOneWidget);

      // Attempt 3
      await tester.enterText(inputField, 'WRONG-3');
      await tester.tap(verifyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Security Lockout: 3 failed attempts. Terminal locked for 5 minutes.'), findsOneWidget);
      expect(find.text('Terminal locked out due to repeated invalid attempts. Please contact Admin or wait for lockout timer.'), findsOneWidget);
    });
  });
}
