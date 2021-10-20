// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/device.pbgrpc.dart' as toit;

// We could use a non-family provider, but this way we could select
// multiple devices at the same time.
final selectedDeviceProvider =
    StateProvider.family<String?, String>((ref, id) => null);

class DeviceSelector extends ConsumerStatefulWidget {
  final String id;
  final ToitApi _toitApi;

  DeviceSelector(this.id, this._toitApi, {Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DeviceSelectorState();
}

class _DeviceSelectorState extends ConsumerState<DeviceSelector> {
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

  Widget _dropdown(BuildContext context, List<toit.Device> devices) {
    var selectedId = ref.watch(selectedDeviceProvider(widget.id)).state;
    var found = false;
    var items = devices.map((dev) {
      var isConnected = dev.status.connected;
      var uuid = Uuid.unparse(dev.id);
      if (uuid == selectedId) found = true;
      return DropdownMenuItem(
        enabled: isConnected,
        value: uuid,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dev.config.name,
                style: isConnected
                    ? null
                    : TextStyle(color: Theme.of(context).unselectedWidgetColor)),
            Text(
              '⬤',
              style: TextStyle(color: isConnected ? Colors.green : Colors.red),
            )
          ],
        ),
      );
    }).toList();
    if (!found) {
      // Don't set a default that doesn't exist.
      selectedId = null;
    }
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: "Device"),
      value: selectedId,
      items: items,
      hint: Text("Select device"),
      onChanged: (newValue) {
        ref.read(selectedDeviceProvider(widget.id)).state = newValue;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<toit.Device>>(
        future: _devices,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _dropdown(context, snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          } else {
            return CircularProgressIndicator();
          }
        });
  }
}
