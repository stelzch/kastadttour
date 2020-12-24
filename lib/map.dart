import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'location_overview.dart';

class MapPage extends StatefulWidget {
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  MapController _mapController;
  final LatLng swMapCorner = LatLng(48.9906, 8.3657);
  final LatLng neMapCorner = LatLng(49.0257, 8.4358);

  @override
  void initState() {
    super.initState();

    _mapController = MapController();
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
          children: const <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue),
              child: Text('KaCityGuide',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Einstellungen'),
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
            ],
          ))
        ]),
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.my_location), onPressed: () {}));
  }
}
