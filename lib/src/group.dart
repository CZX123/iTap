import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'group_actions.dart';
import 'group_data.dart';
import 'user_data.dart';
import 'widgets/custom_cross_fade.dart';
import 'widgets/custom_dialog.dart';
import 'widgets/no_internet.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({Key key}) : super(key: key);

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with WidgetsBindingObserver {
  String _previousGroup;
  GroupDetails _groupDetails;
  bool loading = false;

  void getGroupDetails([
    bool lifecycleChange = false,
  ]) async {
    final userDataNotifier = Provider.of<UserDataNotifier>(context);
    final groupDataNotifier = Provider.of<GroupDataNotifier>(context);
    if (userDataNotifier?.userKey == null ||
        groupDataNotifier?.selectedGroup == null) return;
    Timer timer;
    if (!lifecycleChange) {
      setState(() {
        _groupDetails = null;
      });
      timer = Timer(const Duration(milliseconds: 800), () {
        setState(() {
          loading = true;
        });
      });
    }
    try {
      final response = await http.post('https://itap.ml/app/index.php', body: {
        'userkey': userDataNotifier.userKey,
        'action': 'getGroupDetails',
        'org': userDataNotifier.org,
        'username': userDataNotifier.username,
        'group': convertGroupName(groupDataNotifier.selectedGroup),
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        Provider.of<InternetAvailabilityNotifier>(context, listen: false)
            .value = true;
        timer?.cancel();
        final Map<String, dynamic> parsedJson = jsonDecode(response.body);
        final newGroupDetails = GroupDetails.fromJson(parsedJson);
        if (_groupDetails == newGroupDetails)
          return; // If data is equivalent, do not setState
        setState(() {
          if (loading) loading = false;
          _groupDetails = newGroupDetails;
          print(_groupDetails);
        });
      } else {
        print('Error ${response.statusCode} while getting group details');
      }
    } catch (e) {
      print('Error while getting group details: $e');
      Provider.of<InternetAvailabilityNotifier>(context, listen: false).value =
          false;
      // Get group details again if there is an error
      Future.delayed(const Duration(seconds: 1), () {
        getGroupDetails(true);
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
        getGroupDetails(true);
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
          640; // Reasonable value, windowHeight will get updated immediately after
      // This is to prevent the negative box constraints errror
    }
    final topPadding = MediaQuery.of(context).padding.top;
    final topBarHeight = 84; // hardcoded
    final present = _groupDetails?.checkTakenToday == 0;
    return CustomCrossFade(
      child: _groupDetails == null
          ? Container(
              constraints: BoxConstraints(
                minHeight: windowHeight - topPadding - topBarHeight,
              ),
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: loading ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: CircularProgressIndicator(),
              ),
            )
          : ConstrainedBox(
              key: ObjectKey(_groupDetails),
              constraints: BoxConstraints(
                minHeight: windowHeight - topPadding - topBarHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      getGroupDetails: getGroupDetails,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      child: Column(
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
      ),
    );
  }
}

class GroupTimings extends StatelessWidget {
  final GroupDetails groupDetails;
  final VoidCallback getGroupDetails;
  const GroupTimings({
    Key key,
    @required this.groupDetails,
    @required this.getGroupDetails,
  }) : super(key: key);

  void showRemarksDialog(BuildContext context, bool isCheckOut) async {
    final remarks = await showCustomDialog<String>(
      context: context,
      dialog: AddRemarksDialog(
        groupDetails: groupDetails,
        isCheckOut: isCheckOut,
      ),
    );
    if (remarks == null) return;
    addRemarks(context, isCheckOut, remarks);
  }

  void addRemarks(
    BuildContext context,
    bool isCheckOut,
    String remarks,
  ) async {
    if (!isCheckOut && groupDetails.remarks == remarks ||
        isCheckOut && groupDetails.remarksCheckout == remarks) return;
    try {
      final userDataNotifier = Provider.of<UserDataNotifier>(context);
      final response = await http.post('https://itap.ml/app/index.php', body: {
        'userkey': userDataNotifier.userKey,
        'action': 'addRemarks',
        'org': userDataNotifier.org,
        'group': convertGroupName(groupDetails.groupName),
        'username': userDataNotifier.username,
        (isCheckOut ? 'remarks_checkout' : 'remarks'): remarks,
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        Provider.of<InternetAvailabilityNotifier>(context, listen: false)
            .value = true;
        final Map<String, dynamic> parsedJson = jsonDecode(response.body);
        if (parsedJson['success'] == 1) {
          print('Check ${isCheckOut ? 'out' : 'in'} remarks added: $remarks');
          getGroupDetails();
        } else {
          showCustomDialog(
            context: context,
            dialog: AlertDialog(
              title: Text('Error'),
              content: Text(parsedJson['error_message']),
              actions: <Widget>[
                FlatButton(
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
        print(
            'Error ${response.statusCode} while adding check ${isCheckOut ? 'out' : 'in'} remarks');
      }
    } catch (e) {
      print(
          'Error while adding check ${isCheckOut ? 'out' : 'in'} remarks: $e');
      Provider.of<InternetAvailabilityNotifier>(context, listen: false).value =
          false;
      Future.delayed(const Duration(seconds: 1), () {
        addRemarks(context, isCheckOut, remarks);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text(
                groupDetails.checkIn,
                style: Theme.of(context).textTheme.display1,
              ),
              Text('Checked in'),
              SizedBox(
                height: 28,
                child: IconButton(
                  iconSize: 20,
                  icon: groupDetails.remarks == ''
                      ? const Icon(Icons.add_comment)
                      : const Icon(Icons.comment),
                  tooltip: groupDetails.remarks == ''
                      ? 'Add check in remarks'
                      : 'Edit check in remarks',
                  onPressed: () {
                    showRemarksDialog(context, false);
                  },
                ),
              ),
            ],
          ),
          if (groupDetails.checkCheckOut == 1)
            Column(
              children: <Widget>[
                Text(
                  groupDetails.checkOut == '' ? '–' : groupDetails.checkOut,
                  style: Theme.of(context).textTheme.display1,
                ),
                Text('Checked out'),
                SizedBox(
                  height: 28,
                  child: groupDetails.checkOut == ''
                      ? null
                      : IconButton(
                          iconSize: 20,
                          icon: groupDetails.remarksCheckout == ''
                              ? const Icon(Icons.add_comment)
                              : const Icon(Icons.comment),
                          tooltip: groupDetails.remarks == ''
                              ? 'Add check out remarks'
                              : 'Edit check out remarks',
                          onPressed: () {
                            showRemarksDialog(context, true);
                          },
                        ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class AddRemarksDialog extends StatefulWidget {
  final GroupDetails groupDetails;
  final bool isCheckOut;
  const AddRemarksDialog({
    Key key,
    @required this.groupDetails,
    @required this.isCheckOut,
  }) : super(key: key);

  @override
  _AddRemarksDialogState createState() => _AddRemarksDialogState();
}

class _AddRemarksDialogState extends State<AddRemarksDialog> {
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.isCheckOut
          ? widget.groupDetails.remarksCheckout
          : widget.groupDetails.remarks,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          '${widget.isCheckOut ? 'Check Out Remarks' : 'Check In Remarks'} for ${widget.groupDetails.groupName}'),
      content: TextField(
        controller: _textController,
        maxLines: null,
        autofocus: true,
        decoration: InputDecoration(
          labelText:
              widget.isCheckOut ? 'Check out remarks' : 'Check in remarks',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          Navigator.pop(context, _textController.text);
        },
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('CANCEL'),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
        FlatButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.pop(context, _textController.text);
          },
        ),
      ],
    );
  }
}
