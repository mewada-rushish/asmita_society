import 'package:flutter/material.dart';
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
    );
  }
}
