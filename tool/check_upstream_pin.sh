#!/usr/bin/env bash
# Fails unless the third_party/Chart.js gitlink is the commit of the upstream
# release tag named by chartJsVersion (packages/flutter_chartjs_port/lib/src/upstream.dart).
# A commit pin (ADR 0006 item 5, packages/flutter_chartjs_port/doc/upstream-tracking.md
# section 2.4) has the version "<last version>+<sha8>". Then the gitlink must
# start with <sha8>, and the tag "v<last version>" must exist.
# Also fails unless the D3 gitlinks are the commits of their tags (ADR 0005 item 4,
# D3 ADR 0001):
# - third_party/d3: the release tag named by d3Version
#   (packages/flutter_d3_port/lib/src/upstream.dart).
# - Each other D3 submodule: the tag "ref" of its entry in
#   packages/flutter_d3_port/tool/port_sources.yaml. The gitlink must also
#   equal the "commit" of the entry.
# Also fails unless the ECharts gitlinks are the commits of their tags (ECharts
# ADR 0001):
# - third_party/echarts: the release tag named by echartsVersion
#   (packages/flutter_echarts_port/lib/src/upstream.dart). The ECharts tags
#   have no "v" prefix.
# - third_party/zrender: the release tag named by zrenderVersion.
# - The gitlinks must also equal the "commit" of their entries in
#   packages/flutter_echarts_port/tool/port_sources.yaml.
# Also fails unless the third_party/chartjs-plugin-zoom gitlink is the commit
# of chartjsPluginZoomVersion
# (packages/flutter_chartjs_plugin_zoom_port/lib/src/upstream.dart, Zoom ADR
# 0001). A commit pin "<last version>+<sha8>" needs a gitlink that starts
# with <sha8> and the tag "v<last version>". The gitlink must also equal the
# "commit" of the entry in
# packages/flutter_chartjs_plugin_zoom_port/tool/port_sources.yaml.
# Also fails on a submodule of .gitmodules that no entry of a
# packages/*/tool/port_sources.yaml file pins.
# Reads the gitlinks from the index. Thus it needs no submodule checkout. It
# also works before the first commit. It gets the commit of each tag with
# git ls-remote.
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(sed -n "s/^const String chartJsVersion = '\(.*\)';\$/\1/p" \
  packages/flutter_chartjs_port/lib/src/upstream.dart)
if [ -z "$version" ]; then
  echo "chartJsVersion not found in packages/flutter_chartjs_port/lib/src/upstream.dart" >&2
  exit 1
fi
# A commit pin: the release before "+" and the abbreviated commit after it.
release=${version%%+*}
commit=
if [ "$release" != "$version" ]; then
  commit=${version#*+}
  if ! [[ $release =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && $commit =~ ^[0-9a-f]{8}$ ]]; then
    echo "chartJsVersion $version is not <version> or <version>+<sha8>" >&2
    exit 1
  fi
fi
tag="v$release"

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

if [ -n "$commit" ]; then
  # git ls-remote lists only refs. Thus the script cannot see if the commit is
  # on master after the tag. The upstream ledger records the commits of the
  # range.
  if [[ $pinned != "$commit"* ]]; then
    echo "third_party/Chart.js is pinned to $pinned, but chartJsVersion $version names the commit $commit." >&2
    echo "Check out the commit in the submodule and stage it: git add third_party/Chart.js" >&2
    exit 1
  fi
  if [ "$pinned" = "$expected" ]; then
    echo "third_party/Chart.js is pinned to $tag ($pinned). Write chartJsVersion $release, not $version." >&2
    exit 1
  fi
  echo "third_party/Chart.js is pinned to the commit pin v$version ($pinned, after $tag)"
else
  if [ "$pinned" != "$expected" ]; then
    echo "third_party/Chart.js is pinned to $pinned, but $tag is $expected." >&2
    echo "Check out the tag in the submodule and stage it: git add third_party/Chart.js" >&2
    exit 1
  fi
  echo "third_party/Chart.js is pinned to $tag ($pinned)"
fi

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
tag_commit() {
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

failed=0
# Compares the gitlink of <path> with the commit of tag <tag> and with the
# commit <recorded> of the port_sources.yaml file <sources>. Sets failed to 1
# on a mismatch.
check_pin() {
  local path=$1 tag=$2 recorded=$3 sources=$4 pinned url expected
  pinned=$(git ls-files --stage -- "$path" | awk '$1 == "160000" { print $2 }')
  if [ -z "$pinned" ]; then
    echo "$path is not recorded as a submodule" >&2
    failed=1
    return
  fi
  if ! url=$(git config -f .gitmodules "submodule.$path.url"); then
    echo "$path has no url in .gitmodules" >&2
    failed=1
    return
  fi
  if ! expected=$(tag_commit "$url" "$tag"); then
    echo "git ls-remote failed for $url" >&2
    failed=1
    return
  fi
  if [ -z "$expected" ]; then
    echo "Tag $tag not found in $url" >&2
    failed=1
    return
  fi
  if [ "$pinned" != "$expected" ]; then
    echo "$path is pinned to $pinned, but $tag is $expected." >&2
    echo "Check out the tag in the submodule and stage it: git add $path" >&2
    failed=1
    return
  fi
  if [ "$recorded" != "$pinned" ]; then
    echo "$sources gives commit $recorded for $path, but the gitlink is $pinned." >&2
    failed=1
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
      failed=1
    fi
    check_pin "$path" "v$d3_version" "$commit" "$d3_sources"
  else
    check_pin "$path" "$ref" "$commit" "$d3_sources"
  fi
done 3<<<"$d3_pins"
if [ "$d3_seen" = 0 ]; then
  echo "$d3_sources has no entry for third_party/d3" >&2
  failed=1
fi

# ECharts. The script examines both ECharts pins and reports each failure.
echarts_upstream=packages/flutter_echarts_port/lib/src/upstream.dart
echarts_sources=packages/flutter_echarts_port/tool/port_sources.yaml
echarts_version=$(sed -n "s/^const String echartsVersion = '\(.*\)';\$/\1/p" "$echarts_upstream")
zrender_version=$(sed -n "s/^const String zrenderVersion = '\(.*\)';\$/\1/p" "$echarts_upstream")
if [ -z "$echarts_version" ] || [ -z "$zrender_version" ]; then
  echo "echartsVersion or zrenderVersion not found in $echarts_upstream" >&2
  exit 1
fi
if [ ! -f "$echarts_sources" ]; then
  echo "$echarts_sources not found" >&2
  exit 1
fi

# One line "<path> <ref> <commit>" for each pin block of a port_sources.yaml.
read_pins() {
  awk '
    $1 == "pin:" { path = ""; ref = ""; next }
    $1 == "path:" { path = $2 }
    $1 == "ref:" { ref = $2; gsub(/"/, "", ref) }
    $1 == "commit:" { print path, ref, $2 }
  ' "$1"
}

echarts_seen=0
zrender_seen=0
while read -r path ref commit <&3; do
  case "$path" in
    third_party/echarts)
      echarts_seen=1
      expected_ref=$echarts_version
      ;;
    third_party/zrender)
      zrender_seen=1
      expected_ref=$zrender_version
      ;;
    *)
      expected_ref=$ref
      ;;
  esac
  if [ "$ref" != "$expected_ref" ]; then
    echo "$echarts_sources gives ref $ref for $path, but $echarts_upstream gives $expected_ref." >&2
    failed=1
  fi
  check_pin "$path" "$expected_ref" "$commit" "$echarts_sources"
done 3< <(read_pins "$echarts_sources")
if [ "$echarts_seen" = 0 ] || [ "$zrender_seen" = 0 ]; then
  echo "$echarts_sources needs an entry for third_party/echarts and for third_party/zrender" >&2
  failed=1
fi

# chartjs-plugin-zoom (Zoom ADR 0001). A commit pin "<last version>+<sha8>":
# the gitlink starts with <sha8>, is not the commit of the tag
# "v<last version>", and that tag exists. A release pin: the gitlink is the
# commit of the tag "v<version>". In both cases the gitlink is the "commit"
# of the entry.
zoom_upstream=packages/flutter_chartjs_plugin_zoom_port/lib/src/upstream.dart
zoom_sources=packages/flutter_chartjs_plugin_zoom_port/tool/port_sources.yaml
zoom_path=third_party/chartjs-plugin-zoom
zoom_version=$(sed -n "s/^const String chartjsPluginZoomVersion = '\(.*\)';\$/\1/p" "$zoom_upstream")
if [ -z "$zoom_version" ]; then
  echo "chartjsPluginZoomVersion not found in $zoom_upstream" >&2
  exit 1
fi
if [ ! -f "$zoom_sources" ]; then
  echo "$zoom_sources not found" >&2
  exit 1
fi
zoom_release=${zoom_version%%+*}
zoom_commit=
if [ "$zoom_release" != "$zoom_version" ]; then
  zoom_commit=${zoom_version#*+}
fi
if ! [[ $zoom_release =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  { [ -n "$zoom_commit" ] && ! [[ $zoom_commit =~ ^[0-9a-f]{8}$ ]]; }; then
  echo "chartjsPluginZoomVersion $zoom_version is not <version> or <version>+<sha8>" >&2
  exit 1
fi
zoom_seen=0
while read -r path ref recorded <&3; do
  if [ "$path" != "$zoom_path" ]; then
    echo "$zoom_sources pins $path. It must pin only $zoom_path." >&2
    failed=1
    continue
  fi
  zoom_seen=1
  if [ -z "$zoom_commit" ]; then
    if [ "$ref" != "v$zoom_version" ]; then
      echo "$zoom_sources gives ref $ref for $path, but chartjsPluginZoomVersion is $zoom_version." >&2
      failed=1
    fi
    check_pin "$path" "v$zoom_version" "$recorded" "$zoom_sources"
    continue
  fi
  pinned=$(git ls-files --stage -- "$path" | awk '$1 == "160000" { print $2 }')
  if [ -z "$pinned" ]; then
    echo "$path is not recorded as a submodule" >&2
    failed=1
    continue
  fi
  if [[ $pinned != "$zoom_commit"* ]]; then
    echo "$path is pinned to $pinned, but chartjsPluginZoomVersion $zoom_version names the commit $zoom_commit." >&2
    echo "Check out the commit in the submodule and stage it: git add $path" >&2
    failed=1
    continue
  fi
  if [ "$ref" != "$recorded" ] || [ "$recorded" != "$pinned" ]; then
    echo "$zoom_sources gives ref $ref and commit $recorded for $path, but the gitlink is $pinned. A commit pin names the full gitlink in both." >&2
    failed=1
    continue
  fi
  if ! url=$(git config -f .gitmodules "submodule.$path.url"); then
    echo "$path has no url in .gitmodules" >&2
    failed=1
    continue
  fi
  if ! expected=$(tag_commit "$url" "v$zoom_release"); then
    echo "git ls-remote failed for $url" >&2
    failed=1
    continue
  fi
  if [ -z "$expected" ]; then
    echo "Tag v$zoom_release not found in $url" >&2
    failed=1
    continue
  fi
  if [ "$pinned" = "$expected" ]; then
    echo "$path is pinned to v$zoom_release ($pinned). Write chartjsPluginZoomVersion $zoom_release, not $zoom_version." >&2
    failed=1
    continue
  fi
  echo "$path is pinned to the commit pin v$zoom_version ($pinned, after v$zoom_release)"
done 3< <(read_pins "$zoom_sources")
if [ "$zoom_seen" = 0 ]; then
  echo "$zoom_sources has no entry for $zoom_path" >&2
  failed=1
fi

# The loops above examine the D3, ECharts and zoom entries. This loop finds a
# submodule without an entry. Each port lists its submodules in its own
# tool/port_sources.yaml. The Chart.js file lists the Chart.js submodules.
listed=$(awk '$1 == "path:" { print $2 }' packages/*/tool/port_sources.yaml)
while read -r _ path <&3; do
  if ! grep -qxF -- "$path" <<<"$listed"; then
    echo "$path is in .gitmodules, but no port_sources.yaml entry pins it." >&2
    failed=1
  fi
done 3< <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$')
exit "$failed"
