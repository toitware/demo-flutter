// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'src/home.dart';
import 'src/login.dart';
import 'src/toit_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An API token created on https://console.toit.io/project/apikeys or
/// with
/// ```
/// toit project api-keys add <name>  # Prints an ID.
/// toit project api-keys print-secret <id>
/// ```
const API_TOKEN = "";

Future<void> main() async {
  // The 'MyApp' below opens the login screen if the 'toitApi' provider
  // returns 'null'.
  // If we have an API token, then we can override the value of the
  // provider with one that uses the token.
  // In that case, it is safe to remove the login page from the project.
  // Note that the tests use a similar approach to avoid the login screen,
  // and to provide a fake RPC service.
  var overrides = [
    if (API_TOKEN != "")
      toitApiProvider
          .overrideWithValue(StateController(ToitApi(token: API_TOKEN)))
  ];
  runApp(ProviderScope(overrides: overrides, child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We are using Riverpod for state management.
    // Other state management techniques would work as well. Fundamentally,
    // we just keep track of whether we have an authenticated connection to
    // the Toit server.
    var toitApi = ref.watch(toitApiProvider).state;

    Widget page;
    if (toitApi == null) {
      page = LoginPage();
    } else {
      page = HomePage(toitApi);
    }
    return MaterialApp(
      title: 'Toit Demo',
      home: page,
    );
  }
}
