import 'package:flutter/material.dart';
import "package:esense_flutter/esense.dart";
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import 'settings.dart';

class YesNoDialog extends StatefulWidget {
  @override
  State<YesNoDialog> createState() => YesNoDialogState();
}

class YesNoDialogState extends State<YesNoDialog> {
  StreamSubscription sensorSub;
  StreamSubscription connEventSub;
  StreamSubscription esenseSub;
  AccelerometerOffsetRead offset;

  void sensorEvent(SensorEvent e) {
    //print("Sensor event: $e");
    if (offset == null) return;
    var now = new DateTime.now();

    var accX = e.accel[0] + offset.offsetX;
    var accY = e.accel[1] + offset.offsetY;
    var accZ = e.accel[2] + offset.offsetZ;

    print(
        "ESENSELOG||${now.toIso8601String()},$accX,$accY,$accZ,${e.gyro[0]},${e.gyro[1]},${e.gyro[2]}");
  }

  void esenseEvents(e) {
    print("Esense event: $e");

    if (e.runtimeType == AccelerometerOffsetRead) {
      setState(() {
        offset = e;
      });
    }
  }

  void connectionEvent(ConnectionEvent e) async {
    print("Connection event: $e");
    if (e.type == ConnectionType.connected) {
      await sensorSub?.cancel();
      await ESenseManager.setSamplingRate(50);

      esenseSub = ESenseManager.eSenseEvents.listen(esenseEvents);
      Timer(Duration(seconds: 1), ESenseManager.getAccelerometerOffset);

      // Start sensor reads after 3 seconds
      Timer(Duration(seconds: 3), () async {
        print("Starting sensor read");
        var sub = ESenseManager.sensorEvents.listen(sensorEvent);

        setState(() {
          sensorSub = sub;
        });
      });
    }
  }

  void connectEsense(prefs) async {
    var name = prefs.getString(CONFIG_ESENSE_NAME);
    if (name == null) return;

    print("Connecting to $name");
    await ESenseManager.connect(name);
  }

  @override
  void initState() {
    SharedPreferences.getInstance().then(connectEsense);

    connEventSub = ESenseManager.connectionEvents.listen(connectionEvent);
  }

  @override
  Widget build(BuildContext ctx) {
    return Text("YES OR NAH?");
  }

  @override
  void dispose() async {
    sensorSub?.cancel();
    esenseSub?.cancel();
    connEventSub?.cancel();
    await ESenseManager.disconnect();

    super.dispose();
  }
}
