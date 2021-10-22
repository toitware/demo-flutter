// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'device_log.dart';
import 'devices_list.dart';
import 'device_run.dart';
import 'pubsub_listen_heartbeat.dart';
import 'pubsub_listen_in.dart';
import 'toit_api.dart';
import 'pubsub_send.dart';

/// Widget to show all available demos.
class HomePage extends StatelessWidget {
  final ToitApi _toitApi;

  HomePage(this._toitApi, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nested function to push a page onto the navigator.
    void push(Widget pageFun(ToitApi toitApi)) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => pageFun(_toitApi)));
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Toit Demos'),
        ),
        body: ListView(
          children: <Widget>[
            Card(
                child: ListTile(
                    title: Text('List Devices'),
                    subtitle:
                        Text('Demonstrates the use of the Toit Server API'),
                    onTap: () => push((toitApi) => DevicesPage(toitApi)))),
            Card(
                child: ListTile(
                    title: Text('Log'),
                    subtitle: Text('Shows the logs of a device'),
                    onTap: () => push((toitApi) => LogPage(toitApi)))),
            Card(
                child: ListTile(
                    title: Text('Run'),
                    subtitle: Text('Runs a program on a device'),
                    onTap: () => push((_) => RunPage()))),
            Card(
                child: ListTile(
                    title: Text('Pubsub Send'),
                    subtitle: Text('Sends a pubsub event to a device'),
                    onTap: () => push((toitApi) => PubsubSendPage(toitApi)))),
            Card(
                child: ListTile(
                    title: Text('Pubsub Listen'),
                    subtitle: Text('Listens to messages on a topic'),
                    onTap: () =>
                        push((toitApi) => PubsubListenInPage(toitApi)))),
            Card(
                child: ListTile(
                    title: Text('Pubsub Listen Heartbeat'),
                    subtitle: Text('Requests the device to stream data'),
                    onTap: () =>
                        push((toitApi) => PubsubListenHeartbeatPage(toitApi)))),
          ],
        ));
  }
}
