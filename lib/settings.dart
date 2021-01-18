import 'package:flutter/material.dart';
import "package:esense_flutter/esense.dart";
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

const String CONFIG_ESENSE_NAME = "esenseName";
const String CONFIG_TAP_TO_SET_GPS = "tapToGPS";

class SettingsPage extends StatefulWidget {
  static const String routeName = "/settings";
  @override
  State<SettingsPage> createState() => SettingsState();
}

class SettingsState extends State<SettingsPage> {
  String esenseName = "Kein Gerät ausgewählt";
  bool esenseSelected = false;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool tapToSetGPS = true;
  SharedPreferences prefs;

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      this.prefs = prefs;
      var v = prefs.getString(CONFIG_ESENSE_NAME);

      setState(() {
        if (v != null) {
          esenseName = v;
          esenseSelected = true;
        }
        tapToSetGPS = prefs.getBool(CONFIG_TAP_TO_SET_GPS) ?? false;

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
        body: Padding(
            padding: EdgeInsets.only(left: 10),
            child: Column(children: [
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
              Row(children: [
                Text("Tippen um Standort zu bewegen"),
                Checkbox(
                    value: tapToSetGPS,
                    onChanged: (value) {
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setBool(CONFIG_TAP_TO_SET_GPS, value);
                        setState(() {
                          tapToSetGPS = value;
                        });
                      });
                    })
              ]),
            ])));
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
  final SCAN_DURATION = Duration(seconds: 5);
  final MAC_PREFIX = "00:04:79:";
  Timer scanTimer;

  @override
  void initState() {
    super.initState();

    blueDevices = List<Widget>();
    flutterBlue.startScan(timeout: SCAN_DURATION);
    subscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        setState(() {
          if (!devicesAdded) {
            blueDevices.clear();
            devicesAdded = true;
            scanTimer.cancel();
          }

          if (!r.device.id.toString().startsWith(MAC_PREFIX)) return;

          blueDevices.add(SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, r.device.name);
            },
            child: Text(r.device.name),
          ));
        });
      }
    });

    scanTimer = new Timer(SCAN_DURATION, () {
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
    scanTimer?.cancel();
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
