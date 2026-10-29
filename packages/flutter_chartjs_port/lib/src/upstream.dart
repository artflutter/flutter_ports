// Original code, not ported from Chart.js: the pinned upstream version.
/// The Chart.js version this port tracks.
///
/// For a release tag, the value is `<version>`. For a commit pin, it is
/// `<last version>+<sha8>` (§2.4 of `doc/upstream-tracking.md` in the
/// repository). The upstream
/// sources are pinned as a git submodule at `third_party/Chart.js` (the tag
/// `v4.6.1`). Bump both together.
/// The pin checks of the repository read this line.
const String chartJsVersion = '4.6.1';

/// The `version` of the Chart.js `package.json` at the pin: the part of
/// [chartJsVersion] before `+`.
///
/// Upstream `Chart.version` is this value (`core.controller.js:12`). A
/// commit pin does not change it.
const String chartJsPackageVersion = '4.6.1';
