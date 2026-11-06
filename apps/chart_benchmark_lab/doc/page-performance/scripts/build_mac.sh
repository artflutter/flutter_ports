#!/bin/zsh
# Usage: build_mac.sh <app dir> <side name> <out dir>. Builds the page driver for macOS, in low priority.
APP=$1; SIDE=$2; OUT=$3
cd $APP
taskpolicy -b ~/fvm/versions/beta/bin/flutter build macos --profile -t tool/perf_page.dart > $OUT/$SIDE.mac.log 2>&1 && rm -rf $OUT/$SIDE.app && cp -R build/macos/Build/Products/Profile/chart_benchmark_lab.app $OUT/$SIDE.app
echo done mac $SIDE
