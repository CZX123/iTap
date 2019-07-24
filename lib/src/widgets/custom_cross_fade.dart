import 'package:flutter/material.dart';

class CustomCrossFade extends StatelessWidget {
  final Widget child;
  const CustomCrossFade({Key key, @required this.child}) : super(key: key);

  Widget transitionBuilder(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: Tween<double>(begin: .95, end: 1).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      transitionBuilder: transitionBuilder,
      switchInCurve: Interval(.5, 1, curve: Curves.ease),
      switchOutCurve: Interval(.5, 1, curve: Curves.decelerate),
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
