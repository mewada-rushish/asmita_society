import 'package:flutter/material.dart';
import 'package:asmita_society/core/constants/design_system.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeReply;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onSwipeReply,
    required this.isMe,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0.0;
  final double _maxDragDistance = 70.0; // Hard cap on how far you can slide
  final double _triggerDistance = 40.0; // Distance required to trigger the reply

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
      if (widget.isMe) {
        if (_dragExtent > 0) _dragExtent = 0; // Only allow sliding left
        if (_dragExtent < -_maxDragDistance) {
          _dragExtent =
              -_maxDragDistance + ((_dragExtent + _maxDragDistance) * 0.1);
        }
      } else {
        if (_dragExtent < 0) _dragExtent = 0; // Only allow sliding right
        if (_dragExtent > _maxDragDistance) {
          _dragExtent =
              _maxDragDistance + ((_dragExtent - _maxDragDistance) * 0.1);
        }
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isMe) {
      if (_dragExtent <= -_triggerDistance) {
        widget.onSwipeReply();
      }
    } else {
      if (_dragExtent >= _triggerDistance) {
        widget.onSwipeReply();
      }
    }

    _animation = Tween<double>(
      begin: _dragExtent,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward(from: 0).then((_) {
      _dragExtent = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final offset = _controller.isAnimating ? _animation.value : _dragExtent;
    final absOffset = offset.abs();

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          if (absOffset > 5)
            Positioned(
              left: widget.isMe
                  ? null
                  : (absOffset / _maxDragDistance).clamp(0.0, 1.0) * 16,
              right: widget.isMe
                  ? (absOffset / _maxDragDistance).clamp(0.0, 1.0) * 16
                  : null,
              child: Transform.scale(
                scale: (absOffset / _maxDragDistance).clamp(0.0, 1.0),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.reply_rounded,
                    color: AsmitaPalette.deepNavy,
                    size: 20,
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(offset, 0), child: widget.child),
        ],
      ),
    );
  }
}
