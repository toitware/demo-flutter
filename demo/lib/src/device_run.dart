// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_select.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/program.pbgrpc.dart' as toit;
import 'package:uuid/uuid.dart';

/// Runs a small program on a device.
class RunPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  RunPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _RunPageState createState() => _RunPageState();
}

class _RunPageState extends ConsumerState<RunPage> {
  String? _text = "";

  Future<void> _sendProgram(String selectedDevice) async {
    var sources = toit.ProgramSource_Files(entryFilename: 'main.toit', files: {
      'main.toit': utf8.encode('main: print "hello world"'),
    });
    setState(() {
      _text = null;
    });
    var request = toit.DeviceRunRequest(
      deviceId: Uuid.parse(selectedDevice),
      source: toit.ProgramSource(files: sources),
    );
    var response = widget._toitApi.programServiceStub.deviceRun(request);
    await for (var responseLine in response) {
      var line = utf8
          .decode(responseLine.hasErr() ? responseLine.err : responseLine.out);
      setState(() {
        _text = (_text ?? "") + line;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var selectedDevice = ref.watch(selectedDeviceProvider("run")).state;
    return Scaffold(
        appBar: AppBar(
          title: Text('Toit Demo Home Page'),
        ),
        body: Column(children: [
          DeviceSelector("run", widget._toitApi),
          TextButton(
              onPressed: selectedDevice == null
                  ? null
                  : () {
                      _sendProgram(selectedDevice);
                    },
              child: Text('Run')),
          _text == null ? CircularProgressIndicator() : Text(_text!),
        ]));
  }
}
