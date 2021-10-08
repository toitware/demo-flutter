// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/device.pbgrpc.dart' as toit;

extension ToitDevice on toit.Device {
  String idString() {
    var bytes = this.id;
    var hex = bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join();
    return "${hex.substring(0, 8)}-"
        "${hex.substring(8, 12)}-"
        "${hex.substring(12, 16)}-"
        "${hex.substring(16, 20)}-"
        "${hex.substring(20)}";
  }
}

class Device extends StatelessWidget {
  toit.Device _device;

  Device(this._device) : super(key: ValueKey(_device.idString()));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(_device.config.name),
          Text(_device.idString()),
        ]
      )
    );
  }
}

class DevicesList extends StatelessWidget {
  final List<toit.Device> _entries;

  DevicesList(this._entries);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _entries.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          child: Device(_entries[index]),
        );
      },
    );
  }
}

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
      FutureBuilder<List<toit.Device>>(
        future: _devices,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return DevicesList(snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        }
      ),
    );
  }
}
