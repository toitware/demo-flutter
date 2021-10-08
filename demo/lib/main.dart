// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'src/devices_list.dart';
import 'src/toit_api.dart';

const API_TOKEN = "";

void main() {
  if (API_TOKEN == "") {
    runApp(MaterialApp(
        home: const Text("Please update the value of the API_TOKEN.")));
    return;
  }
  var toitApi = ToitApi(token: API_TOKEN);
  runApp(MyApp(toitApi));
}

class MyApp extends StatelessWidget {
  final ToitApi _toitApi;

  MyApp(this._toitApi);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toit Demo',
      home: DevicesPage(_toitApi),
    );
  }
}
