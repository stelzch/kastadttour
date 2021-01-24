#!/bin/sh
inkscape --export-background-opacity=0 --export-width 48  --export-height 48  --export-filename=../android/app/src/main/res/mipmap-mdpi/ic_launcher.png logo.svg 
inkscape --export-background-opacity=0 --export-width 72  --export-height 72  --export-filename=../android/app/src/main/res/mipmap-hdpi/ic_launcher.png logo.svg 
inkscape --export-background-opacity=0 --export-width 96  --export-height 96  --export-filename=../android/app/src/main/res/mipmap-xhdpi/ic_launcher.png logo.svg
inkscape --export-background-opacity=0 --export-width 144 --export-height 144 --export-filename=../android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png logo.svg
inkscape --export-background-opacity=0 --export-width 192 --export-height 192 --export-filename=../android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png logo.svg 
