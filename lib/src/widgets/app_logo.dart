import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'icon/iTap-small.png',
          width: 30,
          height: 30,
        ),
        const SizedBox(
          width: 12,
        ),
        Text(
          'iTap',
          style: Theme.of(context).textTheme.title,
        ),
      ],
    );
  }
}
