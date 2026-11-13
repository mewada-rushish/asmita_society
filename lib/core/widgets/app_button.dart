import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/design_system.dart';

/// Centralized, async-aware button wrapper for AsmitA Society.
///
/// Features:
/// - Wraps any button style (Elevated, Outlined, Text, InkWell, or custom container)
/// - Self-manages async state when passed a `Future<void> Function()? onPressed`
/// - Accepts external `isLoading` state when needed
/// - Spinner REPLACES the existing icon (same size/position ~18-20px, 2px stroke width).
/// - If no icon exists, adds leading spinner next to the label.
/// - Guarantees ZERO width or height changes between idle and busy states.
/// - Disables re-taps while busy without looking grayed out.
/// - Minimum spinner visibility ~300ms to eliminate instant flash.
/// - Always safely resets in `finally` with `mounted` check.
enum AppButtonStyle {
  primaryElevated,
  secondaryOutlined,
  ghostText,
  dangerElevated,
  dangerOutlined,
  custom,
}

class AppButton extends StatefulWidget {
  final FutureOr<void> Function()? onPressed;
  final bool? isLoading;
  final String? label;
  final dynamic icon;
  final Widget? child;
  final AppButtonStyle style;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? borderSide;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final Key? buttonKey;

  const AppButton({
    super.key,
    required this.onPressed,
    this.isLoading,
    this.label,
    this.icon,
    this.child,
    this.style = AppButtonStyle.primaryElevated,
    this.width,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.foregroundColor,
    this.borderSide,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.textStyle,
    this.buttonKey,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _internalLoading = false;

  bool get _effectiveLoading => widget.isLoading ?? _internalLoading;

  Future<void> _handlePress() async {
    if (widget.onPressed == null || _effectiveLoading) return;

    HapticFeedback.lightImpact();

    if (widget.isLoading == null) {
      setState(() => _internalLoading = true);
    }

    final stopwatch = Stopwatch()..start();
    try {
      await widget.onPressed!();
    } finally {
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 300) {
        await Future.delayed(Duration(milliseconds: 300 - elapsed));
      }
      if (mounted && widget.isLoading == null) {
        setState(() => _internalLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide? border = widget.borderSide;

    switch (widget.style) {
      case AppButtonStyle.primaryElevated:
        final rawBg = widget.backgroundColor ?? AsmitaPalette.deepNavy;
        bg = (isDark && rawBg == AsmitaPalette.deepNavy) ? AsmitaPalette.deepNavyDark : rawBg;
        fg = widget.foregroundColor ?? Colors.white;
        break;
      case AppButtonStyle.secondaryOutlined:
        bg = widget.backgroundColor ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
        fg = widget.foregroundColor ?? (isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy);
        border ??= BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.0,
        );
        break;
      case AppButtonStyle.ghostText:
        bg = widget.backgroundColor ?? Colors.transparent;
        fg = widget.foregroundColor ?? (isDark ? const Color(0xFF93C5FD) : AsmitaPalette.deepNavy);
        break;
      case AppButtonStyle.dangerElevated:
        bg = widget.backgroundColor ?? (isDark ? const Color(0xFFEF4444) : AsmitaPalette.actionRed);
        fg = widget.foregroundColor ?? Colors.white;
        break;
      case AppButtonStyle.dangerOutlined:
        bg = widget.backgroundColor ?? (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.25) : const Color(0xFFFFF1F2));
        fg = widget.foregroundColor ?? (isDark ? const Color(0xFFF87171) : AsmitaPalette.actionRed);
        border ??= BorderSide(
          color: isDark ? const Color(0xFFBE123C).withValues(alpha: 0.35) : const Color(0xFFFECDD3),
          width: 1.0,
        );
        break;
      case AppButtonStyle.custom:
        final rawBg = widget.backgroundColor ?? AsmitaPalette.deepNavy;
        bg = (isDark && rawBg == AsmitaPalette.deepNavy) ? AsmitaPalette.deepNavyDark : rawBg;
        fg = widget.foregroundColor ?? Colors.white;
        break;
    }

    final spinner = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(fg),
      ),
    );

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      final textWidget = widget.label != null
          ? Text(
              widget.label!,
              style: widget.textStyle ??
                  TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.2,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const SizedBox.shrink();

      Widget? resolvedIcon;
      if (widget.icon is IconData) {
        resolvedIcon = Icon(widget.icon as IconData, size: 18, color: fg);
      } else if (widget.icon is Widget) {
        resolvedIcon = widget.icon as Widget;
      }

      if (_effectiveLoading) {
        if (resolvedIcon != null) {
          // Spinner REPLACES existing icon at same size/position
          content = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spinner,
              if (widget.label != null) ...[
                const SizedBox(width: 6),
                Flexible(child: textWidget),
              ],
            ],
          );
        } else {
          // Leading spinner next to label
          content = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spinner,
              if (widget.label != null) ...[
                const SizedBox(width: 6),
                Flexible(child: textWidget),
              ],
            ],
          );
        }
      } else {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (resolvedIcon != null) ...[
              resolvedIcon,
              if (widget.label != null) const SizedBox(width: 6),
            ],
            if (widget.label != null)
              Flexible(child: textWidget),
          ],
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: widget.buttonKey,
        onTap: (widget.onPressed == null || _effectiveLoading) ? null : _handlePress,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: border != null ? Border.fromBorderSide(border) : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}

