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

/// A demo page to show a pubsub stream with limited lifetime.
///
/// The Flutter application sends a signal to the device, which then
/// continuously produces data, until a stop signal is sent.
///
/// In case the Flutter application dies (or is killed) without sending a
/// stop signal, the device also requires a regular heartbeat signal. If the
/// device doesn't receive any heartbeat for a specific time, it assumes that
/// the Flutter app silently disappeared and stops producing new data.
class PubsubListenHeartbeatPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  PubsubListenHeartbeatPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _PubsubListenHeartbeatState createState() => _PubsubListenHeartbeatState();
}

const pubsubListenDataTopic = "cloud:flutter_demo/listen_data";
const pubsubListenHeartbeatTopic = "cloud:flutter_demo/listen_heartbeat";
const pubsubListenStopTopic = "cloud:flutter_demo/listen_stop";

/// Code that is executed on the device.
///
/// For the purpose of this demo, the Flutter application sends the code
/// dynamically. Normally, this application would be installed beforehand, and
/// the Flutter application would simply send the heartbeat message to start
/// receiving data.
///
/// The app uses three pubsub topics:
/// - the heartbeat topic, on which it listens for a signal that the device
///   should produce data. If the device doesn't receive a heartbeat for
///   30 seconds, it assumes that the receiver died and stops sending data.
/// - the stop topic: lets the application know that it should stop sending
///   data immediately.
/// - the data topic, on which it sends data.
///
/// The app could just run all the time, or it could be triggered by the
/// heartbeat message (in the `app.yaml` file):
/// ```
/// pubsub:
///   subscriptions:
///     - "cloud:flutter_demo/listen_heartbeat"
/// ```
///
/// The Toit program should furthermore be enhanced to take into account the
/// creation time of the pubsub message. The current code assumes that the
/// heartbeat message was received without noticeable delay. If, however, the
/// device was offline, it would receive a stale heartbeat message. In that
/// case it should probably just ignore the message.
///
/// The device does not differentiate between different Flutter applications
/// requesting data. This means that multiple phones could send heartbeats
/// and would listen to the same data. If individual listeners should receive
/// a concrete set of data, see the RPC example.
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
  // Normally we should be able to use `mounted` as indication of
  // whether we are allowed to call `setState`.
  // However, we are hit by https://github.com/flutter/flutter/issues/25536.
  // We are therefore keeping track of it ourselves.
  bool _isDisposing = false;

  Future<void> _startListening() async {
    // Create a fresh subscription.
    // The fresh subscription is destroyed in the [dispose] function below.
    // If the [dispose] is not called (the app is killed, battery died, ...)
    // we end up leaving a stale subscription that the user needs to clean up
    // by themselves. There is, unfortunately, no good way to avoid this.
    // One could include a timestamp in the subscription name and
    // remove stale subscriptions the next time the Flutter app runs, but that's
    // not always working either.
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

  /// Starts sending periodic heartbeat messages.
  ///
  /// The device must have an app installed that reacts to the heartbeat.
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

  /// Sends a heartbeat to the device.
  Future<void> _sendHeartbeat() async {
    var request = PublishRequest(
        publisherName: "Flutter demo",
        // TODO(florian): figure out why we can't send to the specific client.
        // By using '@selectedDevice' we send the message only to this device.
        topic: pubsubListenHeartbeatTopic, // @$selectedDevice",
        data: const [[]]);
    await widget._toitApi.publishStub.publish(request);
  }

  /// Sends a stop message to the device.
  ///
  /// This method can also be used in the [dispose] method below. As such it
  /// allows to not update the state.
  Future<void> _sendStop() async {
    assert(_heartbeatSubscription != null);
    _heartbeatSubscription!.cancel();
    if (!_isDisposing) {
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
        data: const [[]]);
    await widget._toitApi.publishStub.publish(request);
  }

  @override
  void initState() {
    super.initState();
    // Create a fresh unique subscription name.
    var name = "demo-pubsub-listen-heartbeat-${Uuid().v1()}";
    _toitSubscription =
        toit.Subscription(name: name, topic: pubsubListenDataTopic);
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Pubsub Heartbeat Listen'),
        ),
        body: Column(children: [
          RunWidget(
            code: clientCode,
            selectedDeviceId: "pubsub-listen-heartbeat",
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
    _isDisposing = true;
    if (_heartbeatSubscription != null) _sendStop();
    _heartbeatSubscription?.cancel();  // Linter wants a cancel in the dispose.
    _streamSubscription?.cancel();
    _streamSubscription = null;
    var request =
        toit.DeleteSubscriptionRequest(subscription: _toitSubscription);
    widget._toitApi.subscribeStub.deleteSubscription(request);
    super.dispose();
  }
}
