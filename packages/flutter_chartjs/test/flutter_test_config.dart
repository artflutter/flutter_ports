// Ported from Chart.js v4.5.1 test/index.js (MIT, Chart.js Contributors).

/// Port of `test/index.js`, the set-up of the Chart.js specs
/// (porting-flow.md section 3, "`test/index.js` equivalent").
///
/// `flutter test` runs [testExecutable] around the `main()` of each test
/// file in this package. `dart test` does not read this file. Thus each
/// pure-layer spec also calls `setUpSpecs()` of
/// `package:chartjs_test_utils/pure.dart`, which runs the same restore
/// (`harness-defaults-restore`) on the VM, dart2js and dart2wasm. Under
/// `flutter test`, such a file restores the scopes twice after each test.
/// Both restores put back the same snapshot: the second one finds nothing
/// to change.
///
/// The harness installs no theme (Chart.js ADR 0001).
library;

import 'dart:async';
import 'dart:ui';

// index.js:1 imports the helpers of chartjs-test-utils. The specs import
// them from the harness: `createMockContext` and the matchers from
// package:chartjs_test_utils/pure.dart. `acquireChart`, `releaseChart`,
// `afterEvent`, `waitForResize` and `triggerMouseEvent` come in phase 5
// (package:chartjs_test_utils/flutter.dart). `specsFromFixtures` comes in
// phase 7.
import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `devicePixelRatio` of the test view (index.js:3-5).
const double _devicePixelRatio = 1;

/// The logical size of the test view: the flutter_test default (2400 x 1800
/// physical pixels at a ratio of 3).
const Size _logicalSize = Size(800, 600);

/// The set-up of each test file in this package.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // force ratio=1 for tests on high-res/retina devices
  // fixes https://github.com/chartjs/Chart.js/issues/4515
  //
  // The flutter_test view has a ratio of 3. `tester.view.reset()` in a test
  // puts back 3, not 1. Thus a `setUp` sets the ratio before each test, as
  // upstream specs that change `window.devicePixelRatio` restore it to 1.
  final view = binding.platformDispatcher.implicitView!;
  void forceRatio() {
    if (view.devicePixelRatio != _devicePixelRatio) {
      view.devicePixelRatio = _devicePixelRatio;
    }
    final physicalSize = _logicalSize * _devicePixelRatio;
    if (view.physicalSize != physicalSize) view.physicalSize = physicalSize;
  }

  forceRatio();
  setUp(forceRatio);

  // index.js:7-11 put the helpers on `window`. Dart has no globals: the
  // specs import them (see the imports above).

  // index.js:13 `injectWrapperCSS()`: n/a. Flutter has no CSS. The chart
  // host has no border, margin or padding.

  // index.js:15-19 `jasmine.fixture` (phase 7) and
  // `jasmine.triggerMouseEvent` (phase 5): the specs import them.

  // Set a fixed time zone (and, in particular, disable Daylight Saving Time)
  // for more stable test results.
  //
  // index.js:23 `window.moment.tz.setDefault('Etc/UTC')`: Dart cannot set the
  // zone of `DateTime` in a running isolate. The specs use the default date
  // adapter in UTC (porting-flow.md 2.10, phase 6), so no spec depends on the
  // zone of the machine.

  // index.js:25-28: Disable colors plugin for tests.
  // `Chart.defaults.plugins.colors.enabled = false` waits for the colors
  // plugin (phase 8). It must run here, before the snapshot of the restore
  // below, so that the restore keeps it.

  // DIVERGES(chartjs): harness-defaults-restore, restore defaults after tests.
  setUpDefaultsRestore();

  // index.js:30-32 `addMatchers()`: n/a. The matchers are functions of
  // package:chartjs_test_utils/pure.dart that a spec imports.

  // index.js:34-36 `releaseCharts()` after each test: phase 5, with
  // `acquireChart`.

  // DIVERGES(chartjs): harness-test-font, Liberation Sans for Arial/Helvetica.
  await installTestFont();

  await testMain();
}
