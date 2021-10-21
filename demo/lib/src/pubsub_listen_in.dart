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
    var name = "demo-pubsub-listen-in-${Uuid().v1()}";
    _toitSubscription =
        toit.Subscription(name: name, topic: pubsubListenInTopic);
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
