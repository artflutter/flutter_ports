// Ported from Chart.js v4.5.1+7169e651 test/specs/plugin.subtitle.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

// The spec builds charts of flutter_chartjs_port, which does not export lib/src
// yet.
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.subtitle.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.title.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/index.dart' as fixture;

// The upstream spec has only the fixture group `auto` (Chart.js ADR 0029).
// The fixture runner builds charts, so the file runs on the VM. The one
// fixture `plugin.subtitle/basic.js` is pure data and needs no hand port.

void main() {
  // Chart.js ADR 0041 section 7: until wave 4 adds the plugins to
  // registerables, this file registers the plugins that its cases need.
  Chart.register([subTitle, title]);

  group('plugin.subtitle', () {
    group('auto', fixture.specs('plugin.subtitle'));
  });
}
