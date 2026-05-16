import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShakeWrapper extends StatefulWidget {
  const ShakeWrapper({
    super.key,
    required this.shake,
    required this.child,
  });

  final bool shake;
  final Widget child;

  @override
  State<ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(ShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;
    final active = widget.shake && _controller.isAnimating;
    final dx = active ? math.sin(t * math.pi * 10) * 12 * (1 - t) : 0.0;

    return Transform.translate(
      offset: Offset(dx, 0),
      child: widget.child,
    );
  }
}
