import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class TextMessageBubble extends StatelessWidget {
  final String content;

  const TextMessageBubble({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 13,
            height: 1.4,
            color: AsmitaPalette.textDark,
          ),
    );
  }
}
