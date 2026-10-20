// Original code, not ported from Chart.js: the pinned upstream version.
/// The Chart.js version this port tracks.
///
/// For a release tag, the value is `<version>`. For a commit pin, it is
/// `<last version>+<sha8>` (`doc/upstream-tracking.md` §2.4). The upstream
/// sources are pinned as a git submodule at `third_party/Chart.js` (the
/// commit pin `7169e651`, after the tag `v4.5.1`). Bump both together.
/// `tool/check_upstream_pin.sh` and the header check read this line.
const String chartJsVersion = '4.5.1+7169e651';

/// The `version` of the Chart.js `package.json` at the pin: the part of
/// [chartJsVersion] before `+`.
///
/// Upstream `Chart.version` is this value (`core.controller.js:12`). A
/// commit pin does not change it: the `package.json` of the commit
/// `7169e651` gives the release `4.5.1`.
const String chartJsPackageVersion = '4.5.1';
