import 'package:flutter/material.dart';

class CustomCrossFade extends StatelessWidget {
  final Widget child;
  final bool crossShrink;
  final Duration duration;
  const CustomCrossFade({
    Key key,
    @required this.child,
    this.crossShrink = true,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  static Widget layoutBuilder(
      Widget currentChild, List<Widget> previousChildren) {
    Widget element = IgnorePointer(
      child: Stack(
        children: previousChildren,
        alignment: Alignment.center,
      ),
    );
    if (currentChild != null)
      element = Stack(
        children: <Widget>[
          Positioned.fill(
            child: element,
          ),
          currentChild,
        ],
        alignment: Alignment.center,
      );
    return element;
  }

  Widget transitionBuilder(Widget child, Animation<double> animation) {
    final element = FadeTransition(
      opacity: animation,
      child: child,
    );
    if (crossShrink) {
      return ScaleTransition(
        scale: Tween<double>(begin: .95, end: 1).animate(animation),
        child: element,
      );
    }
    return element;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      transitionBuilder: transitionBuilder,
      layoutBuilder: layoutBuilder,
      switchInCurve: Interval(crossShrink ? .5 : .1, 1, curve: Curves.ease),
      switchOutCurve:
          Interval(crossShrink ? .5 : .1, 1, curve: Curves.decelerate),
      duration: duration,
      child: child,
    );
  }
}
