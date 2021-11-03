// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:grpc/grpc.dart';
import 'package:toit_api/toit/api/device.pb.dart';
import 'package:toit_api/toit/api/device.pbgrpc.dart'
    show DeviceServiceBase, ListDevicesResponse;

class UnimplementedDeviceService extends DeviceServiceBase {
  @override
  Future<ConfigureDeviceResponse> configureDevice(ServiceCall call, ConfigureDeviceRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ConfigureJobResponse> configureJob(ServiceCall call, ConfigureJobRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<GetCurrentTimeResponse> getCurrentTime(ServiceCall call, GetCurrentTimeRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<GetDeviceResponse> getDevice(ServiceCall call, GetDeviceRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<GetDevicePartitionsResponse> getDevicePartitions(ServiceCall call, GetDevicePartitionsRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<InstallJobResponse> installJob(ServiceCall call, InstallJobRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ListDevicesResponse> listDevices(ServiceCall call, ListDevicesRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ListJobsResponse> listJobs(ServiceCall call, ListJobsRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<LookupDevicesResponse> lookupDevices(ServiceCall call, LookupDevicesRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ReadDeviceEventsResponse> readDeviceEvents(ServiceCall call, ReadDeviceEventsRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ReadDeviceLogsResponse> readDeviceLogs(ServiceCall call, ReadDeviceLogsRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<RebootDeviceResponse> rebootDevice(ServiceCall call, RebootDeviceRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<UnclaimDeviceResponse> unclaimDevice(ServiceCall call, UnclaimDeviceRequest request) {
    throw UnimplementedError();
  }

  @override
  Stream<WatchDeviceChangesResponse> watchDeviceChanges(ServiceCall call, WatchDeviceChangesRequest request) {
    throw UnimplementedError();
  }

  @override
  Stream<WatchJobChangesResponse> watchJobChanges(ServiceCall call, WatchJobChangesRequest request) {
    throw UnimplementedError();
  }

  @override
  Stream<WatchSessionChangesResponse> watchSessionChanges(ServiceCall call, WatchSessionChangesRequest request) {
    throw UnimplementedError();
  }
}

Future<Server> startServer(List<Service> services) async {
  final server = Server(
    services,
    const <Interceptor>[],
    CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
  );
  await server.serve(port: 0);
  return server;
}
