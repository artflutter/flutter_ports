#!/usr/bin/env bash
# Writes the archive of the docs samples that the "Try in DartPad" links open
# (lib/ui/dartpad.dart). The archive has two folders:
#   chartjs_docs/          the samples (lib/examples) and their DartPad apps
#                          (lib/dartpad), with a pubspec of their own;
#   flutter_chartjs_port/  the lib of the port, with its pubspec.
# The port is not on pub.dev yet, so the samples name it with a path
# dependency. DartPad accepts a path dependency only to a package of the same
# archive. It resolves the other packages from pub.dev.
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
port="$(cd "$docs/../../packages/flutter_chartjs_port" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/chartjs_docs/lib" "$work/flutter_chartjs_port"
cp -R "$docs/lib/examples" "$docs/lib/dartpad" "$work/chartjs_docs/lib/"
cp "$docs/LICENSE" "$work/chartjs_docs/"
cat > "$work/chartjs_docs/pubspec.yaml" <<'YAML'
name: chartjs_docs
description: The samples of the docs of flutter_chartjs_port, for DartPad.
publish_to: none

environment:
  sdk: ^3.13.0
  flutter: ">=3.47.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_chartjs_port:
    path: ../flutter_chartjs_port
  material_ui: ^1.10.0
YAML

cp -R "$port/lib" "$port/LICENSE" "$work/flutter_chartjs_port/"
# The port alone: no workspace and no dev dependencies.
awk '
  /^resolution: workspace$/ { next }
  /^dev_dependencies:/ { skip = 1; next }
  /^[^ #]/ { skip = 0 }
  !skip
' "$port/pubspec.yaml" > "$work/flutter_chartjs_port/pubspec.yaml"

# COPYFILE_DISABLE keeps the macOS tar from adding ._ files.
COPYFILE_DISABLE=1 tar -czf "$out" -C "$work" chartjs_docs flutter_chartjs_port
echo "Wrote $out ($(wc -c < "$out" | tr -d ' ') bytes)."
