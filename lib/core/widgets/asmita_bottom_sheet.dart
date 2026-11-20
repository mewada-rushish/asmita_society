import 'package:flutter/material.dart';


/// A reusable function to show a styled modal bottom sheet.
///
/// [context]: The build context.
/// [title]: The title displayed at the top of the sheet.
/// [subtitle]: Optional subtitle displayed below the title.
/// [customHeader]: Optional custom header widget replacing standard title/subtitle.
/// [child]: The content widget to display inside the sheet.
/// [isScrollControlled]: Whether the sheet can be scrolled. Defaults to `true`.
/// [useRootNavigator]: Whether to use the root navigator. Defaults to `false`.
/// [isDismissible]: Whether tapping on the barrier dismisses the sheet. Defaults to `true`.
/// [enableDrag]: Whether the sheet can be dismissed via downward drag. Defaults to `true`.
/// [contentPadding]: Content padding. Defaults to `EdgeInsets.fromLTRB(24, 16, 24, 16)`.
/// [maxHeightFactor]: Maximum ratio of screen height the sheet can occupy. Defaults to `0.80` (80%).
Future<T?> showAsmitaBottomSheet<T>({
  required BuildContext context,
  String title = '',
  String? subtitle,
  Widget? customHeader,
  required Widget child,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  EdgeInsetsGeometry? contentPadding,
  double maxHeightFactor = 0.85,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.95,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final viewInsets = MediaQuery.of(ctx).viewInsets;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: AsmitaBottomSheet(
          title: title,
          subtitle: subtitle,
          customHeader: customHeader,
          contentPadding: contentPadding,
          maxHeightFactor: maxHeightFactor,
          child: child,
        ),
      );
    },
  );
}

/// The main layout for the custom bottom sheet.
class AsmitaBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? customHeader;
  final Widget child;
  final EdgeInsetsGeometry? contentPadding;
  final double maxHeightFactor;

  const AsmitaBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.customHeader,
    this.contentPadding,
    this.maxHeightFactor = 0.85,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardInset > 0;

    // When keyboard is open, allow up to 95% of the visible viewport so the user gets ample space to see inputs.
    // When keyboard is closed, respect the default maxHeightFactor (e.g. 85%).
    final effectiveFactor = isKeyboardOpen ? 0.95 : maxHeightFactor;
    final availableHeight = (screenHeight - keyboardInset).clamp(150.0, screenHeight);
    final maxSheetHeight = (availableHeight * effectiveFactor).clamp(150.0, availableHeight);

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxSheetHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // White Header with Shadow
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (customHeader != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      customHeader!,
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),
                ] else if (title.isNotEmpty || subtitle != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                textAlign: subtitle != null ? TextAlign.left : TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                textAlign: TextAlign.left,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Content Area (Grey Background from the BottomSheet itself)
          Flexible(
            child: SafeArea(
              top: false,
              maintainBottomViewPadding: true,
              child: Padding(
                padding: contentPadding ?? const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
