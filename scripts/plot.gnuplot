set terminal png size 1920,1080
set datafile separator comma
set xdata time
#set timefmt "%Y-%m-%d %H:%M:%S"
set timefmt "%Y-%m-%dT%H:%M:%S"
set autoscale x
set autoscale y

set multiplot title "eSense Sensor Reading" layout 2,3 rowsfirst
set xlabel "Time"

# Accelerometer reading
set ylabel "AccelX"
plot filename using 1:2

set ylabel "AccelY"
plot filename using 1:3

set ylabel "AccelZ"
plot filename using 1:4

# Gyroscope
set ylabel "GyroX"
plot filename using 1:5

set ylabel "GyroY"
plot filename using 1:6

set ylabel "GyroZ"
plot filename using 1:7

unset multiplot
