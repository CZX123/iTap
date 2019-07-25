import 'package:flutter/material.dart';

class AnimatedPlaceholder extends StatefulWidget {
  final Duration duration;
  final ShapeBorder shape;
  final Color startColor;
  final Color endColor;
  final double height;
  final double width;
  final BoxConstraints constraints;
  const AnimatedPlaceholder({
    Key key,
    this.duration = const Duration(seconds: 2),
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.startColor,
    this.endColor,
    this.height,
    this.width,
    this.constraints,
  }) : super(key: key);

  _AnimatedPlaceholderState createState() => _AnimatedPlaceholderState();
}

class _AnimatedPlaceholderState extends State<AnimatedPlaceholder>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  void statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animationController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _animationController.forward();
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(seconds: 1),
    )..addStatusListener(statusListener);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(statusListener);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _color = ColorTween(
      begin: widget.startColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(.05),
      end: widget.endColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(.1),
    ).animate(_animationController);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ClipPath(
          clipper: ShapeBorderClipper(
            shape: widget.shape ??
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
          ),
          child: Container(
            color: _color.value,
            height: widget.height,
            width: widget.width,
            constraints: widget.constraints,
          ),
        );
      },
    );
  }
}
