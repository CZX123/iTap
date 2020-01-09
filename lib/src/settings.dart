import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
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
  bool _showAccountsPage = false;
  bool _loaded = false;
  String _userKey;
  String _fullName;
  String _username;
  String _org;

  @override
  Widget build(BuildContext context) {
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);
    final userDataNotifier = Provider.of<UserDataNotifier>(context);

    if (!_loaded) {
      if (userDataNotifier.checkData()) {
        _showAccountsPage = true;
        _loaded = true;
        _userKey = userDataNotifier.userKey;
        _fullName = userDataNotifier.fullName;
        _username = userDataNotifier.username;
        _org = userDataNotifier.org;
      } else {
        _loaded = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _showAccountsPage = false;
            });
          }
        });
      }
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
              child: _showAccountsPage
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
                  _userKey != null
                      ? IconButton(
                          icon: CustomCrossFade(
                            child: _showAccountsPage
                                ? Icon(
                                    Icons.info,
                                    key: ValueKey(true),
                                  )
                                : Icon(
                                    Icons.account_circle,
                                    key: ValueKey(false),
                                  ),
                          ),
                          tooltip:
                              _showAccountsPage ? 'About iTap' : 'My Account',
                          onPressed: () {
                            setState(() {
                              _loaded = true;
                              if (_showAccountsPage)
                                _showAccountsPage = false;
                              else
                                _showAccountsPage = true;
                            });
                          },
                        )
                      : SizedBox(
                          height: 0,
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
                    tooltip: 'Change Theme',
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
            MediaQuery.of(context).padding.bottom -
            64,
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
          Text('© 2016 – 2020 iTap'),
          Text('Version 2.1.1'),
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.bottom -
            64,
      ),
      child: Column(
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
                  widget.username.toLowerCase() +
                      '@' +
                      widget.org.toLowerCase(),
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
                'https://itap.ml/app/viewattendance/?org=${widget.org}&token=${widget.userKey}',
              );
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
      ),
    );
  }
}
