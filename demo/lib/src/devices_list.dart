// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/device.pbgrpc.dart' as toit;

/// Widget to display the most important properties of a device.
///
/// See [toit.Device] for properties of Toit devices.
class Device extends StatelessWidget {
  final toit.Device _device;

  Device(this._device) : super(key: ValueKey(Uuid.unparse(_device.id)));

  @override
  Widget build(BuildContext context) {
    var isConnected = _device.status.connected;
    var isWell = !_device.status.health.connectivity.checkins.last.missed;
    return Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(_device.config.name + (_device.isSimulator ? " 💻"  : ""),
            style: TextStyle(fontWeight: FontWeight.bold)),
        Spacer(),
        isWell
            ? Icon(Icons.sentiment_satisfied_alt, color: Colors.green)
            : Icon(Icons.sentiment_dissatisfied, color: Colors.red),
        Text('⬤',
            style: TextStyle(color: isConnected ? Colors.green : Colors.red))
      ]),
      Text(Uuid.unparse(_device.id)),
    ]));
  }
}

/// Widget to show the given devices in a list.
class DevicesList extends StatelessWidget {
  final List<toit.Device> _entries;

  DevicesList(this._entries);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: _entries.map((toitDevice) => Device(toitDevice)).toList(),
    );
  }
}

/// Widget to show information of the devices that are accessible to the user
/// through the Toit API.
class DevicesPage extends StatefulWidget {
  final ToitApi _toitApi;

  DevicesPage(this._toitApi, {Key? key}) : super(key: key);

  @override
  _DevicesState createState() => _DevicesState();
}

class _DevicesState extends State<DevicesPage> {
  late Future<List<toit.Device>> _devices;

  @override
  void initState() {
    super.initState();
    // Asynchronously fetches all devices.
    // There are flags to `listDevices` but, for simplicity, we just get a
    // simple list of all devices.
    _devices = widget._toitApi.deviceServiceStub
        .listDevices(toit.ListDevicesRequest())
        .then((response) => response.devices);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Toit Demo Home Page'),
      ),
      body:
          // While waiting for the response from the server show a spinner.
          FutureBuilder<List<toit.Device>>(
              future: _devices,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return DevicesList(snapshot.data!);
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return CircularProgressIndicator();
              }),
    );
  }
}
