// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:convert';

import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/program.pbgrpc.dart' as toit;
import 'package:uuid/uuid.dart';

final deviceId = "b01fb57f-ef2a-4632-801c-c5d0f5ba5736";

/// Runs a small program on a device.
class RunPage extends StatefulWidget {
  final ToitApi _toitApi;

  RunPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _RunPageState createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  String _text = "";

  Future<void> _sendProgram() async {
    var sources = toit.ProgramSource_Files(entryFilename: 'main.toit', files: {
      'main.toit': utf8.encode('main: print "hello world"'),
    });
    var request = toit.DeviceRunRequest(
      deviceId: Uuid.parse(deviceId),
      source: toit.ProgramSource(files: sources),
    );
    var response = widget._toitApi.programServiceStub.deviceRun(request);
    await for (var responseLine in response) {
      var line = utf8
          .decode(responseLine.hasErr() ? responseLine.err : responseLine.out);
      setState(() {
        _text += line;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Toit Demo Home Page'),
        ),
        body: Column(children: [
          TextButton(onPressed: _sendProgram, child: Text('Run')),
          Text(_text),
        ]));
  }
}
