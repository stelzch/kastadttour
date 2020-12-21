#!/bin/sh
flutter logs > .logfile
awk -F "|" '/ESENSELOG/ {print $3 }' \
    < .logfile \
    > "logs/$(date '+esensor_%Y%m%d-%H_%M_%S.csv')"
