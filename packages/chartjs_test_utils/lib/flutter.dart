// Original code, not ported from Chart.js: the flutter test harness.

/// The part of the harness that needs the Flutter engine: it runs in
/// `flutter test` only (porting-flow.md section 3).
///
/// - The test font: `packages/flutter_chartjs/test/flutter_test_config.dart`
///   calls `installTestFont` before each test file.
/// - The DOM stand-in of `src/dom.dart` (Chart.js ADR 0022): `document`,
///   `window`, `setTimeout`, `afterEachChart`, `pumpFrames`, `pumpFrame`,
///   `waitForDone`, `frameInterval`, `specTimeout`, the element classes and
///   the extensions `CanvasParentElement` and `CssProperties`.
/// - The chart helpers of chartjs-test-utils `src/index.js` and
///   `src/utils.js` (Chart.js ADR 0022, sections 4 to 6): `acquireChart`,
///   `releaseChart` and `releaseCharts`, which need the chart host;
///   `afterEvent` and `waitForResize`, which replace a function field of a
///   chart; and `triggerMouseEvent`, which pumps frames. `acquireChart`
///   works only in the body of a `testWidgets` test.
/// - The fixture smoke runner of chartjs-test-utils `src/fixture.js`
///   (Chart.js ADR 0029): `specsFromFixtures`, `specFromFixture`,
///   `FixtureSource`, `FixtureItem`, `FixtureInputs`, `FixtureLoad`,
///   `HandFixture`, `fixturesTag`, `fixturesRequiredVariable` and
///   `noSubmoduleReason`.
///
/// The pure part of the harness is `package:chartjs_test_utils/pure.dart`.
/// This library is not a pure layer: a test that imports it needs
/// `@TestOn('vm')`.
library;

export 'src/dom.dart'
    show
        CanvasParentElement,
        CssProperties,
        HarnessDocument,
        HarnessElement,
        HarnessWindow,
        afterEachChart,
        document,
        frameInterval,
        pumpFrame,
        pumpFrames,
        setTimeout,
        specTimeout,
        waitForDone,
        window;
export 'src/fonts.dart' show installTestFont, testFontFamilies, testFontFiles;
export 'src/index.dart'
    show
        FixtureInputs,
        FixtureItem,
        FixtureLoad,
        FixtureSource,
        HandFixture,
        acquireChart,
        afterEvent,
        fixturesRequiredVariable,
        fixturesTag,
        noSubmoduleReason,
        releaseChart,
        releaseCharts,
        specFromFixture,
        specsFromFixtures,
        triggerMouseEvent,
        waitForResize;
