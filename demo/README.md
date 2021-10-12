# Toit Demo

A project to showcase how Flutter and Toit can work together.

## Implementation Note
The Toit APIs need access to the Internet.
The `android/app/src/main/AndroidManifest.xml` thus must include:

```
<uses-permission android:name="android.permission.INTERNET"/>
```

## Run the Demo

``` shell
flutter run
```

For running the tests:
```
flutter test
```
