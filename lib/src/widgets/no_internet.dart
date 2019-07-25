import 'package:flutter/material.dart';

class InternetAvailibility {
  bool _noInternet = false;

  void showNoInternetSnackBar(BuildContext context, [ScaffoldState scaffoldState]) {
    if (_noInternet) return;
    _noInternet = true;
    ScaffoldState state = scaffoldState;
    state ??= Scaffold.of(context);
    state.showSnackBar(
      SnackBar(
        content: Text('No Internet'),
        duration: const Duration(hours: 1),
      ),
    );
  }

  void removeSnackbar(BuildContext context, [ScaffoldState scaffoldState]) {
    if (!_noInternet) return;
    _noInternet = false;
    ScaffoldState state = scaffoldState;
    state ??= Scaffold.of(context);
    state.removeCurrentSnackBar();
  }
}
