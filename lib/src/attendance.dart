import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'group.dart';
import 'group_data.dart';
import 'user_data.dart';
import 'widgets/app_logo.dart';
import 'widgets/custom_cross_fade.dart';
import 'widgets/no_internet.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key key}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with WidgetsBindingObserver {
  void getGroups() async {
    final userDataNotifier = Provider.of<UserDataNotifier>(context);
    if (userDataNotifier?.userKey == null) return;
    try {
      final response = await http.post('https://itap.ml/app/index.php', body: {
        'userkey': userDataNotifier.userKey,
        'action': 'getGroups',
        'org': userDataNotifier.org,
        'username': userDataNotifier.username,
        'method': 'flutter',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        Provider.of<InternetAvailabilityNotifier>(context, listen: false)
            .value = true;
        final groupDataNotifier = Provider.of<GroupDataNotifier>(context);
        final groupList = List<String>.from(jsonDecode(response.body));
        groupDataNotifier.groupList = groupList;
        var selectedGroup = groupDataNotifier.selectedGroup;
        if (selectedGroup == null || !groupList.contains(selectedGroup)) {
          print('Groups: $groupList');
          groupDataNotifier.selectedGroup = groupList[0];
        }
      } else {
        print('Error ${response.statusCode} while getting groups');
      }
    } catch (e) {
      print('Error while getting groups: $e');
      Provider.of<InternetAvailabilityNotifier>(context, listen: false).value =
          false;
      // Get groups again if there is an error
      Future.delayed(const Duration(seconds: 1), () {
        getGroups();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final groupDataNotifier = Provider.of<GroupDataNotifier>(context);
    if (groupDataNotifier.groupList == null) getGroups();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  AppLifecycleState _lastLifecyleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_lastLifecyleState == AppLifecycleState.paused) {
        getGroups();
      }
    }
    if (_lastLifecyleState == AppLifecycleState.paused &&
        state == AppLifecycleState.inactive) {
      _lastLifecyleState = AppLifecycleState.paused;
    } else {
      _lastLifecyleState = state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).padding.top + 20,
          ),
          TopBar(),
          const SizedBox(
            height: 16,
          ),
          GroupPage(),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(
            width: 4,
          ),
          const AppLogo(),
          const SizedBox(
            width: 56,
          ),
          GroupsDropdown(),
          const SizedBox(
            width: 16,
          ),
        ],
      ),
    );
  }
}

class GroupsDropdown extends StatelessWidget {
  const GroupsDropdown({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupDataNotifier = Provider.of<GroupDataNotifier>(context);
    return Expanded(
      child: CustomCrossFade(
        child: groupDataNotifier.groupList == null
            ? const SizedBox.shrink()
            : Container(
                height: 44,
                constraints: BoxConstraints(
                  maxWidth: 240,
                ),
                child: DropdownButtonHideUnderline(
                  child: Material(
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      highlightColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.blue.withOpacity(.1),
                      splashColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white10
                              : Colors.blue.withOpacity(.1),
                      onTap: () {},
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: groupDataNotifier.selectedGroup,
                        style: Theme.of(context).textTheme.subtitle,
                        iconEnabledColor:
                            Theme.of(context).textTheme.subtitle.color,
                        items: groupDataNotifier.groupList.map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          groupDataNotifier.selectedGroup = newValue;
                        },
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
