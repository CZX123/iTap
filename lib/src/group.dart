import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'group_actions.dart';
import 'group_data.dart';
import 'user_data.dart';
import 'widgets/custom_cross_fade.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({Key key}) : super(key: key);

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with WidgetsBindingObserver {
  String _previousGroup;
  GroupDetails _groupDetails;

  void getGroupDetails() {
    final userDataNotifier = Provider.of<UserDataNotifier>(context);
    final groupDataNotifier = Provider.of<GroupDataNotifier>(context);
    if (userDataNotifier?.userKey == null ||
        groupDataNotifier?.selectedGroup == null) return;
    http.post('https://itap.ml/app/index.php', body: {
      'userkey': userDataNotifier.userKey,
      'action': 'getGroupDetails',
      'org': userDataNotifier.org,
      'username': userDataNotifier.username,
      'group': groupDataNotifier.modifiedSelectedGroup,
    }).then((response) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedJson = jsonDecode(response.body);
        final newGroupDetails = GroupDetails.fromJson(parsedJson);
        if (_groupDetails == newGroupDetails)
          return; // If data is equivalent, do not setState
        setState(() {
          _groupDetails = newGroupDetails;
          print(_groupDetails);
        });
      } else {
        // Die
      }
    }).catchError((e) {
      // Something
    });
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
    if (_previousGroup != groupDataNotifier.selectedGroup) {
      _previousGroup = groupDataNotifier.selectedGroup;
      getGroupDetails();
    }
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
        getGroupDetails();
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
    var windowHeight = MediaQuery.of(context).size.height;
    if (windowHeight == 0) {
      windowHeight =
          640; // Reasonable value, windowHeight will get update immediately after
      // This is to prevent the negative box constraints errror
    }
    final topPadding = MediaQuery.of(context).padding.top;
    final topBarHeight = 80; // hardcoded
    final present = _groupDetails?.checkTakenToday == 0;
    return CustomCrossFade(
      child: _groupDetails == null
          ? ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: windowHeight - topPadding - topBarHeight,
              ),
            )
          : ConstrainedBox(
              key: ObjectKey(_groupDetails),
              constraints: BoxConstraints(
                minHeight: windowHeight - topPadding - topBarHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(),
                  GroupStatus(
                    groupDetails: _groupDetails,
                    present: present,
                  ),
                  if (present)
                    GroupTimings(
                      groupDetails: _groupDetails,
                    ),
                  GroupActions(
                    groupDetails: _groupDetails,
                    getGroupDetails: getGroupDetails,
                  ),
                ],
              ),
            ),
    );
  }
}

class GroupStatus extends StatelessWidget {
  final GroupDetails groupDetails;
  final bool present;
  const GroupStatus(
      {Key key, @required this.groupDetails, @required this.present})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          present ? Icons.check : Icons.clear,
          size: 56,
          color: present ? Colors.green : Colors.red,
        ),
        Text(
          present ? 'Present' : 'Not Marked',
          style: Theme.of(context).textTheme.display2.copyWith(
                color: present ? Colors.green : Colors.red,
              ),
        ),
      ],
    );
  }
}

class GroupTimings extends StatelessWidget {
  final GroupDetails groupDetails;
  const GroupTimings({Key key, @required this.groupDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          children: <Widget>[
            Text(
              groupDetails.checkIn == '' ? '–' : groupDetails.checkIn,
              style: Theme.of(context).textTheme.display1,
            ),
            Text('Checked in'),
            SizedBox(
              height: 28,
              child: IconButton(
                iconSize: 20,
                icon: const Icon(Icons.comment),
                onPressed: () {},
              ),
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        ),
        Column(
          children: <Widget>[
            Text(
              groupDetails.checkOut == '' ? '–' : groupDetails.checkOut,
              style: Theme.of(context).textTheme.display1,
            ),
            Text('Checked out'),
            SizedBox(
              height: 28,
              child: IconButton(
                iconSize: 20,
                icon: const Icon(Icons.comment),
                onPressed: () {},
              ),
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        ),
      ],
    );
  }
}
