import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/attendance.dart';
import 'src/group_data.dart';
import 'src/login.dart';
import 'src/notification.dart';
import 'src/settings.dart';
import 'src/theme.dart';
import 'src/user_data.dart';
import 'src/widgets/custom_cross_fade.dart';
import 'src/widgets/custom_dialog.dart';
import 'src/widgets/no_internet.dart';
import 'src/wifi.dart';

void main() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(Main());
}

class Main extends StatelessWidget {
  const Main({Key key}) : super(key: key);
  static const platform = const MethodChannel('com.irs.itap/androidVersion');

  Future<CheckAndroid8> checkAndroid8() async {
    if (Platform.isAndroid)
      return Future.value(
        CheckAndroid8(
          await platform.invokeMethod<bool>('checkAndroid8'),
        ),
      );
    return Future.value(CheckAndroid8(false));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        FutureProvider<CheckAndroid8>.value(
          initialData: CheckAndroid8(false),
          value: checkAndroid8(),
          catchError: (context, error) => CheckAndroid8(false),
        ),
        ChangeNotifierProvider(
          builder: (context) => InternetAvailabilityNotifier(true),
        ),
        ChangeNotifierProvider(
          builder: (context) => NetworkNotifier(),
        ),
        ChangeNotifierProvider(
          builder: (context) => DarkModeNotifier(false),
        ),
        ChangeNotifierProvider(
          builder: (context) => UserDataNotifier(),
        ),
        ChangeNotifierProvider(
          builder: (context) => GroupDataNotifier(),
        ),
      ],
      child: Consumer<DarkModeNotifier>(
        builder: (context, darkModeNotifier, child) {
          return MaterialApp(
            theme: darkModeNotifier.value ? darkThemeData : lightThemeData,
            home: Home(),
          );
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _loaded = false;

  void getNotification() async {
    try {
      final response = await http.post('https://itap.ml/app/index.php', body: {
        'action': 'getNotification',
        'v': Platform.isAndroid ? 'android2.1' : 'ios2.1'
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedJson = jsonDecode(response.body);
        final notification = NotificationDetails.fromJson(parsedJson);
        print(notification);
        if (notification.id != 0) {
          showCustomDialog(
            context: context,
            barrierDismissible: notification.id != 2,
            dialog: AlertDialog(
              title: Text(notification.title),
              content: Text(notification.message),
              actions: <Widget>[
                if (notification.noButton != '')
                  FlatButton(
                    child: Text(notification.noButton.toUpperCase()),
                    onPressed: () {
                      if (notification.id != 2) Navigator.pop(context);
                      launchURL(context, notification.noLink);
                    },
                  ),
                FlatButton(
                  child: Text(notification.yesButton.toUpperCase()),
                  onPressed: () {
                    if (notification.id != 2) Navigator.pop(context);
                    launchURL(context, notification.yesLink);
                  },
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      Provider.of<InternetAvailabilityNotifier>(context).value = false;
      Future.delayed(const Duration(seconds: 1), getNotification);
    }
  }

  void _initNetwork() async {
    ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Error while initialising network: $e');
    }
    if (!mounted) return;
    _updateNetwork(result);
  }

  void _updateNetwork(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi) {
      String name;
      String mac;
      try {
        name = await _connectivity.getWifiName();
      } catch (e) {
        print('Failed to get wifi name: $e');
      }
      try {
        mac = await _connectivity.getWifiBSSID();
      } catch (e) {
        print('Failed to get mac address: $e');
      }
      Provider.of<NetworkNotifier>(context, listen: false)
          .updateNetwork(result, name, mac);
    } else
      Provider.of<NetworkNotifier>(context, listen: false)
          .updateNetwork(result);
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final userKey = prefs.getString('userKey');
      final username = prefs.getString('username');
      final fullName = prefs.getString('fullName');
      final org = prefs.getString('org');
      final isDark = prefs.getBool('isDark') ?? false;
      final selectedGroup = prefs.getString('selectedGroup');
      Provider.of<UserDataNotifier>(context)
          .updateData(userKey, username, fullName, org);
      Provider.of<GroupDataNotifier>(context).selectedGroup = selectedGroup;
      Provider.of<DarkModeNotifier>(context).value = isDark;
      setState(() {
        _loaded = true;
      });
    });
    _initNetwork();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateNetwork);
    if (!_loaded) getNotification();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDataNotifier = Provider.of<UserDataNotifier>(context);

    Widget child;
    if (!_loaded)
      child = const SizedBox.shrink();
    else if (userDataNotifier.checkData())
      child = const AttendancePage();
    else
      child = const LoginPage();

    return Scaffold(
      drawer: Drawer(
        child: SettingsDrawer(),
      ),
      body: Stack(
        children: <Widget>[
          CustomCrossFade(
            child: child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Align(
              alignment: Alignment.center,
              child: NoInternetWidget(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.swap_vert),
        onPressed: () {
          if (userDataNotifier.checkData())
            userDataNotifier.logout(context);
          else {
            http.post('https://itap.ml/app/index.php', body: {
              'token': 'rQQYP51jI87DnteO',
              'action': 'login',
              'org': 'hci',
              'username': 'kent',
              'password': 'kent',
            }).then((response) {
              if (response.statusCode == 200) {
                final Map<String, dynamic> userData = jsonDecode(response.body);
                print('Login Details: $userData');
                final int success = userData['success'];
                if (success == 0) {
                  showCustomDialog(
                    context: context,
                    dialog: AlertDialog(
                      title: Text('Error'),
                      content: Text(userData['error_message']),
                      actions: <Widget>[
                        FlatButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),
                  );
                } else if (success == 1) {
                  Provider.of<UserDataNotifier>(context).updateData(
                    userData['key'],
                    'kent',
                    userData['user'],
                    'hci',
                  );
                }
              }
            });
          }
        },
      ),
    );
  }
}
