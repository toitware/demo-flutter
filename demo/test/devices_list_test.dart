// Copyright (C) 2021 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toit_api/toit/api/device.pb.dart';
import 'package:grpc/grpc.dart';

import 'package:demo/main.dart';
import 'package:demo/src/toit_api.dart';
import 'package:demo/src/login.dart';
import 'package:toit_api/toit/model/device.pb.dart';
import 'fake_grpc.dart';

class FakeDeviceService extends UnimplementedDeviceService {
  Future<ListDevicesResponse> listDevices(
      ServiceCall call, ListDevicesRequest request) async {
    return ListDevicesResponse(devices: [
      Device(
        id: List.generate(16, (i) => i),
        config: DeviceConfig(name: "device1"),
      ),
      Device(
        id: List.generate(16, (i) => 16 - i),
        config: DeviceConfig(name: "device2"),
      ),
    ]);
  }
}

void main() {
  group('Devices', () {
    late Server server;

    setUp(() async {
      server = await startServer([FakeDeviceService()]);
      var options =
          const ChannelOptions(credentials: ChannelCredentials.insecure());
      var channel =
          ClientChannel('localhost', port: server.port!, options: options);
      toitApi_ = ToitApi.withChannel(channel);
    });

    tearDown(() {
      server.shutdown();
    });

    testWidgets('Toit shows devices', (WidgetTester tester) async {
      await tester.runAsync(() async {
        var app = ProviderScope(child: MyApp());
        // Build our app and trigger a frame.
        await tester.pumpWidget(app);

        await tester.tap(find.text('List Devices'));

        var stopWatch = Stopwatch()..start();
        // Give up to 1 second to get the asynchronous data.
        while (stopWatch.elapsedMilliseconds < 1000) {
          await tester.pumpWidget(app);
          if (find.text('device1').evaluate().isEmpty) {
            // Yield.
            await Future.delayed(Duration());
          }
        }

        // Verify that our counter starts at 0.
        expect(find.text('device1'), findsOneWidget);
        expect(find.text('device2'), findsOneWidget);
        expect(find.text('1'), findsNothing);
      });
    });
  });
}
