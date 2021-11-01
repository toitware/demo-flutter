// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart';
import 'package:toit_api/toit/api/pubsub/subscribe.pbgrpc.dart' as toit;

import 'run_widget.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pretty_gauge/pretty_gauge.dart';

class PubsubListenHeartbeatPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  PubsubListenHeartbeatPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _PubsubListenHeartbeatState createState() => _PubsubListenHeartbeatState();
}

const pubsubListenDataTopic = "cloud:flutter_demo/listen_data";
const pubsubListenHeartbeatTopic = "cloud:flutter_demo/listen_heartbeat";
const pubsubListenStopTopic = "cloud:flutter_demo/listen_stop";

const clientCode = """
import pubsub

TOPIC_HEARTBEAT ::=
    "$pubsubListenHeartbeatTopic"
TOPIC_DATA ::=
    "$pubsubListenDataTopic"
TOPIC_STOP ::=
    "$pubsubListenStopTopic"

should_send := false
sending := false
last /Time? := null
MAX_NO_HEART ::= Duration --s=30

current := 50
send_data:
  // Stream data, for up to 30 seconds
  // without heartbeat. If there is no
  // heartbeat anymore stop streaming, in
  // case the phone didn't send a stop
  // message.
  sending = true
  while should_send and
      (Duration.since last) < MAX_NO_HEART:
    // Simulate an external sensor.
    current += random -5 6
    current = max 0 (min current 100)
    pubsub.publish TOPIC_DATA "\$current"
    sleep --ms=500
  sending = false

listen_heartbeat: 
  pubsub.subscribe TOPIC_HEARTBEAT:
    // Whenever we receive a heartbeat from
    // the phone reset the clock and start
    // (or continue) sending data.
    last = Time.now
    should_send = true
    if not sending:
      task:: send_data

listen_stop:
  pubsub.subscribe TOPIC_STOP:
    should_send = false

main:
  task:: listen_heartbeat
  task:: listen_stop
""";

class _PubsubListenHeartbeatState
    extends ConsumerState<PubsubListenHeartbeatPage> {
  late toit.Subscription _toitSubscription;
  double _currentValue = 0.0;
  StreamSubscription? _streamSubscription;
  StreamSubscription? _heartbeatSubscription;

  Future<void> _startListening() async {
    // Create a fresh subscription.
    var request =
        toit.CreateSubscriptionRequest(subscription: _toitSubscription);
    await widget._toitApi.subscribeStub.createSubscription(request);

    var envelopes =
        widget._toitApi.stream(_toitSubscription, autoAcknowledge: true);
    _streamSubscription = envelopes.listen((envelope) {
      setState(() {
        var value = double.parse(utf8.decode(envelope.message.data));
        _currentValue = value;
      });
    });
  }

  void _startHeartbeat() {
    assert(_heartbeatSubscription == null);
    setState(() {
      _heartbeatSubscription =
          Stream.periodic(Duration(seconds: 20)).listen((_) {
        _sendHeartbeat();
      });
    });
    _sendHeartbeat();
  }

  Future<void> _sendHeartbeat() async {
    var request = PublishRequest(
        publisherName: "Flutter demo",
        // TODO(florian): figure out why we can't send to the specific client.
        // By using '@selectedDevice' we send the message only to this device.
        topic: pubsubListenHeartbeatTopic, // @$selectedDevice",
        data: [[]]);
    await widget._toitApi.publishStub.publish(request);
  }

  Future<void> _sendStop({bool disposing = false}) async {
    assert(_heartbeatSubscription != null);
    _heartbeatSubscription!.cancel();
    if (!disposing) {
      setState(() {
        _heartbeatSubscription = null;
      });
    } else {
      _heartbeatSubscription = null;
    }
    var request = PublishRequest(
        publisherName: "Flutter demo",
        // TODO(florian): figure out why we can't send to the specific client.
        // By using '@selectedDevice' we send the message only to this device.
        topic: pubsubListenStopTopic, // @$selectedDevice",
        data: [[]]);
    await widget._toitApi.publishStub.publish(request);
  }

  @override
  void initState() {
    super.initState();
    // Create a fresh subscription.
    var name = "demo-pubsub-listen-heartbeat-${Uuid().v1()}";
    _toitSubscription =
        toit.Subscription(name: name, topic: pubsubListenDataTopic);
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Toit Demo PubSub Send'),
        ),
        body: Column(children: [
          RunWidget(
            code: clientCode,
            selectedDeviceId: "pubsub-listen",
          ),
          Row(children: [
            TextButton(
                onPressed:
                    _heartbeatSubscription == null ? _startHeartbeat : null,
                child: Text('Start')),
            TextButton(
                onPressed: _heartbeatSubscription == null ? null : _sendStop,
                child: Text('Stop')),
          ]),
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
        ]));
  }

  @override
  void dispose() {
    super.dispose();
    if (_heartbeatSubscription != null) _sendStop(disposing: true);
    // Linter wants a cancel in the dispose.
    _heartbeatSubscription?.cancel();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    var request =
        toit.DeleteSubscriptionRequest(subscription: _toitSubscription);
    widget._toitApi.subscribeStub.deleteSubscription(request);
  }
}
