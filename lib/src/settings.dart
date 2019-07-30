import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
//import 'package:webview_flutter/webview_flutter.dart';
import 'theme.dart';
import 'user_data.dart';
import 'widgets/custom_cross_fade.dart';

void launchURL(BuildContext context, String url) async {
  try {
    await launch(
      url,
      option: new CustomTabsOption(
        toolbarColor: Theme.of(context).primaryColor,
        enableUrlBarHiding: true,
        showPageTitle: true,
        extraCustomTabs: <String>['com.microsoft.emmx', 'org.mozilla.firefox'],
      ),
    );
  } catch (e) {
    debugPrint(e);
  }
}

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({Key key}) : super(key: key);

  @override
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  String _userKey;
  String _fullName;
  String _username;
  String _org;

  @override
  Widget build(BuildContext context) {
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);
    final userDataNotifier = Provider.of<UserDataNotifier>(context);

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

    if (userDataNotifier.checkData()) {
      _userKey = userDataNotifier.userKey;
      _fullName = userDataNotifier.fullName;
      _username = userDataNotifier.username;
      _org = userDataNotifier.org;
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CustomCrossFade(
              child: userDataNotifier.checkData()
                  ? AccountPage(
                      userKey: _userKey,
                      fullName: _fullName,
                      username: _username,
                      org: _org,
                    )
                  : const EmptyPage(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      Navigator.pop(context);
                      launchURL(context, 'https://itap.ml/app/about/?v=2.0');
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (context) => WebViewPage(
                      //             title: 'About iTap',
                      //             url: 'https://itap.ml/app/about/?v=2.0',
                      //           )),
                      // ).whenComplete(
                      //   () => Future.delayed(Duration(milliseconds: 100)).then(
                      //     (_) => _updateAppBar(),
                      //   ),
                      // );
                    },
                  ),
                  IconButton(
                    icon: CustomCrossFade(
                      child: darkModeNotifier.value
                          ? Icon(
                              Icons.brightness_2,
                              key: ValueKey(true),
                            )
                          : Icon(
                              Icons.brightness_6,
                              key: ValueKey(false),
                            ),
                    ),
                    onPressed: () {
                      darkModeNotifier.value = !darkModeNotifier.value;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyPage extends StatelessWidget {
  const EmptyPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            MediaQuery.of(context).padding.bottom -
            24,
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            height: 16,
          ),
          Image.asset(
            'icon/iTap-medium.png',
            width: 96,
            height: 96,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'iTap',
            style: Theme.of(context).textTheme.display1,
          ),
          const Text('Take attendance with a TAP!'),
          const SizedBox(
            height: 16,
          ),
          Text(
            'Developers',
            style: Theme.of(context).textTheme.body2,
          ),
          Text('Cai Zhouxuan'),
          Text('Lu Weiqi'),
          const SizedBox(
            height: 16,
          ),
          Text('© 2016 – 2019 iTap'),
          Text('Version 2.1'),
        ],
      ),
    );
  }
}

class AccountPage extends StatefulWidget {
  final String userKey;
  final String fullName;
  final String username;
  final String org;
  const AccountPage({
    Key key,
    @required this.userKey,
    @required this.fullName,
    @required this.username,
    @required this.org,
  }) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    final userDataNotifier =
        Provider.of<UserDataNotifier>(context, listen: false);
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 24,
            16,
            16,
          ),
          color: Theme.of(context).appBarTheme.color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white70,
                child: Text(
                  widget.fullName[0],
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
                width: double.infinity,
              ),
              Text(
                widget.fullName,
                style: Theme.of(context).textTheme.body2.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                widget.username + '@' + widget.org,
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 1,
          width: double.infinity,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white12
              : Colors.transparent,
        ),
        const SizedBox(
          height: 8,
        ),
        ListTile(
          leading: Icon(Icons.account_box),
          title: Text('Attendance History'),
          onTap: () {
            Navigator.pop(context);
            launchURL(
              context,
              'https://itap.ml/app/viewattendance/?token=${widget.userKey}',
            );
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) {
            //       return WebViewPage(
            //         title: 'Attendance History',
            //         url:
            //             'https://itap.ml/app/viewattendance/?token=${widget.userKey}',
            //       );
            //     },
            //   ),
            // );
          },
        ),
        ListTile(
          leading: Icon(Icons.exit_to_app),
          title: Text('Logout'),
          onTap: () {
            Navigator.pop(context);
            userDataNotifier.logout(context);
          },
        ),
      ],
    );
  }
}

// class WebViewPage extends StatelessWidget {
//   final String title;
//   final String url;
//   const WebViewPage({
//     Key key,
//     @required this.title,
//     @required this.url,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: WebView(
//               javascriptMode: JavascriptMode.unrestricted,
//               initialUrl: url,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
