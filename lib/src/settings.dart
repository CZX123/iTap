import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'user_data.dart';
import 'widgets/custom_cross_fade.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({Key key}) : super(key: key);

  @override
  _SettingsDrawerState createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  String _username;
  String _fullName;
  String _org;

  @override
  Widget build(BuildContext context) {
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);
    final userDataNotifier = Provider.of<UserDataNotifier>(context);
    if (userDataNotifier.checkData()) {
      _username = userDataNotifier.username;
      _fullName = userDataNotifier.fullName;
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
                  ? Column(
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
                                  _fullName[0],
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
                                _fullName,
                                style: Theme.of(context).textTheme.body2.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                _username + '@' + _org,
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
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.transparent,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        ListTile(
                          leading: Icon(Icons.account_box),
                          title: Text('Attendance History'),
                          onTap: () {},
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
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {},
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
