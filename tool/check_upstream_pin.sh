#!/usr/bin/env bash
# Fails unless the third_party/Chart.js gitlink is the commit of the upstream
# release tag named by chartJsVersion (packages/flutter_chartjs/lib/src/upstream.dart).
# Reads the gitlink from the index, so it needs no submodule checkout and also
# works before the first commit.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n "s/^const String chartJsVersion = '\(.*\)';\$/\1/p" \
  packages/flutter_chartjs/lib/src/upstream.dart)
if [ -z "$version" ]; then
  echo "chartJsVersion not found in packages/flutter_chartjs/lib/src/upstream.dart" >&2
  exit 1
fi
tag="v$version"

pinned=$(git ls-files --stage -- third_party/Chart.js | awk '$1 == "160000" { print $2 }')
if [ -z "$pinned" ]; then
  echo "third_party/Chart.js is not recorded as a submodule" >&2
  exit 1
fi

url=$(git config -f .gitmodules submodule.third_party/Chart.js.url)
refs=$(git ls-remote "$url" "refs/tags/$tag" "refs/tags/$tag^{}")
# An annotated tag lists its commit as refs/tags/<tag>^{}; a lightweight tag
# points at the commit directly.
expected=$(awk -v ref="refs/tags/$tag^{}" '$2 == ref { print $1 }' <<<"$refs")
if [ -z "$expected" ]; then
  expected=$(awk -v ref="refs/tags/$tag" '$2 == ref { print $1 }' <<<"$refs")
fi
if [ -z "$expected" ]; then
  echo "Tag $tag not found in $url" >&2
  exit 1
fi

if [ "$pinned" != "$expected" ]; then
  echo "third_party/Chart.js is pinned to $pinned, but $tag is $expected." >&2
  echo "Check out the tag in the submodule and stage it: git add third_party/Chart.js" >&2
  exit 1
fi
echo "third_party/Chart.js is pinned to $tag ($pinned)"
