// Original code, not ported from Apache ECharts: the pinned upstream version.
/// The Apache ECharts release that this port tracks.
///
/// The git submodule `third_party/echarts` pins the upstream repository at
/// tag `6.1.0`. The submodule `third_party/zrender` pins the renderer at the
/// version [zrenderVersion] that the ECharts `package.json` requires.
/// Change this value and the `third_party/echarts` submodule together.
const String echartsVersion = '6.1.0';

/// The zrender release that [echartsVersion] requires.
///
/// The ECharts 6.1.0 `package.json` gives the exact version `6.1.0`. Change
/// this value and the `third_party/zrender` submodule together.
const String zrenderVersion = '6.1.0';
