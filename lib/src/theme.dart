import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkModeNotifier extends ValueNotifier<bool> {
  DarkModeNotifier(bool value) : super(value);
  @override
  set value(bool newValue) {
    super.value = newValue;
    if (Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
          newValue ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);
    }
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDark', newValue);
    });
  }
}

final lightThemeData = ThemeData(
  fontFamily: 'Jost*',
  primarySwatch: Colors.blue,
  accentColor: Colors.blue,
  buttonColor: Colors.blue[50],
  cursorColor: Colors.blue,
  textSelectionColor: Colors.blue,
  textSelectionHandleColor: Colors.blue,
  canvasColor: Colors.grey[50],
  cardColor: Colors.blue[50], // Used for dropdown background
  appBarTheme: AppBarTheme(
    color: Colors.blue,
  ),
  iconTheme: IconThemeData(
    color: Colors.black54,
  ),
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontFamily: 'Jost*',
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  ),
  buttonTheme: ButtonThemeData(
    alignedDropdown: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    buttonColor: Colors.blue[50],
    textTheme: ButtonTextTheme.accent,
  ),
  textTheme: textTheme,
);

final darkThemeData = ThemeData(
  fontFamily: 'Jost*',
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  accentColor: Colors.blue,
  buttonColor: Colors.blue[700],
  cursorColor: Colors.blue,
  textSelectionColor: Colors.blue,
  textSelectionHandleColor: Colors.blue,
  scaffoldBackgroundColor: Colors.grey[900],
  canvasColor: Colors.grey[900],
  cardColor: Colors.grey[850], // Used for dropdown background
  appBarTheme: AppBarTheme(color: Colors.grey[900]),
  iconTheme: IconThemeData(
    color: Colors.white,
  ),
  dialogTheme: DialogTheme(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontFamily: 'Jost*',
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
  ),
  buttonTheme: ButtonThemeData(
    alignedDropdown: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    buttonColor: Colors.blue[700],
    textTheme: ButtonTextTheme.normal,
  ),
  toggleableActiveColor: Colors.blue,
  textTheme: darkTextTheme,
);

final textTheme = TextTheme(
  body1: TextStyle(
    fontSize: 14,
  ),
  title: TextStyle(
    fontSize: 24,
  ),
  subtitle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.lightBlue[800],
  ),
  headline: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
  ),
  display3: TextStyle(
    fontSize: 60,
    color: Colors.black87,
  ),
  display2: TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  ),
  display1: TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  ),
);

final darkTextTheme = textTheme.copyWith(
  subtitle: textTheme.subtitle.copyWith(
    color: Colors.lightBlue[100],
  ),
  display3: textTheme.display3.copyWith(
    color: Colors.white,
  ),
  display2: textTheme.display2.copyWith(
    color: Colors.white,
  ),
  display1: textTheme.display1.copyWith(
    color: Colors.white,
  ),
);
