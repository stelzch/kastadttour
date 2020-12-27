import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'location_overview.dart';
import 'persistence.dart';
import 'settings.dart';
import 'geometry.dart';

class MapPage extends StatefulWidget {
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  MapController _mapController;
  final LatLng swMapCorner = LatLng(48.9906, 8.3657);
  final LatLng neMapCorner = LatLng(49.0257, 8.4358);
  List<LocationInfo> _locationInfo;
  List<Polygon> _zonePolygons;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
    _locationInfo = List<LocationInfo>();
    _zonePolygons = List<Polygon>();

    LocationInfoDB.get().listen((location) {
      _locationInfo.add(location);

      _zonePolygons.add(Polygon(
        points: location.zone,
        color: Color.fromARGB(100, 50, 50, 255),
        borderColor: Color.fromARGB(255, 0, 0, 100),
        borderStrokeWidth: 1.0,
      ));
    });
  }

  void _handleMapTap(LatLng latlng) {
    _locationUpdate(latlng);
  }

  void _locationUpdate(LatLng pos) {
    /*
    var modifiedInfo = info.copyWith(lastVisit: DateTime.now());
    LocationInfoDB.updateLastVisit(modifiedInfo);

    setState(() {
      info = modifiedInfo;
    });
    if (action == LocationCardAction.markVisited) {
    } else {}

    setState(() {});
    */

    print("Now at location ${pos.latitude} ${pos.longitude}");

    // check for polygon intersections
    for (LocationInfo info in _locationInfo) {
      int idx = _locationInfo.indexOf(info);

      if (pointInPolygon(_zonePolygons[idx], pos)) {
        print("Now in region ${info.name}");
      }
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
                polygons: _zonePolygons,
                polygonCulling: false,
              ),
            ],
          ))
        ]),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.my_location), onPressed: () {}));
  }
}
