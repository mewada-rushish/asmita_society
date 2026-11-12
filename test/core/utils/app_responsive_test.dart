import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/constants/design_system.dart';

void main() {
  group('AppResponsive Breakpoints & Scaling Tests', () {
    testWidgets(
      'Reference phone (390dp width) has scaleFactor = 1.0 (zero visual deviation)',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        late bool isCompact;
        late bool isTablet;
        late double scale;
        late double font;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                isCompact = context.isCompact;
                isTablet = context.isTablet;
                scale = context.responsiveScale(100);
                font = context.responsiveFont(14);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(isCompact, isFalse);
        expect(isTablet, isFalse);
        expect(scale, closeTo(100.0, 0.01));
        expect(font, equals(14.0));
      },
    );

    testWidgets(
      'Compact phone (< 360dp, e.g. 320dp width) activates compact mode with clamped scaling',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 600 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        late bool isCompact;
        late bool isTablet;
        late double scale;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                isCompact = context.isCompact;
                isTablet = context.isTablet;
                scale = context.responsiveScale(100);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(isCompact, isTrue);
        expect(isTablet, isFalse);
        // 320 / 390 = ~0.82, but clamped at minScale = 0.88 -> scale = 88.0
        expect(scale, closeTo(88.0, 0.01));
      },
    );

    testWidgets(
      'Tablet (>= 600dp, e.g. 768dp iPad) activates tablet mode with BoundedCanvas container',
      (tester) async {
        tester.view.physicalSize = const Size(768 * 2, 1024 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        late bool isTablet;
        late double scale;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  isTablet = context.isTablet;
                  scale = context.responsiveScale(100);
                  return const BoundedCanvas(
                    maxWidth: 600,
                    child: SizedBox(key: Key('bounded_child'), height: 200),
                  );
                },
              ),
            ),
          ),
        );

        expect(isTablet, isTrue);
        // On tablets, scale is capped to 1.05 to prevent ballooning
        expect(scale, closeTo(105.0, 0.01));

        // Check that BoundedCanvas applied BoxConstraints with maxWidth: 600
        final constrainedBoxFinder = find.descendant(
          of: find.byType(BoundedCanvas),
          matching: find.byType(ConstrainedBox),
        );
        expect(constrainedBoxFinder, findsOneWidget);
        final constrainedBox = tester.widget<ConstrainedBox>(
          constrainedBoxFinder,
        );
        expect(constrainedBox.constraints.maxWidth, equals(600.0));
      },
    );

    testWidgets(
      'BoundedCanvas on phone renders unconstrained child directly without layout wrapper',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: BoundedCanvas(
                maxWidth: 600,
                child: SizedBox(key: Key('bounded_child'), height: 200),
              ),
            ),
          ),
        );

        // On phone, BoundedCanvas returns child directly, so no ConstrainedBox descendant is created inside BoundedCanvas
        final constrainedBoxInsideCanvas = find.descendant(
          of: find.byType(BoundedCanvas),
          matching: find.byType(ConstrainedBox),
        );
        expect(constrainedBoxInsideCanvas, findsNothing);
        expect(find.byKey(const Key('bounded_child')), findsOneWidget);
      },
    );
  });
}
