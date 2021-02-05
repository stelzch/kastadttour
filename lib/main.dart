import 'package:flutter/material.dart';
import 'settings.dart';
import 'location_overview.dart';
import 'map.dart';
import 'persistence.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notifications.dart';
import 'audio.dart';
import 'about.dart';

FlutterLocalNotificationsPlugin notifications;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initNotifications();
  initAudio();
  await LocationInfoDB.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'KA Stadtführer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MapPage(),
        routes: {
          SettingsPage.routeName: (ctx) => SettingsPage(),
          AboutPage.routeName: (ctx) => AboutPage(),
        });
  }
}
