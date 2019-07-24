import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'group_data.dart';
import 'user_data.dart';
import 'widgets/custom_cross_fade.dart';

class GenerateCodePage extends StatefulWidget {
  GenerateCodePage({Key key}) : super(key: key);

  _GenerateCodePageState createState() => _GenerateCodePageState();
}

class _GenerateCodePageState extends State<GenerateCodePage>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  final _codeNotifier = ValueNotifier<String>(null);
  String _nextCode;
  int _interval;

  void getCode() async {
    try {
      final userDataNotifier = Provider.of<UserDataNotifier>(context);
      final groupDataNotifier = Provider.of<GroupDataNotifier>(context);
      final response = await http.post('https://itap.ml/app/index.php', body: {
        'userkey': userDataNotifier.userKey,
        'action': 'getCode',
        'org': userDataNotifier.org,
        'group': groupDataNotifier.modifiedSelectedGroup,
        'username': userDataNotifier.username,
      });
      if (response.statusCode == 200) {
        Map<String, dynamic> parsedJson = jsonDecode(response.body);
        final details = GenerateCodeDetails.fromJson(parsedJson);
        print(details);
        _interval = details.interval;
        _codeNotifier.value = details.code;
        _nextCode = details.nextCode;
        final _animationTimeLeft = (1 - _animationController.value) * _interval;
        if (!_animationController.isAnimating ||
            _animationTimeLeft - details.timeLeft > 1 ||
            _animationTimeLeft - details.timeLeft < -1) {
          _animationController.value = 1 - details.timeLeft / _interval;
          _animationController.animateTo(
            1,
            duration: Duration(seconds: details.timeLeft),
          );
        }
      } else {
        print('No Internet!');
      }
    } catch (e) {
      print(e);
    }
  }

  void animationListener(AnimationStatus status) {
    if (_animationController.value == 1) {
      _codeNotifier.value = _nextCode;
      _animationController.value = 0;
      _animationController.animateTo(
        1,
        duration: Duration(seconds: _interval),
      );
      getCode();
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this)
      ..addStatusListener(animationListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getCode();
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(animationListener);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Code for ${Provider.of<GroupDataNotifier>(context).selectedGroup}'),
      ),
      body: Center(
        child: ValueListenableBuilder<String>(
          valueListenable: _codeNotifier,
          builder: (context, value, child) {
            return CustomCrossFade(
              child: value == null
                  ? const SizedBox.shrink()
                  : Column(
                      key: ValueKey(value),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QrImage(
                          size: 240,
                          data: value,
                          version: 1,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          padding: EdgeInsets.zero,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Text(
                          value,
                          style: Theme.of(context).textTheme.display3,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        SizedBox(
                          width: 240,
                          height: 6,
                          child: ClipPath(
                            clipper: ShapeBorderClipper(
                                shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            )),
                            child: ValueListenableBuilder<double>(
                              valueListenable: _animationController,
                              builder: (context, progress, child) {
                                return LinearProgressIndicator(
                                  backgroundColor:
                                      Theme.of(context).dividerColor,
                                  value: value != _codeNotifier.value
                                      ? 1
                                      : progress,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class GenerateCodeDetails {
  final String code;
  final String nextCode;
  final int timeLeft;
  final int interval;

  GenerateCodeDetails({
    this.code,
    this.nextCode,
    this.timeLeft,
    this.interval,
  });

  factory GenerateCodeDetails.fromJson(Map<String, dynamic> parsedJson) {
    return GenerateCodeDetails(
      code: parsedJson['code'],
      nextCode: parsedJson['next_code'],
      timeLeft: parsedJson['time_left'],
      interval: parsedJson['interval'],
    );
  }

  @override
  String toString() {
    return 'GenerateCodeDetails(code: $code, nextCode: $nextCode, timeLeft: $timeLeft, interval: $interval)';
  }
}
