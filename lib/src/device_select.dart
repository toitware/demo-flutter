// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:toit_api/toit/api/device.pbgrpc.dart' as toit;

/// A provider for a selected device.
///
/// Because of the 'family' we can keep track of multiple selected devices.
///
/// The provider can be used as follows:
/// ```
/// ref.watch(selectedDeviceProvider("<some-string-id>")).state;
/// ```
///
/// The `ref` comes from Riverpod, and is generally obtained by using
/// `ConsumerXWidget` and `ConsumerState` instead of the usual `XWidget` and
/// `State`. (Where "X" stands for "Stateful" and "Stateless").
final selectedDeviceProvider =
    StateProvider.family<String?, String>((ref, id) => null);

/// Widget to select one of the available devices.
///
/// Uses the given [ToitApi] to fetch a list of available devices.
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
    // If this list is shown for a longer period, it would make sense to
    // rerun this call periodically to keep an up-to-date list.
    _devices = widget._toitApi.deviceServiceStub
        .listDevices(toit.ListDevicesRequest())
        .then((response) => response.devices);
  }

  Widget _dropdown(BuildContext context, List<toit.Device> devices) {
    // Use the 'selectedDeviceProvider' to determine which device was selected
    // earlier.
    var selectedId = ref.watch(selectedDeviceProvider(widget.id)).state;
    var found = false;
    var items = devices.map((dev) {
      var isConnected = dev.status.connected;
      var uuid = Uuid.unparse(dev.id);
      // If the device isn't online anymore, treat it as if we didn't find it.
      // This way we won't provide a default for a device that isn't available.
      if (uuid == selectedId && isConnected) found = true;
      return DropdownMenuItem(
        // We are only allowing to select connected devices.
        // This is, because the demo always wants to interact with the device.
        // In other use-cases it would make sense to allow to select all
        // devices, or to use a filter predicate.
        enabled: isConnected,
        value: uuid,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dev.config.name,
                // Since we don't allow to select non-connected devices (see
                // above), we also show them in the "unselectedWidgetColor".
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
      // This happens when the list of devices has changed.
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
