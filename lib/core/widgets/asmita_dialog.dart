import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  const AsmitaDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.contentPadding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AsmitaDialog(
        title: title,
        content: content,
        actions: actions,
        contentPadding: contentPadding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: textTheme.titleLarge?.copyWith(
                  color: AsmitaPalette.deepNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Padding(
              padding: contentPadding ?? EdgeInsets.zero,
              child: content,
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: action,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}