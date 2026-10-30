#!/usr/bin/env bash
# Original code, not ported from Chart.js: the text diff of the observation
# oracle O1 (Chart.js ADR 0054).
#
# Usage: tool/observation_diff.sh <base commit>
#
# Writes the canonical texts of test/port/options/observation_test.dart for
# the tree at <base> and for the current tree, one file for each test, and
# lists the files that differ. The base tree is a temporary detached git
# worktree under ${TMPDIR:-/tmp}; the script removes it at the end. The two
# text folders stay, for a diff by hand:
#   diff -u <base folder>/<test>.txt <head folder>/<test>.txt
# The test runs fail when a digest differs. The script ignores their exit
# codes: the texts are written before the comparison.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <base commit>" >&2
  exit 64
fi
base="$1"

package_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
repo_root="$(git -C "$package_dir" rev-parse --show-toplevel)"
package_path="${package_dir#"$repo_root"/}"
test_file="test/port/options/observation_test.dart"

out="$(mktemp -d "${TMPDIR:-/tmp}/observation_diff.XXXXXX")"
worktree="$out/tree"

cleanup() {
  git -C "$repo_root" worktree remove --force "$worktree" >/dev/null 2>&1 ||
    true
}
trap cleanup EXIT

git -C "$repo_root" worktree add --detach "$worktree" "$base"
(cd "$worktree" && flutter pub get)

(cd "$worktree/$package_path" &&
  O1_DUMP="$out/base" flutter test "$test_file") || true
(cd "$package_dir" && O1_DUMP="$out/head" flutter test "$test_file") || true

echo "base texts: $out/base"
echo "head texts: $out/head"
diff -rq "$out/base" "$out/head" || true
