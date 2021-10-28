// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/toit/api/pubsub/subscribe.pbgrpc.dart' as toit;

import 'run_widget.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pretty_gauge/pretty_gauge.dart';

/// A demo page to show a pubsub stream that listens in on published data.
///
/// The Flutter application creates a fresh subscription and starts listening
/// to data that is sent from the device to the cloud. The device is unaware
/// of how many subscribers it has and just publishes data through the cloud.
class PubsubListenInPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  PubsubListenInPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _PubsubListenInState createState() => _PubsubListenInState();
}

const pubsubListenInTopic = "cloud:flutter_demo/listen_in";

/// A simple Toit application that publishes data through the Toit cloud.
///
/// Critically, it is unaware of any subscribers. It just publishes data.
/// If there is no subscriber, then the data is just lost.
///
/// For the purpose of this demo, the Flutter application sends the code
/// dynamically. Normally, this application would be installed beforehand.
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
  late toit.Subscription _toitSubscription;
  double _currentValue = 0.0;
  StreamSubscription? _streamSubscription;

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

  @override
  void initState() {
    super.initState();
    // Create a fresh subscription.
    //
    // This means that the application only gets data that is received after
    // the subscription was created.
    //
    // The fresh subscription is destroyed in the [dispose] function below.
    // If the [dispose] is not called (the app is killed, battery died, ...)
    // we end up leaving a stale subscription that the user needs to clean up
    // by themselves. There is, unfortunately, no good way to avoid this.
    // One could include a timestamp in the subscription name and
    // remove stale subscriptions the next time the Flutter app runs, but that's
    // not always working either.
    var name = "demo-pubsub-listen-in-${Uuid().v1()}";
    _toitSubscription =
        toit.Subscription(name: name, topic: pubsubListenInTopic);
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Pubsub Listen In'),
        ),
        body: Column(children: [
          RunWidget(
            code: clientCode,
            selectedDeviceId: "pubsub-listen",
          ),
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
    _streamSubscription?.cancel();
    _streamSubscription = null;
    var request =
        toit.DeleteSubscriptionRequest(subscription: _toitSubscription);
    widget._toitApi.subscribeStub.deleteSubscription(request);
  }
}
