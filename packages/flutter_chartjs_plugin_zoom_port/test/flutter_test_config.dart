// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/index.js (MIT, chartjs-plugin-zoom contributors).

/// Port of `test/index.js`, the set-up of the zoom specs (Zoom ADR 0002,
/// item 4).
///
/// Flutter runs [testExecutable] around each test file of the package. The
/// file has the set-up of upstream in the form of the host set-up
/// (`packages/flutter_chartjs_port/test/flutter_test_config.dart`), with the
/// public libraries of the host and the harness only (Zoom ADR 0003, item
/// 1):
///
/// - the device pixel ratio 1 and the view of 800 x 600 before each test;
/// - the default date zone UTC (`harness-date-zone`);
/// - the built-in components of the UMD entry of Chart.js, registered before
///   `main()` of the test file (`harness-register-builtins`);
/// - the colors plugin off, and the restore of the global scopes after each
///   test (`harness-defaults-restore`);
/// - the release of the charts after each test;
/// - the test font of the host harness (`harness-test-font`).
///
/// The oracle O2 of the host (`foreignAudit`) is internal to the host: the
/// zoom tests run without it.
library;

import 'dart:async';
import 'dart:ui';

// index.js:1-8 imports the helpers of chartjs-test-utils. The specs import
// `acquireChart` and `releaseChart` from package:chartjs_test_utils/flutter.dart.
import 'package:chartjs_test_utils/flutter.dart'
    show afterEachChart, installTestFont, releaseCharts;
import 'package:chartjs_test_utils/pure.dart'
    show setUpBuiltins, setUpDefaultsRestore;
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        Chart,
        JsObjectFace,
        controllers,
        defaults,
        elements,
        plugins,
        scales,
        setDefaultDateZone;
import 'package:flutter_test/flutter_test.dart';

/// The `devicePixelRatio` of the test view (index.js:10-12).
const double _devicePixelRatio = 1;

/// The logical size of the test view: the flutter_test default (2400 x 1800
/// physical pixels at a ratio of 3).
const Size _logicalSize = Size(800, 600);

/// The set-up of each test file in this package.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // force ratio=1 for tests on high-res/retina devices
  // ref https://github.com/chartjs/Chart.js/issues/4515
  //
  // The flutter_test view has a ratio of 3. `tester.view.reset()` in a test
  // puts back 3, not 1. Thus a `setUp` sets the ratio before each test, as
  // the host set-up does.
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

  // index.js:14-15 put `acquireChart` and `releaseChart` on `window`. Dart
  // has no globals: the specs import them from
  // package:chartjs_test_utils/flutter.dart.

  // Set a fixed time zone (and, in particular, disable Daylight Saving
  // Time) for more stable test results. Upstream runs in the zone of the
  // browser.
  // DIVERGES(zoom): harness-date-zone, the default date zone UTC.
  setDefaultDateZone('Etc/UTC');

  // karma.conf.cjs loads the UMD bundle of Chart.js, which registers the
  // built-in components (`src/index.umd.ts:28` of Chart.js), before the
  // specs. Dart has no import side effect: the registration runs before
  // `main()` of the test file and before the snapshot of the restore below.
  // Thus the restore keeps the defaults of the components.
  // DIVERGES(zoom): harness-register-builtins, the UMD entries of karma.
  setUpBuiltins(
    () => Chart.register([controllers, scales, elements, plugins]),
    () => Chart.unregister([controllers, scales, elements, plugins]),
  );

  // index.js:140-143
  // Disable colors plugin for tests.
  //
  // Upstream runs the line in a top-level `beforeAll`, once, before the
  // first spec. Here it runs before `main()` of each test file and before
  // the snapshot of the restore, so the restore keeps it.
  ((defaults['plugins']! as JsObjectFace)['colors']!
          as JsObjectFace)['enabled'] =
      false;

  // Upstream restores nothing. The restore keeps the order of the test
  // files from changing their results.
  // DIVERGES(zoom): harness-defaults-restore, restore defaults after tests.
  setUpDefaultsRestore();

  // index.js:132-134 `addMatchers()`: n/a. The matchers are functions of
  // test/support/jasmine.dart and of package:chartjs_test_utils/pure.dart
  // that a spec imports.

  // index.js:136-138 afterEach(function () { releaseCharts() })
  //
  // The unmount of the harness body calls `releaseCharts`, and the
  // `tearDown` is the fallback after a failed test (Chart.js ADR 0022,
  // section 8). The upstream specs have no `afterEach` of their own, so the
  // order of the two is the order of upstream.
  afterEachChart(releaseCharts);
  tearDown(releaseCharts);

  // The text of the scales measures with Liberation Sans under the family
  // names of the Chart.js default font, as in the host specs. Upstream
  // measures with the fonts of the browser.
  // DIVERGES(zoom): harness-test-font, Liberation Sans for Arial/Helvetica.
  await installTestFont();

  await testMain();
}
