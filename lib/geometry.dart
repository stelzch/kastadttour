import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

/*
   Tests whether a given point is in the polygon. This assumes the coordinates
   are cartesian (which is not true for geographic coordinates, but because the
   points in polygon are close enough to each other, the difference is
   negligible.

   Source:
   https://github.com/Sacchid/poly/blob/d3e5414d01ec28edb05f20a8cc1afbb8fce4dec7/lib/poly.dart#L296-L320
*/
bool pointInPolygon(List<LatLng> polygon, LatLng point) {
  /* Copyright (c) 2016, Bernhard Pichler Copyright (c) 2019, Sacchid */
  num ax = 0;
  num ay = 0;
  num bx = polygon.last.latitude - point.latitude;
  num by = polygon.last.longitude - point.longitude;
  int depth = 0;

  for (int i = 0; i < polygon.length; i++) {
    ax = bx;
    ay = by;
    bx = polygon[i].latitude - point.latitude;
    by = polygon[i].longitude - point.longitude;

    if (ay < 0 && by < 0) continue; // both "up" or both "down"
    if (ay > 0 && by > 0) continue; // both "up" or both "down"
    if (ax < 0 && bx < 0) continue; // both points on left

    num lx = ax - ay * (bx - ax) / (by - ay);

    if (lx == 0) return true; // point on edge
    if (lx > 0) depth++;
  }

  return (depth & 1) == 1;
}
