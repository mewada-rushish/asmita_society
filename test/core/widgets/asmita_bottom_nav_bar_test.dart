import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';

void main() {
  testWidgets('Check FAB position relative to BottomNavBar with new fabBottomPadding', (tester) async {
    for (final double bottomInset in [0.0, 34.0, 48.0]) {
      tester.view.physicalSize = Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0; // 540 x 1200 logical
      tester.view.padding = FakeViewPadding(bottom: bottomInset * 2.0); // device bottom inset
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            extendBody: true,
            body: Builder(
              builder: (innerContext) {
                return Scaffold(
                  floatingActionButton: Padding(
                    padding: EdgeInsets.only(
                      bottom: AsmitaBottomNavBar.fabBottomPadding(innerContext),
                    ),
                    child: FloatingActionButton.extended(
                      onPressed: () {},
                      label: const Text('Schedule'),
                    ),
                  ),
                  body: Container(color: Colors.white),
                );
              },
            ),
            bottomNavigationBar: AsmitaBottomNavBar(
              currentIndex: 1,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      final navFinder = find.byType(AsmitaBottomNavBar);

      final fabRect = tester.getRect(fabFinder);
      final navRect = tester.getRect(navFinder);

      final clearance = navRect.top - fabRect.bottom;

      // FAB must hover cleanly 16px above the navigation bar, within [12.0, 20.0] range
      expect(clearance, greaterThanOrEqualTo(12.0));
      expect(clearance, lessThanOrEqualTo(20.0));
    }
  });
}
