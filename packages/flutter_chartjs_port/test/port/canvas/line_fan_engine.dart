// Original code, not ported from Chart.js: the engine of the line fan twins.

/// The engine rule of the twins of Chart.js ADR 0103.
///
/// An app takes the fan only on Impeller. On Skia on the CPU, a test opens the
/// fan with the switch [UiCanvasContext.debugLineFanWithoutImpeller]. On
/// Impeller, a test runs with the gate of an app, with no switch.
///
/// The web legs cannot compile this file. Only `@TestOn('vm')` tests import
/// it.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether this run has to be on Impeller: `CHART_IMPELLER=1`, which the CI job
/// `test-impeller` sets.
final bool _impellerRequired = Platform.environment['CHART_IMPELLER'] == '1';

/// Sets the switch for each test of the file, and fails a run that has to be on
/// Impeller and is not. With no such failure, a job that lost its
/// `--enable-impeller` would pass on Skia on the CPU, where an app declines the
/// fan.
void setUpLineFanEngine() {
  setUp(() {
    UiCanvasContext.debugLineFanWithoutImpeller =
        !ui.ImageFilter.isShaderFilterSupported;
    addTearDown(() => UiCanvasContext.debugLineFanWithoutImpeller = false);
  });

  test(
    'a run with CHART_IMPELLER=1 is on Impeller',
    () => expect(ui.ImageFilter.isShaderFilterSupported, isTrue),
    skip: _impellerRequired ? false : 'n/a: CHART_IMPELLER is not set',
  );
}
