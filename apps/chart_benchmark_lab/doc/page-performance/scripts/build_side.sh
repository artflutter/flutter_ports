#!/bin/zsh
# Usage: build_side.sh <app dir> <side name> <out dir>. Builds the page driver for the Pixel and for the web, in low priority.
APP=$1; SIDE=$2; OUT=$3
F=~/fvm/versions/beta/bin/flutter
cd $APP
taskpolicy -b $F build apk --profile -t tool/perf_page.dart --android-skip-build-dependency-validation > $OUT/$SIDE.apk.log 2>&1 && cp build/app/outputs/flutter-apk/app-profile.apk $OUT/$SIDE.apk
taskpolicy -b $F build web --wasm --profile -t tool/perf_page.dart > $OUT/$SIDE.web.log 2>&1 && rm -rf $OUT/$SIDE.web && cp -R build/web $OUT/$SIDE.web
echo done $SIDE
