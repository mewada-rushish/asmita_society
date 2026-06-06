import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final bool showCloseButton;

  const AsmitaDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.contentPadding,
    this.showCloseButton = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    EdgeInsetsGeometry? contentPadding,
    bool showCloseButton = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: AsmitaPalette.deepNavy.withValues(alpha: 0.4),
      builder: (context) => AsmitaDialog(
        title: title,
        content: content,
        actions: actions,
        contentPadding: contentPadding,
        showCloseButton: showCloseButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AsmitaPalette.systemBG,
              border: const Border(
                bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: title != null
                      ? Text(
                          title!,
                          style: const TextStyle(
                            color: AsmitaPalette.deepNavy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Montserrat',
                            letterSpacing: 0.3,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (showCloseButton)
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AsmitaPalette.borderGrey),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: AsmitaPalette.deepNavy),
                    ),
                  ),
              ],
            ),
          ),
          // Flexible content viewport area
          Flexible(
            child: SingleChildScrollView(
              padding: contentPadding ?? const EdgeInsets.all(20),
              child: content,
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AsmitaPalette.borderGrey, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!.map((action) => Padding(padding: const EdgeInsets.only(left: 10), child: action)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}