import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:provider/provider.dart';
import 'widgets/custom_cross_fade.dart';
import 'package:permission_handler/permission_handler.dart';

// Class to check if location permission is requred.
class RequireLocation {
  final bool value;
  const RequireLocation(this.value);
}

class NetworkNotifier extends ChangeNotifier {
  ConnectivityResult _result;
  ConnectivityResult get result => _result;

  String _name;
  String get name => _name;

  String _mac;
  String get mac => _mac;

  String _errorText;
  String get errorText => _errorText;
  set errorText(String errorText) {
    if (errorText != _errorText) {
      _errorText = errorText;
      notifyListeners();
    }
  }

  bool isNull() {
    return _result == null && _name == null && _mac == null;
  }

  void updateNetwork(ConnectivityResult result, [String name, String mac]) {
    if (_result != result || _name != name || _mac != mac) {
      _result = result;
      _name = name;
      _mac = mac;
      if (result != ConnectivityResult.wifi) {
        _errorText = 'Not connected to WiFi';
      } else if (name != null && mac != null) {
        _errorText = 'Not connected to the correct WiFi';
      }
      notifyListeners();
    }
  }

  @override
  String toString() {
    var value = 'NetworkNotifier(result: $_result';
    if (_name != null) value += ', name: $_name';
    if (_mac != null) value += ', mac: $_mac';
    value += ')';
    return value;
  }
}

class WifiWidget extends StatefulWidget {
  const WifiWidget();

  @override
  _WifiWidgetState createState() => _WifiWidgetState();
}

class _WifiWidgetState extends State<WifiWidget> {
  bool permissionBeingRequested = false;
  String _wifiName;
  bool _connectedToWifi;

  void recheckConnectivity() {
    final networkNotifier = Provider.of<NetworkNotifier>(context);
    Connectivity().checkConnectivity().then((result) async {
      if (result == ConnectivityResult.wifi) {
        String name;
        String mac;
        try {
          name = await Connectivity().getWifiName();
        } catch (e) {
          print('Failed to get wifi name: $e');
        }
        try {
          mac = await Connectivity().getWifiBSSID();
        } catch (e) {
          print('Failed to get mac address: $e');
        }
        if (mac == '00:00:00:00:00:00') {
          name = null;
          mac = null;
        }
        if (name == null) {
          networkNotifier.errorText = 'Error in obtaining WiFi';
        } else {
          networkNotifier.updateNetwork(result, name, mac);
        }
      } else {
        networkNotifier.updateNetwork(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final networkNotifier = Provider.of<NetworkNotifier>(context);
    if (networkNotifier.isNull()) {
      print('Network Details is null! Checking connectivity again...');
      recheckConnectivity();
    }
    _wifiName = networkNotifier?.name ?? _wifiName;
    _connectedToWifi = networkNotifier?.result == ConnectivityResult.wifi;
    if (_connectedToWifi && _wifiName == null) {
      if (Provider.of<RequireLocation>(context).value) {
        print(
            'Error! Cannot get wifi name because location or location permission is not turned on!');
        PermissionHandler()
            .checkPermissionStatus(PermissionGroup.location)
            .then((status) {
          if (status != PermissionStatus.granted) {
            if (status == PermissionStatus.disabled)
              networkNotifier.errorText = 'Location is not turned on';
            else
              networkNotifier.errorText = 'Location permission denied';
            if (!permissionBeingRequested) {
              permissionBeingRequested = true;
              PermissionHandler()
                  .requestPermissions([PermissionGroup.location]).then((value) {
                permissionBeingRequested = false;
                if (value[PermissionGroup.location] !=
                    PermissionStatus.granted) {
                  if (status == PermissionStatus.disabled)
                    networkNotifier.errorText = 'Location is not turned on';
                  else
                    networkNotifier.errorText = 'Location permission denied';
                } else {
                  recheckConnectivity();
                }
              });
            }
          } else {
            recheckConnectivity();
          }
        });
      } else {
        print('Error! Cannot get wifi name due to unknown reasons.');
      }
    }
    return CustomCrossFade(
      child: networkNotifier.isNull()
          ? const SizedBox(
              height: 48,
            )
          : SizedBox(
              key: ValueKey('$_connectedToWifi ${_wifiName != null}'),
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Icon(
                    _connectedToWifi && _wifiName != null
                        ? Icons.signal_wifi_4_bar_lock
                        : Icons.signal_wifi_off,
                    size: 40,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  if (_connectedToWifi && _wifiName != null)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Connected to:'),
                        CustomCrossFade(
                          child: Text(
                            _wifiName ?? '',
                            key: ValueKey(_wifiName),
                            style: Theme.of(context).textTheme.body2.copyWith(
                                  height: .85,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                          ),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CustomCrossFade(
                        key: ValueKey(networkNotifier.errorText ??
                            'Error in obtaining WiFi'),
                        child: Text(networkNotifier.errorText ??
                            'Error in obtaining WiFi'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
