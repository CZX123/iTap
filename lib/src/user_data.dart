import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_data.dart';

class UserDataNotifier extends ChangeNotifier {
  String _userKey; // randomKey to prevent external access
  String get userKey => _userKey;

  String _username; // 15xxxxx
  String get username => _username;

  String _fullName; // Lu Weiqi
  String get fullName => _fullName;

  String _org;
  String get org => _org;

  bool checkData() {
    return _userKey != null &&
        _username != null &&
        _fullName != null &&
        _org != null;
  }

  void updateData(
    String userKey,
    String username,
    String fullName,
    String org,
  ) {
    _userKey = userKey;
    _username = username;
    _fullName = fullName;
    _org = org;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('userKey', userKey);
      prefs.setString('username', username);
      prefs.setString('fullName', fullName);
      prefs.setString('org', org);
    });
  }

  void logout(BuildContext context) {
    updateData(null, null, null, null);
    Provider.of<GroupDataNotifier>(context).reset();
  }
}
