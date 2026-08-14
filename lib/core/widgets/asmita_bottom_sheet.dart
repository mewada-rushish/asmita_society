import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

/// A reusable function to show a styled modal bottom sheet.
///
/// [context]: The build context.
/// [title]: The title displayed at the top of the sheet.
/// [child]: The content widget to display inside the sheet.
/// [isScrollControlled]: Whether the sheet can be scrolled. Defaults to `true`.
/// [useRootNavigator]: Whether to use the root navigator. Defaults to `false`.
void showAsmitaBottomSheet({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.white,
    useRootNavigator: useRootNavigator,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => AsmitaBottomSheet(
      title: title,
      child: child,
    ),
  );
}

/// The main layout for the custom bottom sheet.
class AsmitaBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const AsmitaBottomSheet({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding > 0 ? bottomPadding : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AsmitaPalette.deepNavy,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            const SizedBox(height: 24),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}
