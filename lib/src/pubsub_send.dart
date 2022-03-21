// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart';

import 'device_select.dart';
import 'run_widget.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/program.pbgrpc.dart' as toit;
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sends a pubsub notification to a program running on the device.
///
/// This can be used to trigger actions.
class PubsubSendPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  PubsubSendPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _PubsubSendState createState() => _PubsubSendState();
}

const pubsubSendTopic = "cloud:flutter_demo/to_device";

/// Code that is executed on the device.
///
/// The application simply listens on the pubsub topic and extracts the
/// payload as a string (printing it).
///
/// For the purpose of this demo, the Flutter application sends the code
/// dynamically. Normally, this application would be installed beforehand, and
/// the Flutter application would simply send the notification.
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

  Future<void> _sendNotification(String selectedDevice) async {
    var request = PublishRequest(
        publisherName: "Flutter demo",
        // TODO(florian): figure out why we can't send to the specific client.
        // By using '@selectedDevice' we send the message only to this device.
        topic: "$pubsubSendTopic", // @$selectedDevice",
        data: [utf8.encode("hello from flutter ${DateTime.now()}")]);
    await widget._toitApi.publishStub.publish(request);
  }

  @override
  Widget build(BuildContext context) {
    var selectedDevice = ref.watch(selectedDeviceProvider("pubsub-send"));
    return Scaffold(
        appBar: AppBar(
          title: Text('Pubsub Send'),
        ),
        body: Column(children: [
          RunWidget(
            code: clientCode,
            selectedDeviceId: "pubsub-send",
          ),
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
