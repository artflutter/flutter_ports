// Original code, not ported from chartjs-plugin-zoom: the pinned version.
/// The chartjs-plugin-zoom version that this port tracks.
///
/// The git submodule `third_party/chartjs-plugin-zoom` pins the upstream
/// repository. The value is a commit pin, `<last version>+<sha8>`: the
/// pinned commit `fb81d331` of `master` comes after the release tag
/// `v2.2.0` (Zoom ADR 0001). Change this value and the submodule together.
const String chartjsPluginZoomVersion = '2.2.0+fb81d331';

/// The `version` of the upstream `package.json` at the pin: the part of
/// [chartjsPluginZoomVersion] before `+`. The upstream plugin object gives
/// this value as its `version`.
const String chartjsPluginZoomPackageVersion = '2.2.0';
