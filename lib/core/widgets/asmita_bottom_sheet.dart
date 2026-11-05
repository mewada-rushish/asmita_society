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
  double maxHeightFactor = 0.80,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: AsmitaBottomSheet(
        title: title,
        subtitle: subtitle,
        customHeader: customHeader,
        contentPadding: contentPadding,
        maxHeightFactor: maxHeightFactor,
        child: child,
      ),
    ),
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
    this.maxHeightFactor = 0.80,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = (screenHeight - keyboardInset).clamp(0.0, screenHeight);
    final maxLimit = availableHeight < 100.0 ? 100.0 : availableHeight;
    final maxSheetHeight = (availableHeight * maxHeightFactor).clamp(100.0, maxLimit);

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
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.03),
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.left,
                        style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ],
            ),
                Positioned(
                  top: -8,
                  right: -12,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 24),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ),
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
