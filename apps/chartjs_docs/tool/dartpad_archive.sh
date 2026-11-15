#!/usr/bin/env bash
# Writes the archive of the docs samples that the "Try in DartPad" links open
# (lib/ui/dartpad.dart): the folder chartjs_docs with the samples
# (lib/examples), their DartPad apps (lib/dartpad) and a pubspec of their own.
# The pubspec names flutter_chartjs_port from pub.dev, at the version of
# packages/flutter_chartjs_port/pubspec.yaml or a later compatible one.
#
# Usage: apps/chartjs_docs/tool/dartpad_archive.sh <out.tar.gz>
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <out.tar.gz>" >&2
  exit 2
fi
mkdir -p "$(dirname "$1")"
out="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
docs="$(cd "$(dirname "$0")/.." && pwd)"
version="$(sed -n 's/^version: //p' "$docs/../../packages/flutter_chartjs_port/pubspec.yaml")"
if [ -z "$version" ]; then
  echo "no version in packages/flutter_chartjs_port/pubspec.yaml" >&2
  exit 1
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/chartjs_docs/lib"
cp -R "$docs/lib/examples" "$docs/lib/dartpad" "$work/chartjs_docs/lib/"
cp "$docs/LICENSE" "$work/chartjs_docs/"
cat > "$work/chartjs_docs/pubspec.yaml" <<YAML
name: chartjs_docs
description: The samples of the docs of flutter_chartjs_port, for DartPad.
publish_to: none

environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_chartjs_port: ^$version
  material_ui: ^1.10.0
YAML

# COPYFILE_DISABLE keeps the macOS tar from adding ._ files.
COPYFILE_DISABLE=1 tar -czf "$out" -C "$work" chartjs_docs
echo "Wrote $out ($(wc -c < "$out" | tr -d ' ') bytes, flutter_chartjs_port ^$version)."
