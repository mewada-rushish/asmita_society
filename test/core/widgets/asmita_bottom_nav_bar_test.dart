import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';

void main() {
  testWidgets(
    'FAB clearance is consistently 16px above AsmitaBottomNavBar across all device insets',
    (tester) async {
      for (final double bottomInset in [0.0, 34.0, 48.0]) {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0; // 540 x 1200 logical
        tester.view.viewPadding = FakeViewPadding(
          bottom: bottomInset * 2.0,
        );
        tester.view.padding = FakeViewPadding(
          bottom: bottomInset * 2.0,
        );
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewPadding);
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
                        bottom: AsmitaBottomNavBar.fabBottomPadding(
                          innerContext,
                        ),
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

        debugPrint(
          'bottomInset: $bottomInset | navRect.top: ${navRect.top} | fabRect.bottom: ${fabRect.bottom} | clearance: $clearance',
        );

        // Clearance between FAB bottom and navbar top must be exactly 16px
        expect(clearance, closeTo(16.0, 0.5));
      }
    },
  );
}
