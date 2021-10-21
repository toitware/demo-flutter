// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart' as toit;
import 'package:toit_api/toit/api/pubsub/subscribe.pbgrpc.dart' as toit;
import 'package:toit_api/toit/api/program.pbgrpc.dart' as toit;

import 'device_select.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_gauge/pretty_gauge.dart';

class PubsubListenInPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  PubsubListenInPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _PubsubListenInState createState() => _PubsubListenInState();
}

const pubsubListenInTopic = "cloud:flutter_demo/listen_in";

const clientCode = """
import pubsub

TOPIC ::= "$pubsubListenInTopic"
main:
  current := 50
  100.repeat:
    current += random -10 11
    current = max 0 (min current 100)
    pubsub.publish TOPIC "\$current"
    sleep --ms=1000
""";

class _PubsubListenInState extends ConsumerState<PubsubListenInPage> {
  String? _text = "";
  late toit.Subscription _toitSubscription;
  double _currentValue = 0.0;
  List<StreamSubscription> _streamSubscriptions = [];

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
    _streamSubscriptions.add(response.listen((responseLine) {
      var line = utf8
          .decode(responseLine.hasErr() ? responseLine.err : responseLine.out);
      setState(() {
        _text = (_text ?? "") + line;
      });
    }));
  }

  Future<void> _startListening() async {
    // Create a fresh subscription.
    var request =
        toit.CreateSubscriptionRequest(subscription: _toitSubscription);
    await widget._toitApi.subscribeStub.createSubscription(request);

    var envelopes =
        widget._toitApi.stream(_toitSubscription, autoAcknowledge: true);
    _streamSubscriptions.add(envelopes.listen((envelope) {
      setState(() {
        var value = double.parse(utf8.decode(envelope.message.data));
        _currentValue = value;
      });
    }));
  }

  @override
  void initState() {
    super.initState();
    // Create a fresh subscription.
    var name = "demo-pubsub-listen-in-${Uuid().v1()}";
    _toitSubscription =
        toit.Subscription(name: name, topic: pubsubListenInTopic);
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    var selectedDevice =
        ref.watch(selectedDeviceProvider("pubsub-listen")).state;
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
          DeviceSelector("pubsub-listen", widget._toitApi),
          TextButton(
              onPressed: selectedDevice == null
                  ? null
                  : () {
                      _sendProgram(selectedDevice);
                    },
              child: Text('Run Client')),
          Expanded(
              child: PrettyGauge(
            currentValue: _currentValue,
            segments: [
              GaugeSegment('Low', 20, Colors.red),
              GaugeSegment('Medium', 40, Colors.orange),
              GaugeSegment('High', 40, Colors.green),
            ],
            gaugeSize: 100,
          )),
          _text == null ? CircularProgressIndicator() : Text(_text!),
        ]));
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscriptions.forEach((sub) {
      sub.cancel();
    });
    _streamSubscriptions.clear();
    var request =
        toit.DeleteSubscriptionRequest(subscription: _toitSubscription);
    widget._toitApi.subscribeStub.deleteSubscription(request);
  }
}
