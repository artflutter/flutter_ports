// Ported from chartjs-chart-sankey v0.19.1 test/setup.js (MIT, Jukka Kurkela).

/// Port of `test/setup.js`, the set-up of the sankey specs (Sankey ADR
/// 0002).
///
/// Flutter runs [testExecutable] around each test file of the package. The
/// file has the set-up of upstream in the form of the host set-up
/// (`packages/flutter_chartjs_port/test/flutter_test_config.dart`), with the
/// public libraries of the host and the harness only (ADR 0009):
///
/// - the device pixel ratio 1 and the view of 800 x 600 before each test;
/// - the built-in components of Chart.js and the two components of the
///   sankey chart, registered before `main()` of the test file
///   (`harness-register-builtins`);
/// - the colors plugin off, and the restore of the global scopes after each
///   test (`harness-defaults-restore`);
/// - the release of the charts after each test;
/// - the test font of the host harness (`harness-test-font`).
///
/// setup.js:10-14 puts `Chart`, `acquireChart`, `afterEvent` and
/// `triggerMouseEvent` on `globalThis`. Dart has no globals: a spec imports
/// them from `package:flutter_chartjs_port/chartjs.dart` and
/// `package:chartjs_test_utils/flutter.dart`.
library;

import 'dart:async';
import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart'
    show afterEachChart, installTestFont, releaseCharts;
import 'package:chartjs_test_utils/pure.dart'
    show setUpBuiltins, setUpDefaultsRestore;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show sankeyRegisterables;
import 'package:flutter_chartjs_port/chartjs.dart'
    show Chart, JsObjectFace, controllers, defaults, elements, plugins, scales;
import 'package:flutter_test/flutter_test.dart';

/// setup.js:18 `Chart.defaults.devicePixelRatio = 1`.
const double _devicePixelRatio = 1;

/// The logical size of the test view: the flutter_test default (2400 x 1800
/// physical pixels at a ratio of 3).
const Size _logicalSize = Size(800, 600);

/// The set-up of each test file in this package.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Pin the backing store to CSS pixels so the reference PNGs stay
  // comparable whatever the host display reports.
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

  // setup.js:3 `import '../src/index'` registers the controller and the
  // element, and :7 registers every Chart.js component. Dart has no import
  // side effect: the registration runs before `main()` of the test file and
  // before the snapshot of the restore below.
  // DIVERGES(sankey): harness-register-builtins, the imports of setup.js.
  setUpBuiltins(
    () {
      Chart.register([controllers, scales, elements, plugins]);
      Chart.register(sankeyRegisterables);
    },
    () => Chart.unregister([
      ...sankeyRegisterables,
      controllers,
      scales,
      elements,
      plugins,
    ]),
  );

  // Disable colors plugin for tests.
  ((defaults['plugins']! as JsObjectFace)['colors']!
          as JsObjectFace)['enabled'] =
      false;

  // Upstream restores nothing. The restore keeps the order of the test
  // files from changing their results.
  // DIVERGES(sankey): harness-defaults-restore, restore defaults after tests.
  setUpDefaultsRestore();

  // setup.js:22 `expect.extend(imageMatchers)`: n/a. The fixtures compare
  // observations, not images (row `harness-fixture-observations`).

  // setup.js:24-26 afterEach(() => { releaseCharts() })
  //
  // The unmount of the harness body calls `releaseCharts`, and the
  // `tearDown` is the fallback after a failed test (Chart.js ADR 0022,
  // section 8).
  afterEachChart(releaseCharts);
  tearDown(releaseCharts);

  // The labels measure with Liberation Sans under the family names of the
  // Chart.js default font, as in the host specs. Upstream measures with the
  // fonts of the browser.
  // DIVERGES(sankey): harness-test-font, Liberation Sans for Arial/Helvetica.
  await installTestFont();

  await testMain();
}
