#!/bin/sh
gnuplot -e "filename='$1'" scripts/plot.gnuplot  | imv -
