#!/usr/bin/env bash
# Fails unless the third_party/Chart.js gitlink is the commit of the upstream
# release tag named by chartJsVersion (packages/flutter_chartjs/lib/src/upstream.dart).
# Also fails unless the D3 gitlinks are the commits of their tags (ADR 0005 item 4,
# D3 ADR 0001):
# - third_party/d3: the release tag named by d3Version
#   (packages/flutter_d3_port/lib/src/upstream.dart).
# - Each other D3 submodule: the tag "ref" of its entry in
#   packages/flutter_d3_port/tool/port_sources.yaml. The gitlink must also
#   equal the "commit" of the entry.
# - Each submodule of .gitmodules: the pin of an entry of
#   packages/flutter_chartjs/tool/port_sources.yaml or of the D3 file.
# Reads the gitlinks from the index. Thus it needs no submodule checkout. It
# also works before the first commit. It gets the commit of each tag with
# git ls-remote.
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

# D3. The script examines every D3 pin and reports each failure. Then it exits
# with status 1 if one or more pins failed.
d3_upstream=packages/flutter_d3_port/lib/src/upstream.dart
d3_sources=packages/flutter_d3_port/tool/port_sources.yaml
d3_version=$(sed -n "s/^const String d3Version = '\(.*\)';\$/\1/p" "$d3_upstream")
if [ -z "$d3_version" ]; then
  echo "d3Version not found in $d3_upstream" >&2
  exit 1
fi
if [ ! -f "$d3_sources" ]; then
  echo "$d3_sources not found" >&2
  exit 1
fi

# The commit of tag <tag> in the repository <url>. Empty if the tag does not
# exist. Status 1 if git ls-remote fails.
d3_tag_commit() {
  local refs commit
  refs=$(git ls-remote "$1" "refs/tags/$2" "refs/tags/$2^{}" </dev/null) || return 1
  # An annotated tag lists its commit as refs/tags/<tag>^{}. A lightweight tag
  # points at the commit directly.
  commit=$(awk -v ref="refs/tags/$2^{}" '$2 == ref { print $1 }' <<<"$refs")
  if [ -z "$commit" ]; then
    commit=$(awk -v ref="refs/tags/$2" '$2 == ref { print $1 }' <<<"$refs")
  fi
  echo "$commit"
}

d3_failed=0
# Compares the gitlink of <path> with the commit of tag <tag> and with the
# commit <recorded> of port_sources.yaml. Sets d3_failed to 1 on a mismatch.
d3_check_pin() {
  local path=$1 tag=$2 recorded=$3 pinned url expected
  pinned=$(git ls-files --stage -- "$path" | awk '$1 == "160000" { print $2 }')
  if [ -z "$pinned" ]; then
    echo "$path is not recorded as a submodule" >&2
    d3_failed=1
    return
  fi
  if ! url=$(git config -f .gitmodules "submodule.$path.url"); then
    echo "$path has no url in .gitmodules" >&2
    d3_failed=1
    return
  fi
  if ! expected=$(d3_tag_commit "$url" "$tag"); then
    echo "git ls-remote failed for $url" >&2
    d3_failed=1
    return
  fi
  if [ -z "$expected" ]; then
    echo "Tag $tag not found in $url" >&2
    d3_failed=1
    return
  fi
  if [ "$pinned" != "$expected" ]; then
    echo "$path is pinned to $pinned, but $tag is $expected." >&2
    echo "Check out the tag in the submodule and stage it: git add $path" >&2
    d3_failed=1
    return
  fi
  if [ "$recorded" != "$pinned" ]; then
    echo "$d3_sources gives commit $recorded for $path, but the gitlink is $pinned." >&2
    d3_failed=1
    return
  fi
  echo "$path is pinned to $tag ($pinned)"
}

# One line "<path> <ref> <commit>" for each pin block of port_sources.yaml.
d3_pins=$(awk '
  $1 == "pin:" { path = ""; ref = ""; next }
  $1 == "path:" { path = $2 }
  $1 == "ref:" { ref = $2; gsub(/"/, "", ref) }
  $1 == "commit:" { print path, ref, $2 }
' "$d3_sources")
if [ -z "$d3_pins" ]; then
  echo "$d3_sources has no submodule pin" >&2
  exit 1
fi

d3_seen=0
while read -r path ref commit <&3; do
  if [ "$path" = third_party/d3 ]; then
    d3_seen=1
    if [ "$ref" != "v$d3_version" ]; then
      echo "$d3_sources gives ref $ref for third_party/d3, but d3Version is $d3_version." >&2
      d3_failed=1
    fi
    d3_check_pin "$path" "v$d3_version" "$commit"
  else
    d3_check_pin "$path" "$ref" "$commit"
  fi
done 3<<<"$d3_pins"
if [ "$d3_seen" = 0 ]; then
  echo "$d3_sources has no entry for third_party/d3" >&2
  d3_failed=1
fi

# The loop above examines only the D3 entries. This loop finds a submodule
# without an entry. The Chart.js file lists the Chart.js submodules.
chartjs_sources=packages/flutter_chartjs/tool/port_sources.yaml
listed=$(awk '$1 == "path:" { print $2 }' "$chartjs_sources" "$d3_sources")
while read -r _ path <&3; do
  if ! grep -qxF -- "$path" <<<"$listed"; then
    echo "$path is in .gitmodules, but no port_sources.yaml entry pins it." >&2
    d3_failed=1
  fi
done 3< <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$')
exit "$d3_failed"
