import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';

FlutterLocalNotificationsPlugin _flnp;
const _androidPlatformSpecifics = AndroidNotificationDetails(
    'KaCityGuideId', 'KaCityGuideName', 'KaCityGuide Description',
    importance: Importance.Default,
    priority: Priority.Default,
    timeoutAfter: 2000,
    autoCancel: true);
const _iOSPlatformChannelSpecifics = IOSNotificationDetails();

const _platformChannelSpecifics = NotificationDetails(
    _androidPlatformSpecifics, _iOSPlatformChannelSpecifics);

Future initNotifications() {
  _flnp = FlutterLocalNotificationsPlugin();
  var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
  var IOS = new IOSInitializationSettings();
  var settings = new InitializationSettings(android, IOS);
  _flnp.initialize(settings);
}

Future showNotification(String head, String body, {int id}) async {
  await _flnp.show(id ?? 0, head, body, _platformChannelSpecifics,
      payload: 'Default_sound');
}

Future cancelNotification(int id) async {
  await _flnp.cancel(id);
}
