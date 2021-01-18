import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_overview.dart';
import 'persistence.dart';
import 'audio.dart';
import 'settings.dart';
import 'geometry.dart';
import 'notifications.dart';

class MapPage extends StatefulWidget {
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  MapController _mapController;
  final LatLng swMapCorner = LatLng(48.9906, 8.3657);
  final LatLng neMapCorner = LatLng(49.0257, 8.4358);
  StreamSubscription dbSub;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
    dbSub = LocationInfoDB.updateStream().listen(dbUpdated);
    SharedPreferences.getInstance().then((v) {
      setState(() {
        prefs = v;
      });
    });
  }

  void dbUpdated(_) {
    setState(() {});
  }

  List<Polygon> getPolygons() {
    assert(LocationInfoDB.allCached, "LocationInfoDB not loaded properly");
    return LocationInfoDB.cachedLocations
        .where((i) => i.lastVisit == null)
        .map((i) => Polygon(
              points: i.zone,
              color: Color.fromARGB(100, 50, 50, 255),
              borderColor: Color.fromARGB(255, 0, 0, 100),
              borderStrokeWidth: 1.0,
            ))
        .toList();
  }

  void _handleMapTap(LatLng latlng) {
    if (prefs.getBool(CONFIG_TAP_TO_SET_GPS)) {
      _locationUpdate(latlng);
    }
  }

  void _locationUpdate(LatLng pos) {
    print("Now at location ${pos.latitude} ${pos.longitude}");

    // check for polygon intersections
    bool areaEntered = false;
    assert(LocationInfoDB.allCached, "LocationInfoDB not loaded properly");
    for (LocationInfo info in LocationInfoDB.cachedLocations) {
      // If the place is already visited, we do not need to consider it for
      // collision
      if (info.lastVisit != null) continue;

      if (pointInPolygon(info.zone, pos)) {
        showNotification("Neuen Ort entdeckt", "Willkommen am ${info.name}",
            id: 0);
        queueAudio(info);
        areaEntered = true;

        // Mark the area as visited
        LocationInfo modified = info.copyWith(lastVisit: DateTime.now());
        LocationInfoDB.updateLastVisit(modified).then((v) {
          print("Finished DB UPdate");
          setState(() {}); // Needed so the polygon vanishes from the map
        });
      }
    }

    if (!areaEntered) {
      dequeueAudio();
      cancelNotification(0);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Karte"),
          actions: [
            IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  Navigator.pushNamed(ctx, LocationOverview.routeName);
                })
          ],
        ),
        drawer: Drawer(
            child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue),
              child: Text('KaCityGuide',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Einstellungen'),
              onTap: () {
                Navigator.pushNamed(ctx, SettingsPage.routeName);
              },
            ),
            Padding(
                padding: EdgeInsets.only(top: 30, left: 8),
                child: Text("© 2020 Christoph Stelz")),
          ],
        )),
        body: Column(children: [
          Flexible(
              child: FlutterMap(
            options: MapOptions(
                controller: _mapController,
//                bounds: LatLngBounds(
//                    LatLng(48.9906, 8.3657), LatLng(49.0257, 8.4358)),
                center: LatLng(49.014, 8.40447),
                zoom: 14,
                minZoom: 12,
                maxZoom: 17,
                screenSize: MediaQuery.of(ctx).size,
                slideOnBoundaries: true,
                onTap: _handleMapTap,
                swPanBoundary: LatLng(48.9906, 8.3657),
                nePanBoundary: LatLng(49.0257, 8.4358)),
            layers: [
              TileLayerOptions(
                tileProvider: AssetTileProvider(),
                maxZoom: 18.0,
                urlTemplate: "assets/map/{z}/{x}/{y}.png",
                updateInterval: 50,
                retinaMode: true,
              ),
              PolygonLayerOptions(
                polygons: getPolygons(),
                polygonCulling: false,
              ),
            ],
          ))
        ]),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.my_location), onPressed: () {}));
  }

  @override
  void dispose() {
    dbSub?.cancel();

    super.dispose();
  }
}
