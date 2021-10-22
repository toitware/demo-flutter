// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toit_api/toit/api/program.pbgrpc.dart' as toit;

import 'device_select.dart';
import 'toit_api.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

class RunWidget extends ConsumerStatefulWidget {
  final String _code;
  final String _selectedDeviceId;

  RunWidget({required String code, required String selectedDeviceId, Key? key})
      : _code = code,
        _selectedDeviceId = selectedDeviceId,
        super(key: key);

  @override
  _RunWidgetState createState() => _RunWidgetState();
}

class _RunWidgetState extends ConsumerState<RunWidget> {
  String? _text = "";
  StreamSubscription? _subscription;

  Future<void> _sendProgram(ToitApi toitApi, String selectedDevice) async {
    var sources = toit.ProgramSource_Files(entryFilename: 'main.toit', files: {
      'main.toit': utf8.encode(widget._code),
    });
    setState(() {
      _text = null;
    });
    var request = toit.DeviceRunRequest(
      deviceId: Uuid.parse(selectedDevice),
      source: toit.ProgramSource(files: sources),
    );
    var response = toitApi.programServiceStub.deviceRun(request);
    _subscription = response.listen((responseLine) {
      var line = utf8
          .decode(responseLine.hasErr() ? responseLine.err : responseLine.out);
      setState(() {
        _text = (_text ?? "") + line;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var toitApi = ref.watch(toitApiProvider).state!;
    var selectedDevice =
        ref.watch(selectedDeviceProvider(widget._selectedDeviceId)).state;
    return Column(children: [
      Card(
        child: Row(children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
                child: Text(widget._code, style: GoogleFonts.robotoMono())),
          ),
          Spacer(),
        ]),
      ),
      DeviceSelector(widget._selectedDeviceId, toitApi),
      TextButton(
          onPressed: selectedDevice == null
              ? null
              : () {
                  _sendProgram(toitApi, selectedDevice);
                },
          child: Text('Run on device')),
      _text == null ? CircularProgressIndicator() : Text(_text!),
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}
