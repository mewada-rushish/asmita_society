import 'package:flutter/material.dart';
import '../constants/design_system.dart';

class AsmitaLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const AsmitaLoadingIndicator({
    super.key,
    this.color,
    this.size = 28.0,
    this.strokeWidth = 2.6,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AsmitaPalette.actionRed;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
      ),
    );
  }
}
