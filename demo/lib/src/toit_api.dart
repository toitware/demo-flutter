// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'dart:convert';

import 'package:grpc/grpc.dart';
import 'package:toit_api/toit/api/app.pbgrpc.dart' show AppServiceClient;
import 'package:toit_api/toit/api/auth.pbgrpc.dart'
    show AuthClient, LoginRequest;
import 'package:toit_api/toit/api/data.pbgrpc.dart' show DataServiceClient;
import 'package:toit_api/toit/api/device.pbgrpc.dart'
    show Device, DeviceServiceClient, ListDevicesRequest;
import 'package:toit_api/toit/api/doctor.pbgrpc.dart' show DoctorServiceClient;
import 'package:toit_api/toit/api/hardware.pbgrpc.dart'
    show HardwareServiceClient;
import 'package:toit_api/toit/api/organization.pbgrpc.dart'
    show OrganizationServiceClient;
import 'package:toit_api/toit/api/program.pbgrpc.dart'
    show ProgramServiceClient;
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart'
    show PublishClient;
import 'package:toit_api/toit/api/sdk.pbgrpc.dart' show SDKServiceClient;
import 'package:toit_api/toit/api/simulator.pbgrpc.dart'
    show SimulatorServiceClient;
import 'package:toit_api/toit/api/pubsub/subscribe.pbgrpc.dart'
    show SubscribeClient;
import 'package:toit_api/toit/api/user.pbgrpc.dart' show UserClient;

class ToitUnauthenticatedException implements Exception {
  const ToitUnauthenticatedException();
}

class ToitApi {
  final ClientChannel _channel;
  CallOptions? _options;

  static CallOptions _optionsFromToken(String token) {
    if (token == "") {
      throw ArgumentError("AuthorizationToken can't be the empty string \"\"");
    }
    return CallOptions(metadata: {'Authorization': 'Bearer $token'});
  }

  ToitApi({String? token})
      : _channel = ClientChannel("api.toit.io"),
        _options = token == null ? null : _optionsFromToken(token);

  ToitApi.withChannel(this._channel) : _options = CallOptions();

  CallOptions _ensureOptions() {
    if (_options != null) return _options!;
    throw const ToitUnauthenticatedException();
  }

  AppServiceClient get appServiceStub =>
      AppServiceClient(_channel, options: _ensureOptions());
  AuthClient get authStub => AuthClient(_channel, options: _ensureOptions());
  DataServiceClient get dataServiceStub =>
      DataServiceClient(_channel, options: _ensureOptions());
  DeviceServiceClient get deviceServiceStub =>
      DeviceServiceClient(_channel, options: _ensureOptions());
  DoctorServiceClient get doctorServiceStub =>
      DoctorServiceClient(_channel, options: _ensureOptions());
  HardwareServiceClient get hardwareServiceStub =>
      HardwareServiceClient(_channel, options: _ensureOptions());
  OrganizationServiceClient get organizationServiceStub =>
      OrganizationServiceClient(_channel, options: _ensureOptions());
  ProgramServiceClient get programServiceStub =>
      ProgramServiceClient(_channel, options: _ensureOptions());
  PublishClient get publishStub =>
      PublishClient(_channel, options: _ensureOptions());
  SDKServiceClient get sdkServiceStub =>
      SDKServiceClient(_channel, options: _ensureOptions());
  SimulatorServiceClient get simulatorServiceStub =>
      SimulatorServiceClient(_channel, options: _ensureOptions());
  SubscribeClient get subscribeStub =>
      SubscribeClient(_channel, options: _ensureOptions());
  UserClient get userStub => UserClient(_channel, options: _ensureOptions());

  Future<void> login(String username, String password) async {
    _options = null;
    var request = LoginRequest(username: username, password: password);
    var response = await authStub.login(request);
    var tokenBytes = response.accessToken;
    var token = utf8.decode(tokenBytes);
    _options = _optionsFromToken(token);
  }
}
