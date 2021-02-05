import 'package:flutter/material.dart';
import "package:esense_flutter/esense.dart";
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'dart:async';

import 'settings.dart';

class InteractPage extends StatefulWidget {
  State<InteractPage> createState() => InteractState();
}

class InteractState extends State<InteractPage> {
  String sensorVal = "not read";
  String mstate = "---";
  Timer t;

  @override
  void initState() {
    super.initState();

    t = Timer.periodic(Duration(milliseconds: 250), timedRead);
  }

  void timedRead(t) {
    setState(() {
      mstate = "Walking: ${ESenseInteract().isWalking()}";
      sensorVal = (ESenseInteract().gyroTimeseries.length > 0)
          ? ESenseInteract().gyroTimeseries.last?.toString()
          : "null";
    });
  }

  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text("Interact")),
      body: Column(children: [
        Text(sensorVal),
        Text(mstate),
        ElevatedButton(
            child: Text("Reconnect"),
            onPressed: () {
              ESenseInteract().reconnect();
            }),
      ]),
    );
  }

  @override
  void dispose() {
    t.cancel();
    super.dispose();
  }
}

class ESenseInteract {
  StreamSubscription sensorSub;
  StreamSubscription connEventSub;
  StreamSubscription esenseSub;
  AccelerometerOffsetRead offset;
  num lastGyroY = 2.0;

  static final ESenseInteract _instance = ESenseInteract._init();
  var gyroTimeseries = [];

  void sensorEvent(SensorEvent e) {
    //print("Sensor event: $e");
    if (offset == null) return;
    var now = new DateTime.now();

    var accScaleFac = 16384.0; // Scale factor for +-2g sensor range
    var accX = e.accel[0] / accScaleFac;
    var accY = e.accel[1] / accScaleFac;
    var accZ = e.accel[2] / accScaleFac;

    var gyroScaleFac = 131.0; // Scale factor for +-250 deg sensor range
    var gyroX = e.gyro[0] / gyroScaleFac;
    var gyroY = e.gyro[1] / gyroScaleFac;
    var gyroZ = e.gyro[2] / gyroScaleFac;

    //print(
    //    "ESENSELOG||${now.toIso8601String()},$accX,$accY,$accZ,${e.gyro[0]},${e.gyro[1]},${e.gyro[2]}");
    print("ESENSE|$accZ | $gyroX $gyroY $gyroZ");

    if (gyroTimeseries.length >= 10) gyroTimeseries.removeAt(0);
    gyroTimeseries.add(gyroY);
    lastGyroY = gyroY;
  }

  bool isWalking() {
    if (gyroTimeseries.length != 10) return false;

    var previousAvg =
        gyroTimeseries.sublist(0, 5).reduce((a, b) => a + b) / 5.0;

    var now = gyroTimeseries[9];
    var diff = previousAvg - now;

    return lastGyroY.abs() < 1.0;
  }

  void esenseEvents(e) {
    print("Esense event: $e");

    if (e.runtimeType == AccelerometerOffsetRead) {
      offset = e;
    }
  }

  void connectionEvent(ConnectionEvent e) async {
    print("Connection event: $e");
    if (e.type == ConnectionType.connected) {
      await sensorSub?.cancel();
      await ESenseManager.setSamplingRate(1);

      esenseSub = ESenseManager.eSenseEvents.listen(esenseEvents);
      Timer(Duration(seconds: 2), ESenseManager.getAccelerometerOffset);

      Timer(Duration(seconds: 5), () async {
        print("Starting sensor read");
        sensorSub = ESenseManager.sensorEvents.listen(sensorEvent);
      });
    }
  }

  void connectEsense(prefs) async {
    var name = prefs.getString(CONFIG_ESENSE_NAME);
    if (name == null) return;

    print("Connecting to $name");
    await ESenseManager.connect(name);
  }

  factory ESenseInteract() {
    return _instance;
  }

  ESenseInteract._init() {
    SharedPreferences.getInstance().then(connectEsense);

    connEventSub = ESenseManager.connectionEvents.listen(connectionEvent);
  }

  void reconnect() {
    sensorSub?.cancel();
    esenseSub?.cancel();
    connEventSub?.cancel();
    ESenseManager.disconnect().then((v) {
      SharedPreferences.getInstance().then(connectEsense);
      connEventSub = ESenseManager.connectionEvents.listen(connectionEvent);
    });
  }

  static void stop() {
    _instance.dispose();
  }

  @override
  void dispose() {
    print("Destructing ESenseManager");
    sensorSub?.cancel();
    esenseSub?.cancel();
    connEventSub?.cancel();
    ESenseManager.disconnect();
  }
}
