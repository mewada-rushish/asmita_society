import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class AsmitaDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final Color? headerBgColor;
  final Color? titleColor;

  const AsmitaDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.contentPadding,
    this.headerBgColor,
    this.titleColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    EdgeInsetsGeometry? contentPadding,
    Color? headerBgColor,
    Color? titleColor,
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
        headerBgColor: headerBgColor,
        titleColor: titleColor,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 8.0, bottom: 8.0),
              decoration: BoxDecoration(
                color: headerBgColor ?? const Color(0xFFF8F8FB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: const Border(bottom: BorderSide(color: AsmitaPalette.borderGrey, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: textTheme.titleLarge?.copyWith(
                        color: titleColor ?? (headerBgColor != null ? Colors.white : AsmitaPalette.deepNavy),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                    color: titleColor ?? (headerBgColor != null ? Colors.white : AsmitaPalette.deepNavy),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          Flexible(
            child: RawScrollbar(
              thumbVisibility: true,
              thickness: 2.5,
              radius: const Radius.circular(8.0),
              thumbColor: AsmitaPalette.deepNavy.withValues(alpha: 0.15),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
                child: Padding(
                  padding: contentPadding ?? EdgeInsets.zero,
                  child: content,
                ),
              ),
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AsmitaPalette.borderGrey, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: action,
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}