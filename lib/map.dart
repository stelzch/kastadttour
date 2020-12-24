import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class MapPage extends StatefulWidget {
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
        appBar: AppBar(title: Text("Karte")),
        body: Padding(
            padding: EdgeInsets.all(8),
            child: Column(children: [
              Flexible(
                  child: FlutterMap(
                options: MapOptions(
                    center: LatLng(48.9907, 8.39),
                    zoom: 13,
                    minZoom: 12,
                    maxZoom: 18,
                    swPanBoundary: LatLng(48.9906, 8.3657),
                    nePanBoundary: LatLng(49.0257, 8.4358)),
                layers: [
                  //TileLayerOptions(
                  //    urlTemplate:
                  //        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  //    subdomains: ['a', 'b', 'c']),
                  TileLayerOptions(
                    tileProvider: AssetTileProvider(),
                    urlTemplate: "assets/map/{z}/{x}/{y}.png",
                    retinaMode: true,
                  ),
                ],
              ))
            ])));
  }
}
