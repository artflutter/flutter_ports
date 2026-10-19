// Original code, not ported from Chart.js: the flutter test harness.

/// The part of the harness that needs the Flutter engine: it runs in
/// `flutter test` only (porting-flow.md section 3).
///
/// `packages/flutter_chartjs/test/flutter_test_config.dart` calls
/// `installTestFont` before each test file. Phase 5 adds the chart helpers
/// of chartjs-test-utils `src/utils.js` (`acquireChart`, `releaseChart`,
/// `afterEvent`, `waitForResize`, `triggerMouseEvent`) here, because they
/// pump frames.
///
/// The pure part of the harness is `package:chartjs_test_utils/pure.dart`.
/// This library is not a pure layer: a test that imports it needs
/// `@TestOn('vm')`.
library;

export 'src/fonts.dart' show installTestFont, testFontFamilies, testFontFiles;
