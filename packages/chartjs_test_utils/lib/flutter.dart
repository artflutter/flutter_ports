// Original code, not ported from Chart.js: the flutter test harness.

/// The part of the harness that needs the Flutter engine: it runs in
/// `flutter test` only (porting-flow.md section 3).
///
/// - The test font: `packages/flutter_chartjs_port/test/flutter_test_config.dart`
///   calls `installTestFont` before each test file.
/// - The DOM stand-in of `src/dom.dart` (Chart.js ADR 0022): `document`,
///   `window`, `setTimeout`, `afterEachChart`, `pumpFrames`, `pumpFrame`,
///   `waitForDone`, `frameInterval`, `specTimeout`, the element classes,
///   `HarnessBox` and the extensions `CanvasParentElement` and
///   `HarnessCanvasDisplay` (Chart.js ADR 0200).
/// - The chart helpers of chartjs-test-utils `src/index.js` and
///   `src/utils.js` (Chart.js ADR 0022, sections 4 to 6): `acquireChart`,
///   `releaseChart` and `releaseCharts`, which need the chart host;
///   `afterEvent` and `waitForResize`, which replace a function field of a
///   chart; and `triggerMouseEvent`, which pumps frames. `acquireChart`
///   works only in the body of a `testWidgets` test.
/// - The fixture smoke runner of chartjs-test-utils `src/fixture.js`
///   (Chart.js ADR 0029): `specsFromFixtures`, `specFromFixture`,
///   `FixtureSource`, `FixtureItem`, `FixtureInputs`, `FixtureLoad`,
///   `HandFixture`, `fixturesTag`, `fixturesRequiredVariable`,
///   `noSubmoduleReason` and `sha256Hex` (the SHA-256 of the check of the
///   upstream files, also for the observation oracle O1 of
///   flutter_chartjs_port).
///
/// The library exports each file of `lib/src/` that needs the Flutter
/// engine, and `src/native_colors.dart` and `src/native_easing.dart` (ADR
/// 0011). `src/utils.dart` has its own `acquireChart` and `releaseChart`,
/// the ports of `_acquireChart` and `_releaseChart`: the library hides them
/// and exports those of `src/index.dart` (Chart.js ADR 0012, Collisions).
///
/// The pure part of the harness is `package:chartjs_test_utils/pure.dart`.
/// This library is not a pure layer: a test that imports it needs
/// `@TestOn('vm')`.
library;

export 'package:chartjs_test_utils/src/dom.dart';
export 'package:chartjs_test_utils/src/fixture.dart';
export 'package:chartjs_test_utils/src/fonts.dart';
export 'package:chartjs_test_utils/src/index.dart';
export 'package:chartjs_test_utils/src/native_colors.dart';
export 'package:chartjs_test_utils/src/native_easing.dart';
export 'package:chartjs_test_utils/src/raw_options.dart';
export 'package:chartjs_test_utils/src/utils.dart'
    hide acquireChart, releaseChart;
