#!/usr/bin/env bash
# Writes one archive for each docs sample that the "Try in DartPad" links open
# (lib/ui/dartpad.dart): each file of lib/examples with a main function.
# lib/examples/<path>.dart becomes <out_dir>/<path>.tar.gz with two files:
#   lib/main.dart  the sample, without its region markers and with only the
#                  first line of its header;
#   pubspec.yaml   flutter_chartjs_port from pub.dev, at the version of
#                  packages/flutter_chartjs_port/pubspec.yaml or later.
# A sample with a main function is one file: it imports no other file of the
# docs app.
#
# Usage: apps/chartjs_docs/tool/dartpad_archives.sh <out_dir>
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <out_dir>" >&2
  exit 2
fi
mkdir -p "$1"
out="$(cd "$1" && pwd)"
docs="$(cd "$(dirname "$0")/.." && pwd)"
version="$(sed -n 's/^version: //p' "$docs/../../packages/flutter_chartjs_port/pubspec.yaml")"
if [ -z "$version" ]; then
  echo "no version in packages/flutter_chartjs_port/pubspec.yaml" >&2
  exit 1
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

count=0
while IFS= read -r sample; do
  rel="${sample#"$docs/lib/examples/"}"
  rel="${rel%.dart}"
  if grep -q "package:chartjs_docs/" "$sample"; then
    echo "lib/examples/$rel.dart imports another file of the docs app" >&2
    exit 1
  fi
  project="$work/$rel"
  mkdir -p "$project/lib" "$(dirname "$out/$rel")"
  # Line 1 (the source and its license), then the code without the other
  # header comments and without the region markers.
  awk '
    NR == 1 { print; next }
    head && /^\/\// { next }
    { head = 0 }
    /^[[:space:]]*\/\/ #(end)?docregion / { next }
    { print }
  ' head=1 "$sample" > "$project/lib/main.dart"
  cat > "$project/pubspec.yaml" <<YAML
name: chartjs_sample
publish_to: none

environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_chartjs_port: ^$version
YAML
  # COPYFILE_DISABLE keeps the macOS tar from adding ._ files.
  COPYFILE_DISABLE=1 tar -czf "$out/$rel.tar.gz" -C "$project" pubspec.yaml lib/main.dart
  echo "Wrote $out/$rel.tar.gz"
  count=$((count + 1))
done < <(grep -rlE '^void main\(' "$docs/lib/examples" --include='*.dart' | sort)

if [ "$count" -eq 0 ]; then
  echo "no sample with a main function in lib/examples" >&2
  exit 1
fi
echo "$count archives, flutter_chartjs_port ^$version."
