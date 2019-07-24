import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:provider/provider.dart';
import 'widgets/custom_cross_fade.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkDetails {
  ConnectivityResult result;
  String name;
  String mac;

  NetworkDetails({
    @required this.result,
    this.name,
    this.mac,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NetworkDetails &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            mac == other.mac;
  }

  @override
  int get hashCode => hashValues(result, name, mac);

  @override
  String toString() {
    var value = 'NetworkDetails(result: $result';
    if (name != null) value += ', name: $name';
    if (mac != null) value += ', mac: $mac';
    value += ')';
    return value;
  }
}

class NetworkNotifier extends ValueNotifier<NetworkDetails> {
  NetworkNotifier(NetworkDetails value) : super(value);
}

class WifiWidget extends StatefulWidget {
  const WifiWidget();

  @override
  _WifiWidgetState createState() => _WifiWidgetState();
}

class _WifiWidgetState extends State<WifiWidget> {
  String _wifiName;
  bool _connectedToWifi;
  String _errorText = '';

  void recheckConnectivity() {
    final notifier = Provider.of<NetworkNotifier>(context);
    Connectivity().checkConnectivity().then((result) async {
      if (result == ConnectivityResult.wifi) {
        final name = await Connectivity().getWifiName();
        final mac = await Connectivity().getWifiBSSID();
        if (name == null) {
          final errorText = 'Location is not turned on';
          if (_errorText != errorText)
            setState(() {
              _errorText = errorText;
            });
        } else {
          notifier.value = NetworkDetails(
            result: result,
            name: name,
            mac: mac,
          );
        }
      } else {
        notifier.value = NetworkDetails(
          result: result,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var networkDetails = Provider.of<NetworkDetails>(context);
    if (networkDetails == null) {
      print('Network Details is null! Checking connectivity again...');
      recheckConnectivity();
    }
    _wifiName = networkDetails?.name ?? _wifiName;
    _connectedToWifi = networkDetails?.result == ConnectivityResult.wifi;
    if (_connectedToWifi && _wifiName == null) {
      if (Provider.of<bool>(context)) {
        print(
            'Error! Cannot get wifi name because location or location permission is not turned on!');
        PermissionHandler()
            .checkPermissionStatus(PermissionGroup.location)
            .then((status) {
          if (status != PermissionStatus.granted) {
            var errorText = 'Location permission denied';
            if (status == PermissionStatus.disabled)
              errorText = 'Location is not turned on';
            if (_errorText != errorText)
              setState(() {
                _errorText = errorText;
              });
            PermissionHandler()
                .requestPermissions([PermissionGroup.location]).then((value) {
              if (value[PermissionGroup.location] != PermissionStatus.granted) {
                var errorText = 'Location permission denied';
                if (status == PermissionStatus.disabled)
                  errorText = 'Location is not turned on';
                if (_errorText != errorText)
                  setState(() {
                    _errorText = errorText;
                  });
              } else {
                recheckConnectivity();
              }
            });
          } else {
            recheckConnectivity();
          }
        });
      } else {
        print('Error! Cannot get wifi name due to unknown reasons.');
      }
    }
    return CustomCrossFade(
      child: networkDetails == null
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
                  if (_connectedToWifi)
                    if (_wifiName != null)
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
                          key: ValueKey(_errorText),
                          child: Text(_errorText),
                        ),
                      )
                  else
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Not connected to WiFi'),
                    ),
                ],
              ),
            ),
    );
  }
}
