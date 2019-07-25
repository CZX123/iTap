import 'dart:io' show Platform;
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/attendance.dart';
import 'src/group_data.dart';
import 'src/login.dart';
import 'src/settings.dart';
import 'src/theme.dart';
import 'src/user_data.dart';
import 'src/widgets/custom_cross_fade.dart';
import 'src/wifi.dart';
import 'package:http/http.dart' as http; // Remove when done testing
import 'dart:convert'; // Remove when done testing
import 'src/widgets/custom_dialog.dart'; // Remove when done testing

void main() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(Main());
}

class Main extends StatelessWidget {
  const Main({Key key}) : super(key: key);
  static const platform = const MethodChannel('com.irs.itap/androidVersion');

  Future<bool> checkAndroid8() {
    if (Platform.isAndroid) return platform.invokeMethod<bool>('checkAndroid8');
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        FutureProvider.value(
          initialData: false,
          value: checkAndroid8(),
          catchError: (context, error) => false,
        ),
        ChangeNotifierProvider(
          builder: (context) => UserDataNotifier(),
        ),
        ChangeNotifierProvider(
          builder: (context) => DarkModeNotifier(false),
        ),
        ChangeNotifierProvider(
          builder: (context) => GroupDataNotifier(),
        ),
        StreamProvider<NetworkDetails>(
          builder: (context) {
            return Connectivity()
                .onConnectivityChanged
                .asyncMap((result) async {
              if (result == ConnectivityResult.wifi) {
                String name = await Connectivity().getWifiName();
                String mac = await Connectivity().getWifiBSSID();
                return NetworkDetails(result: result, name: name, mac: mac);
              } else
                return NetworkDetails(result: result);
            });
          },
          updateShouldNotify: (oldDetails, newDetails) {
            return oldDetails != newDetails;
          },
        ),
        ChangeNotifierProvider(
          builder: (context) => NetworkNotifier(null),
        ),
        ProxyProvider2<NetworkDetails, NetworkNotifier, NetworkDetails>(
          builder: (context, streamDetails, notifier, newDetails) {
            if (notifier.value != null &&
                (streamDetails == null ||
                    streamDetails.result == ConnectivityResult.wifi &&
                        streamDetails.name == null)) {
              print('Wifi updated from NetworkNotifier: ${notifier.value}');
              // if the notifier offers more useful info than the stream, then return the notifier instead
              return notifier.value;
            }
            print('Wifi updated from StreamProvider: $streamDetails');
            return streamDetails;
          },
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
  static const platform = const MethodChannel('com.irs.itap/androidVersion');
  bool _loaded = false;
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
      drawer: const Drawer(
        child: SettingsDrawer(),
      ),
      body: CustomCrossFade(
        child: child,
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
