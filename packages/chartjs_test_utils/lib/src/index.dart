// Ported from chartjs-test-utils v0.4.0 src/index.js (MIT, chartjs-test-utils Contributors).

/// Port of `src/index.js`, the entry point of chartjs-test-utils.
///
/// Phase 3 ports [createMockContext] (index.js:33). The other members wait,
/// or have no counterpart (porting-flow.md section 3):
/// - `acquireChart` (index.js:22), `releaseChart` (index.js:28),
///   `releaseCharts` (index.js:54) and the `charts` registry (index.js:9),
///   and the re-exports `afterEvent`, `waitForResize` and
///   `triggerMouseEvent` of `src/utils.js` (index.js:6): phase 5. They need
///   the chart and its host, and they pump frames. Thus they go in
///   `package:chartjs_test_utils/flutter.dart`, not in the pure layer.
/// - The re-export of `src/fixture.js` (index.js:5), `specsFromFixtures`:
///   phase 7, as a smoke runner.
/// - `injectWrapperCSS` (index.js:37): `n/a`. Flutter has no CSS. The chart
///   host has no border, margin or padding.
/// - `addMatchers` (index.js:50): `n/a`. A matcher is a function that
///   returns a `Matcher` (`matchers.dart`). A spec imports it.
///
/// This library is a pure layer.
library;

import 'package:chartjs_test_utils/src/context.dart';

/// index.js:33 `createMockContext`: a new [MockContext].
MockContext createMockContext() {
  return MockContext();
}
