import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';

void main() {
  testWidgets('Check FAB position relative to BottomNavBar with new fabBottomPadding', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0; // 540 x 1200 logical
    tester.view.padding = const FakeViewPadding(bottom: 68); // 34 pt device bottom inset
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

    // FAB must be strictly above the bottom navigation bar by at least 12px
    expect(navRect.top - fabRect.bottom, greaterThanOrEqualTo(12.0));
  });
}
