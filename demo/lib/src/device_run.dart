// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'run_widget.dart';
import 'package:flutter/material.dart';

String helloWorld = """
main:
  print "hello world"
""";

/// Runs a small program on a device.
class RunPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Toit Run Demo'),
        ),
        body: RunWidget(
          code: helloWorld,
          selectedDeviceId: 'run',
        ));
  }
}
