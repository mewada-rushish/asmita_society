import 'package:flutter/material.dart';

class AsmitaAnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AsmitaAnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<AsmitaAnimatedIndexedStack> createState() => _AsmitaAnimatedIndexedStackState();
}

class _AsmitaAnimatedIndexedStackState extends State<AsmitaAnimatedIndexedStack> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentIndex;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AsmitaAnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (index) {
        final isCurrent = index == _currentIndex;
        final isPrevious = index == _previousIndex;
        final bool isAnimating = _currentIndex != _previousIndex;

        Animation<Offset> position;
        Animation<double> opacity;
        bool offstage = true;

        if (isCurrent && isAnimating) {
          // Entering
          position = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
          opacity = const AlwaysStoppedAnimation(1.0);
          offstage = false;
        } else if (isPrevious && isAnimating) {
          // Exiting
          position = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.3, 0.0))
              .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
          opacity = Tween<double>(begin: 1.0, end: 0.0)
              .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
          offstage = false;
        } else if (isCurrent) {
          // Active and Settled
          position = const AlwaysStoppedAnimation(Offset.zero);
          opacity = const AlwaysStoppedAnimation(1.0);
          offstage = false;
        } else {
          // Inactive and Settled
          position = const AlwaysStoppedAnimation(Offset.zero);
          opacity = const AlwaysStoppedAnimation(1.0);
          offstage = true;
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            bool currentOffstage = offstage;
            // Force the previous child offstage once the animation fully completes
            if (isPrevious && _controller.isCompleted && !isCurrent) {
              currentOffstage = true;
            }

            return Offstage(
              offstage: currentOffstage,
              child: SlideTransition(
                position: position,
                child: FadeTransition(
                  opacity: opacity,
                  child: child,
                ),
              ),
            );
          },
          child: widget.children[index], // The actual screen is passed as a child, keeping its state intact
        );
      }),
    );
  }
}
