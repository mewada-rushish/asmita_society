import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/industrial_visit_card.dart';
import 'package:asmita_society/features/visitor_management/presentation/widgets/industrial_system_states.dart';

// Helper for WCAG 2.1 relative luminance
double _sRGBtoLinear(double c) {
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _sRGBtoLinear(color.r);
  final g = _sRGBtoLinear(color.g);
  final b = _sRGBtoLinear(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Phase 9: IndustrialVisitCard & System States Tests', () {
    final mockVisit = IndustrialVisitModel(
      id: 101,
      requestNumber: 'AH-2026-0042',
      propertyId: 114,
      visitorName: 'Rajesh Sharma',
      arrivalMode: 'FOUR_WHEELER',
      vehicleNumber: 'MH04AB1234',
      departmentName: 'Civil Engineering',
      hostName: 'Suresh Patil',
      status: IndustrialVisitStatus.awaitingHost,
      cabinNumber: 'C-201',
      deskNumber: 'D-14',
      purpose: 'Structural Audit Consultation',
    );

    testWidgets('IndustrialVisitCard renders complete content hierarchy and vehicle tag',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IndustrialVisitCard(
              visit: mockVisit,
              onPrimaryAction: () {},
              primaryActionLabel: 'Approve',
              onSecondaryAction: () {},
              secondaryActionLabel: 'Acknowledge',
              onDestructiveAction: () {},
              destructiveActionLabel: 'Reject',
            ),
          ),
        ),
      );

      // Verify Hierarchy Content
      expect(find.text('Rajesh Sharma'), findsOneWidget);
      expect(find.text('AH-2026-0042'), findsOneWidget);
      expect(find.text('Awaiting Host'), findsOneWidget);
      expect(find.text('Civil Engineering'), findsOneWidget);
      expect(find.text('Suresh Patil'), findsOneWidget);
      expect(find.text('Cabin: C-201'), findsOneWidget);
      expect(find.text('Desk: D-14'), findsOneWidget);
      expect(find.text('Structural Audit Consultation'), findsOneWidget);
      expect(find.text('[Vehicle: MH04AB1234]'), findsOneWidget);

      // Verify Strict Action Order Presence
      expect(find.byKey(const ValueKey('visit_card_primary_action')), findsOneWidget);
      expect(find.byKey(const ValueKey('visit_card_secondary_action')), findsOneWidget);
      expect(find.byKey(const ValueKey('visit_card_destructive_action')), findsOneWidget);
    });

    testWidgets('IndustrialVisitCard triggers primary, secondary and destructive actions',
        (tester) async {
      bool primaryCalled = false;
      bool secondaryCalled = false;
      bool destructiveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IndustrialVisitCard(
              visit: mockVisit,
              onPrimaryAction: () => primaryCalled = true,
              primaryActionLabel: 'Approve',
              onSecondaryAction: () => secondaryCalled = true,
              secondaryActionLabel: 'Acknowledge',
              onDestructiveAction: () => destructiveCalled = true,
              destructiveActionLabel: 'Reject',
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('visit_card_primary_action')));
      expect(primaryCalled, isTrue);

      await tester.tap(find.byKey(const ValueKey('visit_card_secondary_action')));
      expect(secondaryCalled, isTrue);

      await tester.tap(find.byKey(const ValueKey('visit_card_destructive_action')));
      expect(destructiveCalled, isTrue);
    });

    testWidgets('IndustrialSystemStates widgets render properly', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const IndustrialShimmerLoadingCard(count: 2),
                  const IndustrialEmptyStateWidget(
                    title: 'No Pending Visits',
                    message: 'All visitor entries have been processed.',
                  ),
                  IndustrialErrorStateWidget(
                    title: 'Network Error',
                    message: 'Could not connect to AsmitA House API.',
                    onRetry: () => retryPressed = true,
                  ),
                  const IndustrialModuleDisabledWidget(
                    moduleName: 'Vehicle Draft Intake',
                    reason: 'Gate 2 parking slips are disabled today.',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Let shimmer animation pump
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No Pending Visits'), findsOneWidget);
      expect(find.text('Network Error'), findsOneWidget);
      expect(find.text('Vehicle Draft Intake Disabled'), findsOneWidget);

      // Ensure visible and tap retry
      await tester.ensureVisible(find.text('Try Again'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Try Again'));
      expect(retryPressed, isTrue);
    });

    test('WCAG AA Contrast: All 11 IndustrialVisitStatus badges meet >= 4.5:1 ratio', () {
      for (final status in IndustrialVisitStatus.values) {
        // Dark Mode
        final darkContrast = _contrastRatio(status.darkFillColor, status.darkTextColor);
        expect(
          darkContrast >= 4.5,
          isTrue,
          reason: 'Status ${status.name} Dark Mode contrast must be >= 4.5:1, got: $darkContrast',
        );

        // Light Mode
        final lightContrast = _contrastRatio(status.lightFillColor, status.lightTextColor);
        expect(
          lightContrast >= 4.5,
          isTrue,
          reason: 'Status ${status.name} Light Mode contrast must be >= 4.5:1, got: $lightContrast',
        );
      }
    });
  });
}
