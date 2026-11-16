#!/usr/bin/env bash
# Original code, not ported from d3-interpolate: the runner of the benchmark.
#
# Usage: tool/bench/run_bench.sh <out dir> ["targets"] [-- bench arguments]
# The targets are one quoted list with spaces (default "node aot js wasm"):
# node (upstream d3-interpolate in Node.js), aot (dart compile exe), jit (dart
# run), js (dart compile js -O4, run in Node.js) and wasm (dart compile wasm
# -O2, run in Node.js). Each target writes <out dir>/<target>.txt with the
# BENCH lines. DART is the dart command (default: the beta SDK of fvm at
# /Users/vasilich/fvm/versions/beta, the version of .fvmrc).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
pkg="$(cd "$here/../.." && pwd)"
out="$(mkdir -p "$1/build" && cd "$1" && pwd)"; shift
targets="node aot js wasm"
if [[ $# -gt 0 && "$1" != "--" ]]; then targets="$1"; shift; fi
[[ $# -gt 0 && "$1" == "--" ]] && shift
DART="${DART:-/Users/vasilich/fvm/versions/beta/bin/dart}"
mkdir -p "$out/build"
cd "$pkg"
for t in $targets; do
  case "$t" in
    node) node "$here/d3_interpolate_bench.mjs" --target=node "$@" > "$out/node.txt" ;;
    aot)
      "$DART" compile exe -o "$out/build/bench.exe" "$here/d3_interpolate_bench.dart" > /dev/null
      "$out/build/bench.exe" --target=aot "$@" > "$out/aot.txt" ;;
    jit) "$DART" run "$here/d3_interpolate_bench.dart" --target=jit "$@" > "$out/jit.txt" ;;
    js)
      "$DART" compile js -O4 -o "$out/build/bench.js" "$here/d3_interpolate_bench.dart" > /dev/null
      # dart2js gives main no arguments in Node.js: dartMainRunner passes them.
      node -e "
        globalThis.self = globalThis;
        // dart2js reads window.performance for a timer in microseconds, else
        // Date.now() in whole milliseconds.
        globalThis.window = globalThis;
        globalThis.dartMainRunner = (main) => main(process.argv.slice(1));
        require('$out/build/bench.js');
      " -- --target=js "$@" > "$out/js.txt" ;;
    wasm)
      "$DART" compile wasm -O2 -o "$out/build/bench.wasm" "$here/d3_interpolate_bench.dart" > /dev/null
      node --input-type=module -e "
        import * as m from '$out/build/bench.mjs';
        import {readFileSync} from 'node:fs';
        const app = await (await m.compile(readFileSync('$out/build/bench.wasm'))).instantiate({});
        app.invokeMain(...process.argv.slice(1));
      " -- --target=wasm "$@" > "$out/wasm.txt" ;;
    *) echo "unknown target $t" >&2; exit 2 ;;
  esac
  echo "$t: $(grep -c '^BENCH' "$out/$t.txt") cases"
done
