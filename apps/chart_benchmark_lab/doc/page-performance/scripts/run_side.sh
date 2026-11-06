#!/bin/zsh
# Usage: run_side.sh <side> <run number> [targets]. One after the other: Chrome, Safari, Firefox, macOS, Pixel.
SIDE=$1; RUN=$2; TARGETS=${3:-chrome safari firefox macos android}
S=${0:a:h}; R=$S/results/$SIDE.$RUN; mkdir -p $R
for T in ${=TARGETS}; do
  case $T in
    chrome|safari|firefox) node $S/web_tool.mjs run $T $S/$SIDE.web $R/$T.txt 300 || { echo "$T failed: $?"; exit 1; } ;;
    macos)
      : > $R/macos.txt
      open -g -n --stdout $R/macos.txt --stderr $R/macos.err $S/$SIDE.app --args -NSAppSleepDisabled YES
      sleep 6; W=$($S/windows | grep '^window chart_benchmark_lab' | head -1); echo "macos window: $W"
      X=$(echo "$W" | sed -E 's/.* x=(-?[0-9]+).*/\1/')
      if [ -z "$X" ] || [ "$X" -lt 2560 ]; then echo "STOP: the macOS window is not on the built-in display"; pkill -f $S/$SIDE.app; exit 3; fi
      t0=$(date +%s); while [ $(( $(date +%s) - t0 )) -lt 300 ]; do grep -q MATRIX_DONE $R/macos.txt && break; sleep 2; done
      echo "macos lines $(grep -c '^PAGE ' $R/macos.txt) after $(( $(date +%s) - t0 )) s"; sleep 1; pkill -f $S/$SIDE.app ;;
    android) python3 -I $S/run_android_page.py $S/$SIDE.apk $R/android.txt 400 | tail -3 ;;
  esac
done
echo "side $SIDE run $RUN finished"
