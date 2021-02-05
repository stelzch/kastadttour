import 'dart:ui';
import 'dart:isolate';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:latlong/latlong.dart';

class BackgroundLocation {
  static StreamController<LatLng> _streamController =
      StreamController<LatLng>();
  static Stream<LatLng> _broadcastStream =
      _streamController.stream.asBroadcastStream();
  static ReceivePort port = ReceivePort();

  static Stream<LatLng> getStream() {
    return _broadcastStream;
  }

  static void start() {
    if (IsolateNameServer.lookupPortByName(
            LocationCallbackHandler._isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          LocationCallbackHandler._isolateName);
    }

    IsolateNameServer.registerPortWithName(
        port.sendPort, LocationCallbackHandler._isolateName);

    port.listen((dynamic data) async {
      print("Port received");
      print("$data");
      if (data != null &&
          _streamController.hasListener &&
          !_streamController.isPaused) {
        _streamController.add(LatLng(data.latitude, data.longitude));
      }
    });

    initPlatformState();
    _onStart();
  }

  static void stop() {
    _onStop();
  }

  static void _onStart() async {
    print("Asking for permission");
    _checkLocationPermission().then((allowed) {
      if (!allowed) {
        print("Location permission denied");
        return;
      }

      print("Starting locationServer");
      startLocationServer();
    });
  }

  static void _onStop() async {
    port.close();
    await _streamController.close();
    await IsolateNameServer.removePortNameMapping(
        LocationCallbackHandler._isolateName);
    await BackgroundLocator.unRegisterLocationUpdate();
  }

  static Future<void> initPlatformState() async {
    await BackgroundLocator.initialize();
  }

  static void startLocationServer() {
    BackgroundLocator.registerLocationUpdate(LocationCallbackHandler.callback,
        initCallback: LocationCallbackHandler.initCallback,
        initDataCallback: {},
        disposeCallback: LocationCallbackHandler.disposeCallback,
        autoStop: false,
        iosSettings: IOSSettings(
            accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 0),
        androidSettings: AndroidSettings(
          accuracy: LocationAccuracy.HIGH,
          interval: 4,
          distanceFilter: 0,
        ));
  }

  /* Source: https://github.com/rekab-app/background_locator/blob/master/example/lib/main.dart */
  static Future<bool> _checkLocationPermission() async {
    final access = await LocationPermissions().checkPermissionStatus();

    switch (access) {
      case PermissionStatus.unknown:
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await LocationPermissions().requestPermissions(
          permissionLevel: LocationPermissionLevel.locationAlways,
        );

        return (permission == PermissionStatus.granted);
        break;
      case PermissionStatus.granted:
        return true;
        break;
      default:
        return false;
        break;
    }
  }
}

/*
class MLocationPage extends StatefulWidget {
  State<MLocationPage> createState() => _LocationState();
}

class _LocationState extends State<MLocationPage> {
  String loc = "";
  StreamSubscription locSub;
  @override
  void initState() {
    super.initState();
    locSub = BackgroundLocationController.getStream().listen(locationReceived);
    BackgroundLocationController.start();
  }

  void locationReceived(LatLng location) {
    setState(() {
      loc = location.toString();
    });
  }

  @override
  void dispose() {
    locSub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LocPage"),
      ),
      body: Text(loc),
    );
  }
}
*/

class LocationCallbackHandler {
  static const String _isolateName = "LocatorIsolate";
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {}

  static Future<void> callback(LocationDto locationDto) async {
    final SendPort send = IsolateNameServer.lookupPortByName(_isolateName);
    send?.send(locationDto);
  }

  static Future<void> disposeCallback() async {}
}
