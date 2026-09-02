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
  String title = '',
  String? subtitle,
  Widget? customHeader,
  required Widget child,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: AsmitaPalette.systemBG,
    useRootNavigator: useRootNavigator,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => AsmitaBottomSheet(
      title: title,
      subtitle: subtitle,
      customHeader: customHeader,
      child: child,
    ),
  );
}

/// The main layout for the custom bottom sheet.
class AsmitaBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? customHeader;
  final Widget child;

  const AsmitaBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.customHeader,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, // Enforce space above the sheet
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // White Header with Shadow
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
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
                if (customHeader != null) ...[
                  const SizedBox(height: 16),
                  customHeader!,
                ] else ...[
                  if (title.isNotEmpty || subtitle != null) const SizedBox(height: 24),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      textAlign: subtitle != null ? TextAlign.left : TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AsmitaPalette.deepNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.left,
                        style: textTheme.bodyMedium?.copyWith(color: AsmitaPalette.textLight),
                      ),
                    ),
                ],
              ],
            ),
                Positioned(
                  top: -8,
                  right: -12,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AsmitaPalette.textLight, size: 24),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
          ),
          // Content Area (Grey Background from the BottomSheet itself)
          Flexible(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
