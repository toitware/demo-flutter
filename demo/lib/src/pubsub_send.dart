// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart';

import 'device_select.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/program.pbgrpc.dart' as toit;
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs a small program on a device.
class PubsubSendPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  PubsubSendPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _PubsubSendState createState() => _PubsubSendState();
}

const pubsubSendTopic = "cloud:flutter_demo/to_device";

const clientCode = """
import pubsub

TOPIC ::= "$pubsubSendTopic"
main:
  print "Listening for events from phone"
  pubsub.subscribe TOPIC: | msg |
    payload := msg.payload.to_string
    print "Received: '\$payload'"
    print "Exiting"
    return
""";

class _PubsubSendState extends ConsumerState<PubsubSendPage> {
  String? _text = "";

  Future<void> _sendProgram(String selectedDevice) async {
    var sources = toit.ProgramSource_Files(entryFilename: 'main.toit', files: {
      'main.toit': utf8.encode(clientCode),
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

  Future<void> _sendNotification(String selectedDevice) async {
    var request = PublishRequest(
        publisherName: "Flutter demo",
        // TODO(florian): figure out why we can't send to the specific client.
        // By using '@selectedDevice' we send the message only to this device.
        topic: "$pubsubSendTopic", // @$selectedDevice",
        data: [utf8.encode("hello from flutter ${DateTime.now()}")]);
    var response = await widget._toitApi.publishStub.publish(request);
  }

  @override
  Widget build(BuildContext context) {
    var selectedDevice = ref.watch(selectedDeviceProvider("pubsub-send")).state;
    return Scaffold(
        appBar: AppBar(
          title: Text('Toit Demo PubSub Send'),
        ),
        body: Column(children: [
          Card(
              child: Row(children: [
            Spacer(),
            Text(clientCode, style: GoogleFonts.robotoMono()),
            Spacer()
          ])),
          DeviceSelector("pubsub-send", widget._toitApi),
          TextButton(
              onPressed: selectedDevice == null
                  ? null
                  : () {
                      _sendProgram(selectedDevice);
                    },
              child: Text('Run Client')),
          _text == null ? CircularProgressIndicator() : Text(_text!),
          TextButton(
              onPressed: selectedDevice == null
                  ? null
                  : () {
                      _sendNotification(selectedDevice);
                    },
              child: Text('Send notification')),
        ]));
  }
}
