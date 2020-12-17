import 'package:flutter/material.dart';
import "package:esense_flutter/esense.dart";
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => SettingsState();
}

class SettingsState extends State<SettingsPage> {
  String esenseName = "Kein Gerät ausgewählt";
  bool esenseSelected = false;

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      var v = prefs.getString("esenseName");
      if (v == null) return;
      setState(() {
        esenseName = v;
        esenseSelected = true;
      });
    });
  }

  void selectEsense(ctx) {
    showDialog(
        context: ctx,
        builder: (BuildContext ctx) {
          return BlueDeviceSelector();
        });
  }

  void getEsenseInfo() {}

  @override
  Widget build(BuildContext ctx) {
    var x = ESenseManager();
    ESenseManager.connectionEvents.listen((event) {
      print('Connection event: $event');
    });

    FlutterBlue flutterBlue = FlutterBlue.instance;

    flutterBlue.startScan(timeout: Duration(seconds: 5));
    var sub = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('${r.device.name} found, rssi: ${r.rssi}, ${r.device}');
      }
    });

    return Scaffold(
        appBar: AppBar(
          title: Text("Einstellungen"),
        ),
        body: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("eSense"),
            ElevatedButton(
              child: Text(esenseName),
              onPressed: () {
                selectEsense(ctx);
              },
            ),
            ElevatedButton(child: Icon(Icons.info), onPressed: getEsenseInfo),
          ]),
        ]));
  }
}

class BlueDeviceSelector extends StatefulWidget {
  @override
  State<BlueDeviceSelector> createState() => BlueDeviceSelectorState();
}

class BlueDeviceSelectorState extends State<BlueDeviceSelector> {
  List<Widget> blueDevices;
  bool devicesAdded = false;
  StreamSubscription subscription;
  FlutterBlue flutterBlue = FlutterBlue.instance;

  @override
  void initState() {
    super.initState();

    blueDevices = List<Widget>();
    flutterBlue.startScan(timeout: Duration(seconds: 5));
    subscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        setState(() {
          if (!devicesAdded) {
            blueDevices.clear();
            devicesAdded = true;
          }

          blueDevices.add(SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, r.device.name);
            },
            child: Text(r.device.name),
          ));
        });
      }
    });

    blueDevices.add(Center(child: CircularProgressIndicator()));
  }

  @override
  Widget build(BuildContext ctx) {
    return SimpleDialog(
        title: const Text('eSense auswählen'), children: blueDevices);
  }

  @override
  void dispose() {
    super.dispose();

    subscription?.cancel();
  }
}
