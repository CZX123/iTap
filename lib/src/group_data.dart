import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String convertGroupName(String value) {
  return value.replaceAll(' ', '_').toLowerCase();
}

class GroupDataNotifier extends ChangeNotifier {
  List<String> _groupList;
  List<String> get groupList => _groupList;
  set groupList(List<String> groupList) {
    if (listEquals(groupList, _groupList))
      return; // If data is equivalent, do not refresh
    _groupList = groupList;
    notifyListeners();
  }

  String _selectedGroup;
  String get selectedGroup => _selectedGroup;
  set selectedGroup(String selectedGroup) {
    _selectedGroup = selectedGroup;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('selectedGroup', selectedGroup);
    });
    notifyListeners();
  }

  void reset() {
    _selectedGroup = null;
    _groupList = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('selectedGroup');
    });
    notifyListeners();
  }
}

class GroupDetails {
  final String groupName;
  final int checkTakenToday;
  final int checkSession;
  final int wifiEnabled;
  final int codeEnabled;
  final int checkCheckOut;
  final int checkOutDialog;
  final String checkIn;
  final String checkOut;
  final String level;
  final String remarks;
  final String remarksCheckout;
  final List<GroupWifiDetails> wifiList;

  const GroupDetails({
    this.groupName,
    this.checkTakenToday,
    this.checkSession,
    this.wifiEnabled,
    this.codeEnabled,
    this.checkCheckOut,
    this.checkOutDialog,
    this.checkIn,
    this.checkOut,
    this.level,
    this.remarks,
    this.remarksCheckout,
    this.wifiList,
  });

  factory GroupDetails.fromJson(Map<String, dynamic> parsedJson) {
    return GroupDetails(
      groupName: parsedJson['group_name'],
      checkTakenToday: parsedJson['checkTakenToday'],
      checkSession: parsedJson['checkSession'],
      wifiEnabled: parsedJson['wifiEnabled'],
      codeEnabled: parsedJson['codeEnabled'],
      checkCheckOut: parsedJson['checkCheckOut'],
      checkOutDialog: parsedJson['checkOutDialog'],
      checkIn: parsedJson['checkin'],
      checkOut: parsedJson['checkout'],
      level: parsedJson['level'],
      remarks: parsedJson['remarks'],
      remarksCheckout: parsedJson['remarks_checkout'],
      wifiList: List.from(parsedJson['wifi']).map((parsedJson) {
        return GroupWifiDetails.fromJson(parsedJson);
      }).toList(),
    );
  }

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        other is GroupDetails &&
            groupName == other.groupName &&
            checkTakenToday == other.checkTakenToday &&
            checkSession == other.checkSession &&
            wifiEnabled == other.wifiEnabled &&
            codeEnabled == other.codeEnabled &&
            checkCheckOut == other.checkCheckOut &&
            checkOutDialog == other.checkOutDialog &&
            checkIn == other.checkIn &&
            checkOut == other.checkOut &&
            level == other.level &&
            remarks == other.remarks &&
            remarksCheckout == other.remarksCheckout &&
            listEquals(wifiList, other.wifiList);
  }

  @override
  int get hashCode {
    return hashValues(
      groupName,
      checkTakenToday,
      checkSession,
      wifiEnabled,
      codeEnabled,
      checkCheckOut,
      checkOutDialog,
      checkIn,
      checkOut,
      level,
      remarks,
      remarksCheckout,
      hashList(wifiList),
    );
  }

  @override
  String toString() {
    return 'GroupDetails(groupName: $groupName, checkTakenToday: $checkTakenToday, checkSession: $checkSession, wifiEnabled: $wifiEnabled, codeEnabled: $codeEnabled, checkCheckOut: $checkCheckOut, checkOutDialog: $checkOutDialog, checkIn: $checkIn, checkOut: $checkOut, level: $level, remarks: $remarks, remarksCheckout: $remarksCheckout, wifiList: $wifiList)';
  }
}

class GroupWifiDetails {
  final int routerId;
  final String ssid;
  final String mac;
  final int eventId;
  final int allowed;
  final int macDigits;

  const GroupWifiDetails({
    this.routerId,
    this.ssid,
    this.mac,
    this.eventId,
    this.allowed,
    this.macDigits,
  });

  factory GroupWifiDetails.fromJson(Map<String, dynamic> parsedJson) {
    return GroupWifiDetails(
      routerId: parsedJson['router_id'],
      ssid: parsedJson['ssid'],
      mac: parsedJson['mac'],
      eventId: parsedJson['event_id'],
      allowed: parsedJson['allowed'],
      macDigits: parsedJson['macDigits'],
    );
  }

  operator ==(Object other) {
    return identical(this, other) ||
        other is GroupWifiDetails &&
            routerId == other.routerId &&
            ssid == other.ssid &&
            mac == other.mac &&
            eventId == other.eventId &&
            allowed == other.allowed &&
            macDigits == other.macDigits;
  }

  @override
  int get hashCode {
    return hashValues(
      routerId,
      ssid,
      mac,
      eventId,
      allowed,
      macDigits,
    );
  }

  @override
  String toString() {
    return 'GroupWifiDetails(routerId: $routerId, ssid: $ssid, mac: $mac, eventId: $eventId, allowed: $allowed, macDigits: $macDigits)';
  }
}
