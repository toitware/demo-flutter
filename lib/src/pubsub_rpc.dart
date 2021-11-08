// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart' as toit;
import 'package:toit_api/toit/api/pubsub/subscribe.pbgrpc.dart' as toit;

import 'device_select.dart';
import 'run_widget.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// A demo page to show a pubsub-based RPC channel between the Flutter app and
/// the device.
///
/// The Flutter application uses individual pubsub commands, and receives
/// responses as messages on a fresh topic that was created for this RPC
/// channel.
class PubsubRpcPage extends ConsumerStatefulWidget {
  final ToitApi _toitApi;

  PubsubRpcPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _PubsubRpcState createState() => _PubsubRpcState();
}

const pubsubRpcTopic = "cloud:flutter_demo/rpc";

/// The Toit code that runs on the device.
///
/// For the purpose of this demo, the Flutter application sends the code
/// dynamically. Normally, this application would be installed beforehand, and
/// the Flutter application would simply establish a new RPC channel.
///
/// In this simple example the device does not keep track of channels. It
/// responds to requests by sending to a topic that was provided as part of
/// the request. As such it is stateless with respect to the RPC protocol.
///
/// Individual requests on the same channel are identified by an ID that is
/// sent with each request.
const clientCode = """
import pubsub
import encoding.json

TOPIC ::= "$pubsubRpcTopic"

send_data response_topic/string id/int:
  data := List 10: (random 170 370)/10
  encoded := json.encode {
    "id": id,
    "data": data,
  }
  pubsub.publish response_topic encoded

main:
  print "listening on \$TOPIC"
  pubsub.subscribe TOPIC: | msg |
    payload := json.decode msg.payload
    id := payload["id"]
    response_topic := payload["topic"]
    send_data response_topic id
""";

class ValuesChart extends StatelessWidget {
  final List<double>? _values;

  ValuesChart(this._values, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors = [
      const Color(0xff23b6e6),
      const Color(0xff02d39a),
    ];
    var spots = <FlSpot>[];
    for (int i = 0; i < _values!.length; i++) {
      spots.add(FlSpot(i.toDouble(), _values![i]));
    }
    var data = LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: 3,
      colors: gradientColors,
    );
    return LineChart(LineChartData(
        minX: -1, maxX: 10, minY: 0, maxY: 40, lineBarsData: [data]));
  }
}

class _PubsubRpcState extends ConsumerState<PubsubRpcPage> {
  List<double>? _values;
  late toit.Subscription _toitSubscription;
  StreamSubscription? _streamSubscription;
  var _rpcCounter = 0;
  /// A map from request-id to response handler.
  ///
  /// When the device sends a response back on the established channel,
  /// the callback with the corresponding id is executed with the data that
  /// was sent.
  Map<int, void Function(dynamic)> _callbacks = {};
  int _waitingForResponses = 0;

  Future<void> _startListening() async {
    // Create a fresh subscription.
    // The topic of this subscription is unique. All messages on this
    // subscription will be responses from the device.
    //
    // The subscription is destroyed in the [dispose] function below.
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
      var response = json.decode(utf8.decode(envelope.message.data));
      var id = response["id"];
      var data = response["data"];
      var callback = _callbacks[id]!;
      _callbacks.remove(id);
      callback(data);
    });
  }

  Future<void> _deleteToitSubscription() {
    var deleteRequest =
        toit.DeleteSubscriptionRequest(subscription: _toitSubscription);
    return widget._toitApi.subscribeStub.deleteSubscription(deleteRequest);
  }

  /// Requests data from the device.
  Future<void> _requestData(String selectedDevice) async {
    setState(() {
      _waitingForResponses++;
    });
    // Each request to the device has its own ID which is used to invoke the
    // correct response closure.
    var rpcId = _rpcCounter++;
    var payload = json.encode({
      "id": rpcId,
      "topic": _toitSubscription.topic,
    });
    var request = toit.PublishRequest(
      publisherName: "Flutter demo",
      // TODO(florian): figure out why we can't send to the specific client.
      // By using '@selectedDevice' we send the message only to this device.
      topic: "$pubsubRpcTopic", // @$selectedDevice",
      data: [utf8.encode(payload)],
    );
    // Record the callback that should be invoked when the device has responded.
    _callbacks[rpcId] = (data) {
      if (!mounted) return;
      setState(() {
        _waitingForResponses--;
        // No need to acknowledge the message since we are deleting the
        // subscription immediately afterwards.
        List dataPoints = data;
        _values = dataPoints.map<double>((x) => x.toDouble()).toList();
      });
    };
    // Send the request to the device.
    await widget._toitApi.publishStub.publish(request);
  }

  @override
  void initState() {
    super.initState();
    // Create a fresh unique subscription name.
    var name = "demo-pubsub-rpc";
    var topic = "cloud:demo-pubsub-rpc-${Uuid().v1()}";
    _toitSubscription = toit.Subscription(name: name, topic: topic);
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    var selectedDevice = ref.watch(selectedDeviceProvider("pubsub-rpc")).state;
    return Scaffold(
        appBar: AppBar(
          title: Text('Pubsub RPC Demo'),
        ),
        body: Column(children: [
          RunWidget(
            code: clientCode,
            selectedDeviceId: "pubsub-rpc",
          ),
          Row(children: [
            TextButton(
                onPressed: selectedDevice == null
                    ? null
                    : () {
                        _requestData(selectedDevice);
                      },
                child: Text('Request data')),
            if (_waitingForResponses > 0) CircularProgressIndicator(),
          ]),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: _values == null ? null : ValuesChart(_values),
          ),
        ]));
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _deleteToitSubscription();
  }
}
