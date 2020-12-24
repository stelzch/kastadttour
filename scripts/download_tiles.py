#!/usr/bin/python3
# Usage: ZOOM_MIN=zmin ZOOM_MAX=zmax BBOX=left,bottom,right,top download_tiles.py 
# Where zmin and zmax are integer numbers between 0 and 17
# left,bottom,right,top are coordinates as double numbers
#
# The tiles will be put in the 


import math
import os
# Source: https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = math.radians(lat_deg)
  n = 2.0 ** zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
  return (xtile, ytile)

zmin = int(os.environ['ZOOM_MIN'])
zmax = int(os.environ['ZOOM_MAX'])
left, bottom, right, top = map(lambda x: float(x), os.environ['BBOX'].split(','))

for z in range(zmin, zmax+1):
    xmin, ymin = deg2num(top, left, z)
    xmax, ymax = deg2num(bottom, right, z)
    for y in range(ymin, ymax+1):
        for x in range(xmin, xmax+1):
            url = "http://127.0.0.1:8087/tile/" + "/".join([str(z), str(x), str(y)]) + ".png"
            print(url)
