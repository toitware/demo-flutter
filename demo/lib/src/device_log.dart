// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/google/protobuf/timestamp.pb.dart';
import 'package:toit_api/toit/api/device.pb.dart';
import 'package:uuid/uuid.dart';

import 'device_select.dart';
import 'package:flutter/material.dart';

import 'toit_api.dart';

/// Shows the log of a device.
class LogPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  LogPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LogPageState();
}

class _LogPageState extends ConsumerState<LogPage> {
  String? _logs = "";

  Future<void> _showLogs(ToitApi toitApi, String device) async {
    setState(() {
      _logs = null;
    });
    var since = DateTime.now().add(-Duration(hours: 3));
    var request = ReadDeviceLogsRequest(
      deviceId: Uuid.parse(device),
      ts: Timestamp(seconds: Int64(since.millisecondsSinceEpoch ~/ 1000)),
    );
    try {
      print("requesting");
      var response = await toitApi.deviceServiceStub.readDeviceLogs(request);
      print("Got response");
      for (var log in response.logs) {
        setState(() {
          var created = DateTime.fromMillisecondsSinceEpoch(
              log.created.seconds.toInt() * 1000);
          created = created
              .add(Duration(microseconds: log.created.nanos.toInt() ~/ 1000));
          _logs = (_logs ?? "") + "$created - ${log.msg}\n";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var selectedDevice = ref.watch(selectedDeviceProvider("log")).state;
    return Scaffold(
      appBar: AppBar(
        title: Text('Toit Log Demo'),
      ),
      body: Column(children: [
        DeviceSelector("log", widget._toitApi),
        TextButton(
            onPressed: selectedDevice == null
                ? null
                : () {
                    _showLogs(widget._toitApi, selectedDevice);
                  },
            child: Text('Get logs of device')),
        Expanded(
          child: SingleChildScrollView(
              child:
                  _logs == null ? CircularProgressIndicator() : Text(_logs!)),
        ),
      ]),
    );
  }
}
