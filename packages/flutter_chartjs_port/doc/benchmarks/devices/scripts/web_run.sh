#!/bin/zsh
# Usage: web_run.sh <build dir> <out file> <timeout s> <page query>
# One dedicated Chrome on the built-in 120 Hz display, with its own profile. Ends when MATRIX_DONE arrives.
B=$1; OUT=$2; TO=$3; Q=$4; PORT=8766
S=${0:a:h}
: > $OUT
python3 -I $S/serve_lab.py $B $PORT $OUT & SRV=$!
sleep 1
PROFILE=$(mktemp -d $S/web/profile.XXXXXX)
caffeinate -d -i -t $((TO+60)) & CAF=$!
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --user-data-dir=$PROFILE --no-first-run --no-default-browser-check \
  --window-position=2600,40 --window-size=${WIN:-1400,1000} --disable-backgrounding-occluded-windows --disable-renderer-backgrounding \
  --disable-background-timer-throttling --disable-features=CalculateNativeWinOcclusion,Translate --disable-extensions \
  "http://127.0.0.1:$PORT/?$Q" > $OUT.chrome.log 2>&1 & CH=$!
t0=$(date +%s)
while [ $(( $(date +%s) - t0 )) -lt $TO ]; do
  sleep 2
  grep -q MATRIX_DONE $OUT && break
  kill -0 $CH 2>/dev/null || { echo "chrome ended"; break; }
done
kill $CH 2>/dev/null; sleep 1; kill -9 $CH 2>/dev/null
kill $SRV $CAF 2>/dev/null
rm -rf $PROFILE
echo "end $(( $(date +%s) - t0 ))s rows $(grep -cE '^(MATRIX|EVERYDAY) \{' $OUT)"
