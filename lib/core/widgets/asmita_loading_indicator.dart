import 'package:flutter/material.dart';
import '../constants/design_system.dart';

class AsmitaLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const AsmitaLoadingIndicator({
    super.key,
    this.color,
    this.size = 28.0,
  });

  @override
  State<AsmitaLoadingIndicator> createState() => _AsmitaLoadingIndicatorState();
}

class _AsmitaLoadingIndicatorState extends State<AsmitaLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 6.283185307179586, // 2 * pi
          child: child,
        );
      },
      child: Icon(
        Icons.blur_on_rounded, // The branded dotted icon
        color: widget.color ?? AsmitaPalette.actionRed,
        size: widget.size,
      ),
    );
  }
}
