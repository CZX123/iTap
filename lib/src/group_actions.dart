import 'dart:async';
import 'dart:convert';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'generate_code.dart';
import 'group_data.dart';
import 'theme.dart';
import 'user_data.dart';
import 'widgets/no_internet.dart';
import 'wifi.dart';
import 'widgets/custom_dialog.dart';

class GroupActions extends StatelessWidget {
  static final _connectivity = Connectivity();
  final GroupDetails groupDetails;
  final VoidCallback getGroupDetails;
  const GroupActions({
    Key key,
    @required this.groupDetails,
    @required this.getGroupDetails,
  }) : super(key: key);

  Future<bool> verifyWifi(BuildContext context) async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Error while initialising network: $e');
      return false;
    }
    if (result != ConnectivityResult.wifi) {
      Provider.of<NetworkNotifier>(context, listen: false)
          .updateNetwork(result);
      return false;
    }
    String name;
    String mac;
    try {
      name = await _connectivity.getWifiName();
    } catch (e) {
      print('Failed to get wifi name: $e');
      return false;
    }
    try {
      mac = await _connectivity.getWifiBSSID();
    } catch (e) {
      print('Failed to get mac address: $e');
      return false;
    }
    if (mac == '00:00:00:00:00:00') {
      name = null;
      mac = null;
    }
    Provider.of<NetworkNotifier>(context, listen: false)
        .updateNetwork(result, name, mac);
    // The logic here may be confusing, but it works.
    // Everything here is just a negation of the original logic.
    return !groupDetails.wifiList.every((wifiDetails) {
      return wifiDetails.ssid != name ||
          wifiDetails.mac.substring(1, wifiDetails.macDigits) !=
                  mac.substring(1, wifiDetails.macDigits) &&
              wifiDetails.mac != 'all';
    });
  }

  void takeAttendance(
    BuildContext context,
    bool takenWithWifi,
    String code,
  ) async {
    bool wifiIsLegit = false;
    if (takenWithWifi) wifiIsLegit = await verifyWifi(context);
    final userDataNotifier = Provider.of<UserDataNotifier>(context);
    if (takenWithWifi && wifiIsLegit || code != '') {
      if (takenWithWifi)
        print('Taking attendance with WiFi...');
      else
        print('Taking attendance with code: $code...');
      final checkOut = groupDetails.checkTakenToday == 0;
      if (takenWithWifi && checkOut && groupDetails.checkOutDialog == 1) {
        final result = await showCustomDialog<bool>(
          context: context,
          dialog: AlertDialog(
            title: Text('Confirmation'),
            content: Text('Are you sure you want to check out now?'),
            actions: <Widget>[
              FlatButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('NO'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              FlatButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('YES'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        );
        if (result == null || !result) {
          print('Attendance taking cancelled');
          return;
        }
      }
      try {
        final response =
            await http.post('https://itap.luweiqi.com/app/index.php', body: {
          'userkey': userDataNotifier.userKey,
          'action': 'takeAttendance',
          'org': userDataNotifier.org,
          'group': convertGroupName(groupDetails.groupName),
          'username': userDataNotifier.username,
          'code': code,
          'checkOut': groupDetails.checkTakenToday == 0 ? 'true' : 'false',
        });
        if (response.statusCode == 200) {
          Provider.of<InternetAvailabilityNotifier>(context, listen: false)
              .value = true;
          print('Response: ${response.body}');
          final Map<String, dynamic> parsedJson = jsonDecode(response.body);
          if (parsedJson['success'] == 1) {
            getGroupDetails();
          } else {
            showCustomDialog(
              context: context,
              dialog: AlertDialog(
                title: Text('Error'),
                content: Text(parsedJson['error_message']),
                actions: <Widget>[
                  FlatButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          }
        } else {
          print('Error ${response.statusCode} while taking attendance');
        }
      } catch (e) {
        print('Error while taking attendance: $e');
        showCustomDialog(
          context: context,
          dialog: AlertDialog(
            title: const Text('Error'),
            content: const Text('No Internet.'),
            actions: <Widget>[
              FlatButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
        // Provider.of<InternetAvailabilityNotifier>(context, listen: false)
        //     .value = false;
        // // Take attendance again if there is an error
        // Future.delayed(const Duration(seconds: 1), () {
        //   takeAttendance(context, takenWithWifi, code);
        // });
      }
    } else if (takenWithWifi && !wifiIsLegit) {
      showCustomDialog(
        context: context,
        dialog: AlertDialog(
          title: Text('Error'),
          content: Text(
              Provider.of<NetworkNotifier>(context, listen: false).errorText +
                  '.'),
          actions: <Widget>[
            FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    void _updateAppBar() {
      Brightness statusBarBrightness;
      if (Provider.of<DarkModeNotifier>(context).value) {
        statusBarBrightness = Brightness.dark;
      } else {
        statusBarBrightness = Brightness.light;
      }
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
          .copyWith(statusBarBrightness: statusBarBrightness));
    }

    void typeCode() async {
      var code = await showCustomDialog<String>(
        context: context,
        dialog: TypeCodeDialog(
          groupDetails: groupDetails,
        ),
      );
      if (code == null) return;
      takeAttendance(context, false, code);
    }

    void scanCode() async {
      try {
        String code = await BarcodeScanner.scan();
        takeAttendance(context, false, code);
      } on PlatformException catch (e) {
        if (e.code == BarcodeScanner.CameraAccessDenied) {
          showCustomDialog(
            context: context,
            dialog: AlertDialog(
              title: Text('Error'),
              content: Text('Camera permission required.'),
              actions: <Widget>[
                FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        } else {
          print('Unknown error while trying to scan code: $e');
        }
      } on FormatException {
        print('User pressed back before scanning code.');
      } catch (e) {
        print('Unknown error while trying to scan code: $e');
      }
    }

    void markWithWifi() {
      takeAttendance(context, true, '');
    }

    void wifiLongPress() {
      final networkNotifier =
          Provider.of<NetworkNotifier>(context, listen: false);
      showCustomDialog(
        context: context,
        dialog: AlertDialog(
          title: Text('Debug'),
          content: Text('MAC address: ${networkNotifier.mac}'),
          actions: <Widget>[
            FlatButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }

    void generateCode() {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GenerateCodePage(
                  groupDetails: groupDetails,
                )),
      ).whenComplete(
        () => Future.delayed(Duration(milliseconds: 100)).then(
          (_) => _updateAppBar(),
        ),
      );
    }

    final bool showButtons = groupDetails.checkIn == '' ||
        groupDetails.checkCheckOut == 1 && groupDetails.checkOut == '';
    Widget lastChild;
    List<Widget> children = [];
    if (showButtons) {
      if (groupDetails.codeEnabled == 1) {
        children.addAll([
          TypeCodeButton(
            onPressed: typeCode,
          ),
          ScanCodeButton(
            onPressed: scanCode,
          ),
        ]);
      }
      if (groupDetails.wifiEnabled == 1) {
        children.add(
          MarkWithWifiButton(
            onPressed: markWithWifi,
            onLongPress: wifiLongPress,
          ),
        );
        lastChild = MarkWithWifiButton(
          fullWidth: true,
          onPressed: markWithWifi,
          onLongPress: wifiLongPress,
        );
      }
    }
    if (groupDetails.level == 'coordinator') {
      children.add(
        GenerateCodeButton(
          onPressed: generateCode,
        ),
      );
      lastChild = GenerateCodeButton(
        fullWidth: true,
        onPressed: generateCode,
      );
    }
    if (children.length % 2 == 1) {
      children.removeLast();
      children.add(lastChild);
    }
    lastChild = null;

    return Column(
      children: <Widget>[
        if (showButtons && groupDetails.wifiEnabled == 1) WifiWidget(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            runSpacing: 8,
            spacing: 8,
            children: children,
          ),
        ),
        SizedBox(
          height:
              children.length == 0 ? 24 : MediaQuery.of(context).padding.bottom,
        ),
      ],
    );
  }
}

class TypeCodeDialog extends StatefulWidget {
  final GroupDetails groupDetails;
  const TypeCodeDialog({Key key, @required this.groupDetails})
      : super(key: key);

  @override
  _TypeCodeDialogState createState() => _TypeCodeDialogState();
}

class _TypeCodeDialogState extends State<TypeCodeDialog> {
  bool _autovalidate = false;
  String _errorText;
  String code;

  void validate() {
    if (code.isEmpty) {
      setState(() {
        _errorText = 'Code cannot be empty';
      });
    } else if (code.length != 6) {
      setState(() {
        _errorText = 'Code must have 6 digits';
      });
    } else {
      setState(() {
        _errorText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Type Code for ${widget.groupDetails.groupName}'),
      content: TextField(
        autofocus: true,
        decoration: InputDecoration(labelText: 'Code', errorText: _errorText),
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.number,
        inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
        maxLength: 6,
        onChanged: (value) {
          code = value;
          if (_autovalidate) validate();
        },
        onSubmitted: (value) {
          code = value;
          _autovalidate = true;
          validate();
          if (_errorText == null) Navigator.pop(context, code);
        },
      ),
      actions: <Widget>[
        FlatButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
        FlatButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('OK'),
          onPressed: () {
            _autovalidate = true;
            validate();
            if (_errorText == null) Navigator.pop(context, code);
          },
        ),
      ],
    );
  }
}

class TypeCodeButton extends StatelessWidget {
  final bool fullWidth;
  final VoidCallback onPressed;
  const TypeCodeButton({
    Key key,
    this.fullWidth = false,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeNotifier>(context).value;
    return GroupButton(
      backgroundColor: isDark ? Colors.grey[850] : Colors.red[50],
      textColor: isDark ? Colors.red : Colors.red[600],
      splashColor: isDark ? Colors.white12 : Colors.red.withOpacity(.12),
      iconData: Icons.dialpad,
      text: 'Type Code',
      onPressed: onPressed,
      fullWidth: fullWidth,
    );
  }
}

class ScanCodeButton extends StatelessWidget {
  final bool fullWidth;
  final VoidCallback onPressed;
  const ScanCodeButton({
    Key key,
    this.fullWidth = false,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeNotifier>(context).value;
    return GroupButton(
      backgroundColor: isDark ? Colors.grey[850] : Colors.lightBlue[50],
      textColor: isDark ? Colors.lightBlue : Colors.lightBlue[600],
      splashColor: isDark ? Colors.white12 : Colors.lightBlue.withOpacity(.12),
      iconData: Icons.camera_alt,
      text: 'Scan Code',
      onPressed: onPressed,
      fullWidth: fullWidth,
    );
  }
}

class MarkWithWifiButton extends StatelessWidget {
  final bool fullWidth;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  const MarkWithWifiButton({
    Key key,
    this.fullWidth = false,
    @required this.onPressed,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeNotifier>(context).value;
    return GroupButton(
      backgroundColor: isDark ? Colors.grey[850] : Colors.orange[50],
      textColor: isDark ? Colors.orange : Colors.orange[600],
      splashColor: isDark ? Colors.white12 : Colors.orange.withOpacity(.12),
      iconData: Icons.wifi,
      text: 'Mark with WiFi',
      onPressed: onPressed,
      onLongPress: onLongPress,
      fullWidth: fullWidth,
    );
  }
}

class GenerateCodeButton extends StatelessWidget {
  final bool fullWidth;
  final VoidCallback onPressed;
  const GenerateCodeButton({
    Key key,
    this.fullWidth = false,
    @required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkModeNotifier>(context).value;
    return GroupButton(
      backgroundColor: isDark ? Colors.grey[850] : Colors.green[50],
      textColor: isDark ? Colors.green : Colors.green[600],
      splashColor: isDark ? Colors.white12 : Colors.green.withOpacity(.12),
      iconData: Icons.code,
      text: 'Generate Code',
      onPressed: onPressed,
      fullWidth: fullWidth,
    );
  }
}

class GroupButton extends ImplicitlyAnimatedWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color splashColor;
  final String text;
  final IconData iconData;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final bool fullWidth;

  const GroupButton({
    Key key,
    Duration duration = kThemeAnimationDuration,
    Curve curve = Curves.linear,
    @required this.backgroundColor,
    @required this.textColor,
    @required this.splashColor,
    @required this.text,
    @required this.iconData,
    @required this.onPressed,
    this.onLongPress,
    this.fullWidth = false,
  }) : super(
          duration: duration,
          curve: curve,
          key: key,
        );

  _GroupButtonState createState() => _GroupButtonState();
}

class _GroupButtonState extends AnimatedWidgetBaseState<GroupButton> {
  ColorTween _backgroundColorTween;
  ColorTween _textColorTween;
  ColorTween _splashColorTween;

  @override
  void forEachTween(visitor) {
    _backgroundColorTween = visitor(_backgroundColorTween,
        widget.backgroundColor, (dynamic value) => ColorTween(begin: value));
    _textColorTween = visitor(_textColorTween, widget.textColor,
        (dynamic value) => ColorTween(begin: value));
    _splashColorTween = visitor(_splashColorTween, widget.splashColor,
        (dynamic value) => ColorTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    Timer timer;
    var buttonWidth = (MediaQuery.of(context).size.width - 24) / 2;
    if (buttonWidth < 0) {
      buttonWidth = 100; // Reasonable value
    }
    if (widget.fullWidth) {
      buttonWidth = buttonWidth * 2 + 8;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: widget.onLongPress != null
          ? (_) {
              timer = Timer(const Duration(seconds: 1), () {
                widget.onLongPress();
              });
            }
          : null,
      onTapUp: widget.onLongPress != null
          ? (_) {
              if (timer != null) {
                timer.cancel();
                timer = null;
              }
            }
          : null,
      onTapCancel: widget.onLongPress != null
          ? () {
              if (timer != null) {
                timer.cancel();
                timer = null;
              }
            }
          : null,
      onForcePressPeak: widget.onLongPress != null
          ? (_) {
              if (timer != null) {
                timer.cancel();
                timer = null;
              }
              widget.onLongPress();
            }
          : null,
      child: RaisedButton(
        padding: EdgeInsets.zero,
        elevation: 0,
        hoverElevation: isDark ? 6 : 3,
        highlightElevation: isDark ? 12 : 6,
        focusElevation: isDark ? 12 : 6,
        color: _backgroundColorTween.evaluate(animation),
        highlightColor: _splashColorTween.evaluate(animation),
        splashColor: _splashColorTween.evaluate(animation),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          height: buttonWidth * (widget.fullWidth ? .25 : .8),
          width: buttonWidth,
          child: widget.fullWidth
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      widget.iconData,
                      color: _textColorTween.evaluate(animation),
                      size: 56,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(
                      widget.text,
                      style: Theme.of(context).textTheme.body2.copyWith(
                            fontSize: 16,
                            color: _textColorTween.evaluate(animation),
                          ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const SizedBox.shrink(),
                    Icon(
                      widget.iconData,
                      color: _textColorTween.evaluate(animation),
                      size: 56,
                    ),
                    Text(
                      widget.text,
                      style: Theme.of(context).textTheme.body2.copyWith(
                            fontSize: 16,
                            color: _textColorTween.evaluate(animation),
                          ),
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
        ),
        onPressed: widget.onPressed,
      ),
    );
  }
}
