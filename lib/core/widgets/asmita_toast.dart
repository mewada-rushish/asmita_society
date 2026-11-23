import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/design_system.dart';

enum AsmitaToastType { success, error, info }

class AsmitaToast {
  static void show(
    BuildContext context, {
    required String message,
    required AsmitaToastType type,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    double? bottomOffset,
  }) {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        bottomOffset: bottomOffset,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final AsmitaToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? bottomOffset;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
    this.bottomOffset,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    // react-hot-toast style snappy spring animation
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, 
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
    _dismissTimer = Timer(widget.duration, _reverseAndDismiss);
  }

  void _reverseAndDismiss() async {
    if (mounted && !_isDismissing) {
      _isDismissing = true;
      // Cancel timer if manually dismissed via tap
      _dismissTimer?.cancel();
      await _controller.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getTypeAttributes() {
    switch (widget.type) {
      case AsmitaToastType.success:
        return {
          'color': const Color(0xFF4CAF50), // Standard Success Green
          'icon': Icons.check_rounded,
        };
      case AsmitaToastType.error:
        return {
          'color': AsmitaPalette.actionRed, // #E21F26
          'icon': Icons.close_rounded,
        };
      case AsmitaToastType.info:
        return {
          'color': AsmitaPalette.deepNavy, // #27347B
          'icon': Icons.priority_high_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final attrs = _getTypeAttributes();
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBottomOffset = widget.bottomOffset ?? 32.0;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter, // Centers the floating pill
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding + effectiveBottomOffset),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _reverseAndDismiss, // Tap anywhere to close instantly
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(100), // Perfect pill shape
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Hugs content tightly
                      children: [
                        // Solid colored circular icon
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: attrs['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            attrs['icon'] as IconData,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Clean, single-line message
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : Colors.grey.shade900,
                            ),
                          ),
                        ),
                        if (widget.actionLabel != null && widget.onAction != null) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () {
                              widget.onAction!();
                              _reverseAndDismiss();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (attrs['color'] as Color).withValues(alpha: isDark ? 0.25 : 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.actionLabel!,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: attrs['color'] as Color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}