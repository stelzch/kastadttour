import 'package:flutter/material.dart';
import "package:esense_flutter/esense.dart";
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

const String CONFIG_ESENSE_NAME = "esenseName";

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => SettingsState();
}

class SettingsState extends State<SettingsPage> {
  String esenseName = "Kein Gerät ausgewählt";
  bool esenseSelected = false;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      var v = prefs.getString(CONFIG_ESENSE_NAME);
      if (v == null) return;
      setState(() {
        esenseName = v;
        esenseSelected = true;

        ESenseManager.connect(esenseName);
      });
    });
  }

  void selectEsense(ctx) async {
    if (!(await flutterBlue.isOn)) {
      final errorSnackBar = SnackBar(
          content: Row(children: [
        Padding(
            child: Icon(Icons.error, color: Colors.white),
            padding: const EdgeInsets.only(right: 15)),
        Text("Bitte Bluetooth aktivieren"),
      ]));
      _scaffoldKey.currentState.showSnackBar(errorSnackBar);
      return;
    }
    var deviceName = await showDialog(
        context: ctx,
        builder: (BuildContext ctx) {
          return BlueDeviceSelector();
        });

    print("Selected device $deviceName");
    if (deviceName != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(CONFIG_ESENSE_NAME, deviceName);
      });

      setState(() {
        esenseName = deviceName;
        ESenseManager.connect(deviceName);
      });
    }
  }

  void getEsenseInfo(ctx) async {
    await showDialog(
        context: ctx,
        builder: (BuildContext ctx) {
          return ESenseInfo();
        });
  }

  @override
  Widget build(BuildContext ctx) {
    var x = ESenseManager();
    ESenseManager.connectionEvents.listen((event) {
      print('Connection event: $event');
    });

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Einstellungen"),
        ),
        body: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Text("eSense"),
            ElevatedButton(
              child: Text(esenseName),
              onPressed: () {
                selectEsense(ctx);
              },
            ),
            ElevatedButton(
                child: Icon(Icons.info),
                onPressed: () {
                  getEsenseInfo(ctx);
                }),
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
  final scanTimeout = Duration(seconds: 5);
  Timer scanTimer;

  @override
  void initState() {
    super.initState();

    blueDevices = List<Widget>();
    flutterBlue.startScan(timeout: scanTimeout);
    subscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        setState(() {
          if (!devicesAdded) {
            blueDevices.clear();
            devicesAdded = true;
            scanTimer.cancel();
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

    scanTimer = new Timer(scanTimeout, () {
      setState(() {
        if (!devicesAdded) {
          blueDevices.clear();
          blueDevices.add(Center(child: Text("Keine Geräte gefunden")));
        }
      });
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

class ESenseInfo extends StatefulWidget {
  @override
  State<ESenseInfo> createState() => ESenseInfoState();
}

class ESenseInfoState extends State<ESenseInfo> {
  List<Widget> content;
  @override
  void initState() {
    super.initState();

    content = [Center(child: CircularProgressIndicator())];

    ESenseManager.isConnected().then((isConnected) async {
      if (!isConnected) {
        setState(() {
          content = [
            Center(
                child: const Text(
                    "eSense nicht verbunden.\nWar das richtige Gerät ausgewählt?\nSind die Earables eingeschaltet und in der Nähe?\nIst Bluetooth eingeschaltet?"))
          ];
        });
      } else {
        var name = await ESenseManager.getDeviceName();
        setState(() {
          content = [
            Center(child: const Text("Erfolgreich mit Earables verbunden")),
          ];
        });
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    return SimpleDialog(title: const Text('eSense Info'), children: content);
  }
}
