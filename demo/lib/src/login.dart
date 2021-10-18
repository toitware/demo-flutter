// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:demo/src/toit_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _usernameKey = 'username';
const _passwordKey = 'password';

class LoginPage extends ConsumerStatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginPage> {
  bool _isAuthenticating = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _prefs = SharedPreferences.getInstance();

  Future<void> _login() async {
    setState(() {
      _isAuthenticating = true;
    });
    var toitApi = ToitApi();
    try {
      print("trying to log in");
      var username = _usernameController.value.text;
      var password = _passwordController.value.text;
      await toitApi.login(username: username, password: password);
      // Successful login.
      var prefs = await _prefs;
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
      ref.read(toitApiProvider).state = toitApi;
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
      });
      String msg;
      if (e is GrpcError && e.message != null) {
        msg = e.message!;
      } else {
        msg = e.toString();
      }
      var snackBar =
          SnackBar(content: Text("Error while authenticating: $msg"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadSavedConfig() async {
    var prefs = await _prefs;
    var username = prefs.getString(_usernameKey);
    var password = prefs.getString(_passwordKey);
    if (username != null) {
      _usernameController.text = username;
    }
    if (password != null) {
      _passwordController.text = password;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Toit Demo Login'),
        ),
        body: AutofillGroup(
            child: Column(children: [
          TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your Toit.io username',
              ),
              controller: _usernameController,
              autofillHints: [AutofillHints.email],
              keyboardType: TextInputType.emailAddress),
          TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your Toit.io password',
              ),
              controller: _passwordController,
              autofillHints: [AutofillHints.password],
              keyboardType: TextInputType.visiblePassword,
              obscureText: true),
          _isAuthenticating
              ? CircularProgressIndicator()
              : TextButton(onPressed: _login, child: Text('Login'))
        ])));
  }
}
