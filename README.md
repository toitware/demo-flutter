# Toit Flutter Demo

A project to showcase how Flutter and Toit can work together.

![Available Demos](screenshots/home.png?raw=true)

This project is intended to be used as starting point for Flutter
applications that want to communicate with the Toit server. Just
pick the functionality that is most similar to what you need, and
remove the remaining pages.

## Implementation Note
The Toit APIs need access to the Internet.
The `android/app/src/main/AndroidManifest.xml` thus must include:

```
<uses-permission android:name="android.permission.INTERNET"/>
```

We have used [Riverpod](https://riverpod.dev) as state-management
framework. It would be straight-forward to switch to a different
framework, like [Bloc](https://bloclibrary.dev).

## Run the Demo

``` shell
flutter run
```

For running the tests:
```
flutter test
```

## Managing Devices

![Listing of all devices](screenshots/listing.png?raw=true)

The "List Devices" page demonstrates how the Flutter app can
connect to the Toit server to query all available devices.

It serves as a starting point for applications that want to
manage the Toit fleet, or simply want to show the status of
existing devices.

## Device Logs

![Device Log](screenshots/log.png?raw=true)

The "Log" example connects to the Toit server to receive the logs
of a selected device. It is one of the simplest API calls and
serves as a good starting example.

However, the logs often contain valuable information, so this
example is frequently useful in real apps.

## Run

![Run](screenshots/run.png?raw=true)

This page shows how to run code on the device. This functionality is
used in multiple demos, which is why a separate run-widget has been
created.

The used 'run' command has many limitations. It doesn't support multiple
files, and the program can only run for a limited time. Different API
endpoints are responsible for managing the installed applications. 

## Pubsub Send

![Pubsub Send](screenshots/pubsub_send.png?raw=true)

A simple pubsub example that sends a notification to the device.

This functionality can be used to send commands to devices. The Toit
server will make sure that all notifications are eventually sent to
the corresponding device (only giving up after 7 days).

Since this demo requires a receiving application on the device side,
it also has functionality to temporarily run a Toit program on the
device (similar to the "Run" demo). This functionality is independent
and would normally be removed from the Flutter application.

## Pubsub Listen In

![Pubsub Listen In](screenshots/pubsub_listen_in.png?raw=true)

This page demonstrates how a Flutter application can listen to events
that are sent to a specific topic.

The application creates a fresh subscription, which means that it will
only receive data that is sent once the subscription was created. Having
its own subscription also means that it won't interfere with other
listeners to the same topic.

This demo is primarily useful for devices that regularly send sensor data
(like temperature, or distance) to the Toit servers, but where the Flutter
application doesn't need stale data.

## Pubsub Listen Heartbeat

![Pubsub Listen Heartbeat](screenshots/pubsub_listen_heartbeat.png?raw=true)

This example illustrates how a Flutter app can request a device to start
producing data, so it can listen to it.

If producing data is expensive (in terms of power, bandwidth, ...), then
devices should only generate data if there is a listener for it. The
listeners thus initiate the generation of data by sending a request.
The listeners are furthermore supposed to send a 'stop' signal, when they
don't need data anymore. However, listeners may misbehave (for example by
losing power). To protect against missing 'stop' events, the device
requires listeners to send heartbeat notifications at fixed intervals to
ensure that they are still alive and are still interested in the data.

Note: in this example, the request to receive data, and the heartbeat
notification have been merged.

## Pubsub RPC

![Pubsub RPC](screenshots/pubsub_rpc.png?raw=true)

In this demo, the pubsub API is used to establish an RPC (remote procedure
call) channel, so that the Flutter app can invoke methods on the device.

It uses the 'publish' functionality to send requests to the device, and
receives the response in a stream.

The demo only supports methods that are initiated by the Flutter app, but
it would be trivial to extend it so that the device can invoke end-points on
the Flutter side as well.
