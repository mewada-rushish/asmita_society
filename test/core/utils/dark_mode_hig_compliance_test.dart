import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/app_button.dart';
import 'package:asmita_society/core/widgets/asmita_sub_header.dart';

void main() {
  group('Apple HIG Dark Mode Compliance Tests', () {
    test(
      'TC-HIG-01: Text Contrast Ratios strictly meet or exceed WCAG AA (4.5:1) on dark surfaces',
      () {
        // Calculate relative luminance per W3C formula
        double relativeLuminance(Color color) {
          double channel(double c) => c <= 0.03928
              ? c / 12.92
              : ((c + 0.055) / 1.055) * ((c + 0.055) / 1.055);
          return 0.2126 * channel(color.r) +
              0.7152 * channel(color.g) +
              0.0722 * channel(color.b);
        }

        double contrastRatio(Color fg, Color bg) {
          final l1 = relativeLuminance(fg);
          final l2 = relativeLuminance(bg);
          final lighter = l1 > l2 ? l1 : l2;
          final darker = l1 > l2 ? l2 : l1;
          return (lighter + 0.05) / (darker + 0.05);
        }

        // 1. Primary Text on System BG
        final primaryOnBase = contrastRatio(
          AsmitaPalette.textDarkModeMain,
          AsmitaPalette.systemBGDark,
        );
        expect(
          primaryOnBase,
          greaterThan(12.0),
        ); // Far exceeds 4.5:1 requirement

        // 2. Primary Text on Card Surface
        final primaryOnCard = contrastRatio(
          AsmitaPalette.textDarkModeMain,
          AsmitaPalette.surfaceDark,
        );
        expect(primaryOnCard, greaterThan(10.0));

        // 3. Secondary Text (Muted) on Card Surface (Apple secondary label >= 4.5:1)
        final secondaryOnCard = contrastRatio(
          AsmitaPalette.textDarkModeMuted,
          AsmitaPalette.surfaceDark,
        );
        expect(secondaryOnCard, greaterThan(5.0));

        // 4. Accent Blue tint on Card Surface
        final accentOnCard = contrastRatio(
          AsmitaPalette.deepNavyDark,
          AsmitaPalette.surfaceDark,
        );
        expect(accentOnCard, greaterThan(4.5));
      },
    );

    testWidgets(
      'TC-HIG-02: AsmitaThemeContext dynamically resolves Apple HIG tokens based on active theme',
      (tester) async {
        late Color lightPrimary;
        late Color lightText;
        late Color lightSurface;

        await tester.pumpWidget(
          MaterialApp(
            theme: AsmitaTheme.lightTheme,
            home: Builder(
              builder: (context) {
                lightPrimary = context.primaryColor;
                lightText = context.textPrimary;
                lightSurface = context.surfaceColor;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(lightPrimary, AsmitaPalette.deepNavy);
        expect(lightText, AsmitaPalette.textDark);
        expect(lightSurface, AsmitaPalette.surfaceLight);

        late Color darkPrimary;
        late Color darkText;
        late Color darkTextSec;
        late Color darkSurface;
        late Color darkElevated;

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(
          () => tester.platformDispatcher.clearPlatformBrightnessTestValue(),
        );

        await tester.pumpWidget(
          MaterialApp(
            key: const Key('dark_test_app'),
            theme: AsmitaTheme.lightTheme,
            darkTheme: AsmitaTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Builder(
              builder: (context) {
                darkPrimary = context.primaryColor;
                darkText = context.textPrimary;
                darkTextSec = context.textSecondary;
                darkSurface = context.surfaceColor;
                darkElevated = context.elevatedSurfaceColor;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(darkPrimary, AsmitaPalette.deepNavyDark);
        expect(darkText, AsmitaPalette.textDarkModeMain);
        expect(darkTextSec, AsmitaPalette.textDarkModeMuted);
        expect(darkSurface, AsmitaPalette.surfaceDark);
        expect(darkElevated, AsmitaPalette.surfaceElevatedDark);
      },
    );

    testWidgets(
      'TC-HIG-03: AppButton automatically adapts deepNavy background to deepNavyDark under Dark Mode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AsmitaTheme.lightTheme,
            darkTheme: AsmitaTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: AppButton(
                onPressed: () {},
                label: 'Save & Activate',
                backgroundColor: AsmitaPalette.deepNavy,
              ),
            ),
          ),
        );

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);

        final buttonContainer = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Save & Activate'),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = buttonContainer.decoration as BoxDecoration;
        expect(decoration.color, equals(AsmitaPalette.deepNavyDark));
      },
    );

    testWidgets(
      'TC-HIG-04: AsmitaSubHeader title renders crisp textDarkModeMain in dark mode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AsmitaTheme.lightTheme,
            darkTheme: AsmitaTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const Scaffold(
              body: AsmitaSubHeader(title: 'Visitor Approval Delegation'),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(
          find.text('Visitor Approval Delegation'),
        );
        expect(textWidget.style?.color, equals(const Color(0xFFF1F5F9)));

        final iconWidget = tester.widget<Icon>(find.byType(Icon));
        expect(iconWidget.color, equals(AsmitaPalette.deepNavyDark));
      },
    );

    testWidgets(
      'TC-HIG-05: Dark theme includes elevated surface styling for Dialogs and Sheets',
      (tester) async {
        final darkTheme = AsmitaTheme.darkTheme;
        expect(
          darkTheme.dialogTheme.backgroundColor,
          equals(AsmitaPalette.surfaceElevatedDark),
        );
        expect(
          darkTheme.bottomSheetTheme.backgroundColor,
          equals(AsmitaPalette.surfaceElevatedDark),
        );
        expect(
          darkTheme.popupMenuTheme.color,
          equals(AsmitaPalette.surfaceElevatedDark),
        );
      },
    );
  });
}
