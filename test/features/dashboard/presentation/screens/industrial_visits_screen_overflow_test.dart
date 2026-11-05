import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/constants/design_system.dart';

Widget buildTestDetailRow(
  BuildContext context, {
  required IconData icon,
  required String label,
  String? value,
  Widget? customValue,
  Widget? trailing,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: AsmitaPalette.textLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: customValue ??
                (value != null
                    ? Text(
                        value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink()),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing,
        ],
      ],
    ),
  );
}

void main() {
  testWidgets('Detail row does not overflow even at narrow width of 282px', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 282.0, // Exact width constraint from user's RenderFlex overflow exception
              child: Builder(
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildTestDetailRow(
                        context,
                        icon: Icons.access_time_rounded,
                        label: 'Scheduled Time',
                        value: '05 Nov 2026, 12:58 AM',
                      ),
                      buildTestDetailRow(
                        context,
                        icon: Icons.business_rounded,
                        label: 'Department',
                        value: 'Executive Campus Management HQ',
                      ),
                      buildTestDetailRow(
                        context,
                        icon: Icons.phone_outlined,
                        label: 'Visitor Contact',
                        value: '+91 98201 10101',
                        trailing: const Icon(Icons.phone, size: 16),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify no exception was thrown and all labels/values render
    expect(find.text('Scheduled Time'), findsOneWidget);
    expect(find.text('05 Nov 2026, 12:58 AM'), findsOneWidget);
    expect(find.text('Department'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
