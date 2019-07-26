import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'user_data.dart';
import 'widgets/app_logo.dart';
import 'widgets/custom_cross_fade.dart';
import 'widgets/custom_dialog.dart';
import 'widgets/no_internet.dart';

enum FormType { login, reset }

class LoginPage extends StatefulWidget {
  const LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formTypeNotifier = ValueNotifier(FormType.login);

  @override
  Widget build(BuildContext context) {
    // Random widget here for testing first
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          0,
          MediaQuery.of(context).padding.top + 20,
          0,
          0,
        ),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const TopBar(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: ValueListenableBuilder<FormType>(
                valueListenable: _formTypeNotifier,
                builder: (context, formType, child) {
                  return CustomCrossFade(
                    child: formType == FormType.login
                        ? LoginForm(
                            formTypeNotifier: _formTypeNotifier,
                          )
                        : ResetPasswordForm(
                            formTypeNotifier: _formTypeNotifier,
                          ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.only(bottom: 24),
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
        ],
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final ValueNotifier<FormType> formTypeNotifier;
  const LoginForm({Key key, @required this.formTypeNotifier}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _validate = false; // Do not start validating input first
  final _formKey = GlobalKey<FormState>();
  final _organisationNode = FocusNode();
  final _usernameNode = FocusNode();
  final _passwordNode = FocusNode();
  String _org;
  String _username;
  String _password;

  void _submitForm([bool error = false]) {
    FormState state = _formKey.currentState;
    if (state.validate()) {
      state.save();
      try {
        http.post('https://itap.ml/app/index.php', body: {
          'token': 'rQQYP51jI87DnteO',
          'action': 'login',
          'org': _org,
          'username': _username,
          'password': _password,
        }).then((response) {
          if (response.statusCode == 200) {
            if (error) {
              Provider.of<InternetAvailibility>(context)
                  .removeSnackbar(context);
            }
            final Map<String, dynamic> userData = jsonDecode(response.body);
            print('Login Details: $userData');
            final int success = userData['success'];
            if (success == 0) {
              showCustomDialog(
                context: context,
                dialog: AlertDialog(
                  title: Text('Error'),
                  content: Text(userData['error_message']),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('OK'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
              );
            } else if (success == 1) {
              Provider.of<UserDataNotifier>(context).updateData(
                userData['key'],
                _username,
                userData['user'],
                _org,
              );
            } // if success == 2
          } else {
            print('Error ${response.statusCode} while logging in');
          }
        });
      } catch (e) {
        print('Error while logging in: $e');
        if (!error) {
          Provider.of<InternetAvailibility>(context)
              .showNoInternetSnackBar(context);
        }
        // Login again if there is an error
        Future.delayed(const Duration(seconds: 1), () {
          _submitForm(true);
        });
      }
    } else
      setState(() {
        _validate = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      autovalidate: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Sign In',
            style: Theme.of(context).textTheme.headline,
          ),
          Text(
            'to your iTap account',
            style: Theme.of(context).textTheme.subhead,
          ),
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            focusNode: _organisationNode,
            decoration: InputDecoration(labelText: 'Organisation'),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: (value) {
              if (value.isEmpty) return 'Organisation cannot be empty';
              return null;
            },
            onSaved: (value) {
              _org = value;
            },
            onFieldSubmitted: (value) {
              _organisationNode.unfocus();
              FocusScope.of(context).requestFocus(_usernameNode);
            },
          ),
          TextFormField(
            focusNode: _usernameNode,
            decoration: InputDecoration(labelText: 'Username'),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: (value) {
              if (value.isEmpty) return 'Username cannot be empty';
              return null;
            },
            onSaved: (value) {
              _username = value;
            },
            onFieldSubmitted: (value) {
              _usernameNode.unfocus();
              FocusScope.of(context).requestFocus(_passwordNode);
            },
          ),
          TextFormField(
            focusNode: _passwordNode,
            decoration: InputDecoration(labelText: 'Password'),
            textInputAction: TextInputAction.done,
            autocorrect: false,
            obscureText: true,
            validator: (value) {
              if (value.isEmpty) return 'Password cannot be empty';
              return null;
            },
            onSaved: (value) {
              _password = value;
            },
            onFieldSubmitted: (value) {
              _passwordNode.unfocus();
              _submitForm();
            },
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                elevation: 0,
                hoverElevation: isDark ? 6 : 3,
                highlightElevation: isDark ? 12 : 6,
                focusElevation: isDark ? 12 : 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Login'),
                onPressed: _submitForm,
              ),
              const SizedBox(
                width: 12,
              ),
              FlatButton(
                textColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Forgot Password?'),
                onPressed: () {
                  widget.formTypeNotifier.value = FormType.reset;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  final ValueNotifier<FormType> formTypeNotifier;
  const ResetPasswordForm({Key key, @required this.formTypeNotifier})
      : super(key: key);

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  bool _validate = false; // Do not start validating input first
  final _formKey = GlobalKey<FormState>();
  final _organisationNode = FocusNode();
  final _usernameNode = FocusNode();
  String _org;
  String _username;

  void _submitForm([bool error = false]) {
    print('yay?');
    FormState state = _formKey.currentState;
    if (state.validate()) {
      state.save();
      try {
        http.post('https://itap.ml/app/index.php', body: {
          'token': 'rQQYP51jI87DnteO',
          'action': 'forgotPassword',
          'org': _org,
          'username': _username,
        }).then((response) {
          if (response.statusCode == 200) {
            if (error) {
              Provider.of<InternetAvailibility>(context)
                  .removeSnackbar(context);
            }
            final Map<String, dynamic> userData = jsonDecode(response.body);
            print('Reset Password Details: $userData');
            final int success = userData['success'];
            if (success == 0) {
              showCustomDialog(
                context: context,
                dialog: AlertDialog(
                  title: Text('Error'),
                  content: Text(userData['error_message']),
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
            } else if (success == 1) {
              showCustomDialog(
                context: context,
                dialog: AlertDialog(
                  title: Text('Success'),
                  content: Text(userData['error_message']),
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
            print('Error ${response.statusCode} while resetting password');
          }
        });
      } catch (e) {
        print('Error while resetting password: $e');
        if (!error) {
          Provider.of<InternetAvailibility>(context)
              .showNoInternetSnackBar(context);
        }
        // Reset password again if there is an error
        Future.delayed(const Duration(seconds: 1), () {
          _submitForm(true);
        });
      }
    } else
      setState(() {
        _validate = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      autovalidate: _validate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Reset Password',
            style: Theme.of(context).textTheme.headline,
          ),
          Text(
            'for your iTap account',
            style: Theme.of(context).textTheme.subhead,
          ),
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            focusNode: _organisationNode,
            decoration: InputDecoration(labelText: 'Organisation'),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: (value) {
              if (value.isEmpty) return 'Organisation cannot be empty';
              return null;
            },
            onSaved: (value) {
              _org = value;
            },
            onFieldSubmitted: (value) {
              _organisationNode.unfocus();
              FocusScope.of(context).requestFocus(_usernameNode);
            },
          ),
          TextFormField(
            focusNode: _usernameNode,
            decoration: InputDecoration(labelText: 'Username'),
            textInputAction: TextInputAction.next,
            autocorrect: false,
            validator: (value) {
              if (value.isEmpty) return 'Username cannot be empty';
              return null;
            },
            onSaved: (value) {
              _username = value;
            },
            onFieldSubmitted: (value) {
              _usernameNode.unfocus();
              _submitForm();
            },
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: <Widget>[
              RaisedButton(
                elevation: 0,
                hoverElevation: isDark ? 6 : 3,
                highlightElevation: isDark ? 12 : 6,
                focusElevation: isDark ? 12 : 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Reset'),
                onPressed: _submitForm,
              ),
              const SizedBox(
                width: 12,
              ),
              FlatButton(
                textColor: Theme.of(context).colorScheme.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Back To Login'),
                onPressed: () {
                  widget.formTypeNotifier.value = FormType.login;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
