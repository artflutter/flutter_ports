// Ported from Chart.js v4.5.1+7169e651 test/index.js (MIT, Chart.js Contributors).

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
/// Before the snapshot of the restore, the file registers the built-in
/// components, as the UMD entry of the specs does
/// (`harness-register-builtins`). A file that calls `setUpSpecs()` or
/// `removeBuiltins()` removes them again. The unmount of the harness body
/// releases the charts of `acquireChart`, with a `tearDown` as the fallback
/// (`harness-release-at-unmount`, Chart.js ADR 0022, section 8). A
/// pure-layer spec under `dart test` has neither of them.
///
/// The harness installs no theme (Chart.js ADR 0001).
library;

import 'dart:async';
import 'dart:ui';

// index.js:1 imports the helpers of chartjs-test-utils. The specs import
// them from the harness: `createMockContext` and the matchers from
// package:chartjs_test_utils/pure.dart, and `acquireChart`, `releaseChart`,
// `afterEvent`, `waitForResize` and `triggerMouseEvent` from
// package:chartjs_test_utils/flutter.dart. `specsFromFixtures` comes in
// phase 7.
import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/date_adapter.dart'
    show setDefaultDateZone;
// The specs run on the UMD entry of Chart.js, which registers the built-in
// components. flutter_chartjs does not export lib/src/index.dart yet.
import 'package:flutter_chartjs/src/index.dart'
    show Chart, controllers, elements, plugins, scales;
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

  // index.js:15-17 `jasmine.fixture` is `specs` of `test/fixtures/index.dart`,
  // which the spec files import with the prefix `fixture` (Chart.js ADR
  // 0029). index.js:19 `jasmine.triggerMouseEvent` (phase 5): the specs
  // import it.

  // Set a fixed time zone (and, in particular, disable Daylight Saving Time)
  // for more stable test results.
  //
  // index.js:23 `window.moment.tz.setDefault('Etc/UTC')`: the default zone of
  // the default date adapter (Chart.js ADR 0024, decision 3).
  setDefaultDateZone('Etc/UTC');

  // The specs run on the UMD entry `src/index.umd.ts` (karma.conf.cjs:110).
  // It registers the built-in components before the first spec:
  // index.umd.ts:28 `Chart.register(controllers, scales, elements,
  // plugins)`. The call runs before `main()` of the test file and before the
  // snapshot of the restore below. Thus the restore keeps the defaults of the
  // ported components. In phase 6, only `elements` and `scales` have entries
  // (Chart.js ADR 0022, section 8). A pure-layer file removes them again in
  // `setUpSpecs()`, because `dart test` does not run this file.
  // DIVERGES(chartjs): harness-register-builtins, src/index.umd.ts:28.
  setUpBuiltins(
    () => Chart.register([controllers, scales, elements, plugins]),
    () => Chart.unregister([controllers, scales, elements, plugins]),
  );

  // index.js:25-28: Disable colors plugin for tests.
  // `Chart.defaults.plugins.colors.enabled = false` waits for the colors
  // plugin (phase 8). It must run here, before the snapshot of the restore
  // below, so that the restore keeps it.

  // DIVERGES(chartjs): harness-defaults-restore, restore defaults after tests.
  setUpDefaultsRestore();

  // index.js:30-32 `addMatchers()`: n/a. The matchers are functions of
  // package:chartjs_test_utils/pure.dart that a spec imports.

  // index.js:34-36 afterEach(function() { releaseCharts(); });
  //
  // The unmount of the harness body calls `releaseCharts`. flutter_test
  // disposes the body in the warm-up frame of its `runApp` after the test
  // body. Thus the release runs before the end-of-test checks of
  // flutter_test and before the `tearDown` functions. Jasmine runs the
  // global `afterEach` last, after the `afterEach` blocks of the spec. The
  // inline local afterEach functions of Chart.js ADR 0022, section 2, keep
  // that order. A spec afterEach that stays a `tearDown` runs after the
  // release, the reverse of Jasmine. That is safe while such a block reads
  // no chart, as the device pixel ratio restore of
  // core.controller.tests.js:1392-1394 does not.
  // The `tearDown` is the fallback: after a failed test, flutter_test keeps
  // the tree. It runs before the restore of `harness-defaults-restore`,
  // because `tearDown` functions run in the reverse order (Chart.js ADR
  // 0022, section 8).
  // DIVERGES(chartjs): harness-release-at-unmount, release before checks.
  afterEachChart(releaseCharts);
  tearDown(releaseCharts);

  // DIVERGES(chartjs): harness-test-font, Liberation Sans for Arial/Helvetica.
  await installTestFont();

  await testMain();
}
